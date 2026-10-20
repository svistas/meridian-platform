#!/usr/bin/env python3
"""Check that every datastore really has the properties the path promises.

The build brief's guarantee table is the contract between the path and its
users. This script reads it back from the AWS API after an apply, one row at a
time, for every request. It never trusts Terraform state: the point is to
confirm what AWS actually did.

Exits non-zero if any row fails for any datastore.

Usage:
    verify_guarantee.py --kms-key-arn arn:aws:kms:... [--region eu-west-1]
                        [--requests DIR] [--markdown FILE]
"""

from __future__ import annotations

import argparse
import pathlib
import sys
from dataclasses import dataclass

import yaml

# boto3 is imported inside verify(), so the pure checks below can be unit
# tested on a machine that has no AWS SDK installed.

HERE = pathlib.Path(__file__).resolve().parent
DEFAULT_REQUESTS = HERE.parent / "requests"

BACKUP_RETENTION_DAYS = 35
LOG_RETENTION_DAYS = 90
REQUIRED_LOG_EXPORTS = {"postgresql", "upgrade"}
REQUIRED_TAG_KEYS = {
    "service",
    "team",
    "cost-center",
    "classification",
    "managed-by",
    "path",
    "data-leaves-meridian",
}


@dataclass
class Check:
    """One row of the guarantee table, for one datastore."""

    service: str
    row: str
    passed: bool
    detail: str

    @property
    def mark(self) -> str:
        return "PASS" if self.passed else "FAIL"


def normalise_leaves(value) -> str:
    """Same normalisation as validate_requests.py, for comparing the tag."""
    if isinstance(value, bool):
        return "no" if value is False else str(value).lower()
    text = str(value).strip()
    return "no" if text.lower() in {"no", "false"} else text


def check_instance(service: str, instance: dict, expected_kms: str, request: dict) -> list[Check]:
    checks: list[Check] = []

    def add(row: str, passed: bool, detail: str):
        checks.append(Check(service, row, passed, detail))

    # Storage encrypted with the platform's key.
    encrypted = instance.get("StorageEncrypted", False)
    kms = instance.get("KmsKeyId", "")
    add(
        "Storage encrypted",
        bool(encrypted) and kms == expected_kms,
        f"encrypted={encrypted}, key={kms or 'none'}",
    )

    # Not reachable from the internet.
    public = instance.get("PubliclyAccessible", True)
    add("Publicly accessible", public is False, f"publicly_accessible={public}")

    # Backups.
    retention = instance.get("BackupRetentionPeriod")
    add(
        "Backup retention",
        retention == BACKUP_RETENTION_DAYS,
        f"{retention} days (want {BACKUP_RETENTION_DAYS})",
    )

    # Logs exported.
    exports = set(instance.get("EnabledCloudwatchLogsExports") or [])
    add(
        "Logs exported",
        REQUIRED_LOG_EXPORTS.issubset(exports),
        f"exports={sorted(exports) or 'none'}",
    )

    # Master password managed by RDS, and the secret encrypted with our key.
    secret = instance.get("MasterUserSecret") or {}
    has_secret = bool(secret.get("SecretArn"))
    secret_key_ok = secret.get("KmsKeyId") == expected_kms
    add(
        "Master password managed",
        has_secret,
        f"secret={'present' if has_secret else 'absent'}",
    )
    add(
        "Secret encrypted with platform key",
        secret_key_ok,
        f"secret key={secret.get('KmsKeyId') or 'none'}",
    )

    # Tags.
    tags = {t["Key"]: t["Value"] for t in instance.get("TagList") or []}
    missing = REQUIRED_TAG_KEYS - set(tags)
    wrong = []
    if tags.get("managed-by") != "meridian-platform":
        wrong.append(f"managed-by={tags.get('managed-by')!r}")
    if tags.get("path") != "compliant-datastore":
        wrong.append(f"path={tags.get('path')!r}")
    if tags.get("service") != service:
        wrong.append(f"service={tags.get('service')!r}")
    if tags.get("classification") != request.get("classification"):
        wrong.append(f"classification={tags.get('classification')!r}")
    expected_leaves = normalise_leaves(request.get("data_leaves_meridian"))
    if tags.get("data-leaves-meridian") != expected_leaves:
        wrong.append(f"data-leaves-meridian={tags.get('data-leaves-meridian')!r}")
    add(
        "Tags",
        not missing and not wrong,
        "ok" if not missing and not wrong
        else f"missing={sorted(missing)} wrong={wrong}",
    )

    return checks


def check_parameters(service: str, rds, parameter_group: str) -> list[Check]:
    wanted = {"rds.force_ssl": "1", "log_connections": "1", "log_disconnections": "1"}
    found: dict[str, str] = {}

    paginator = rds.get_paginator("describe_db_parameters")
    for page in paginator.paginate(DBParameterGroupName=parameter_group):
        for parameter in page["Parameters"]:
            name = parameter.get("ParameterName")
            if name in wanted:
                found[name] = parameter.get("ParameterValue")

    tls_ok = found.get("rds.force_ssl") == "1"
    logging_ok = (
        found.get("log_connections") == "1" and found.get("log_disconnections") == "1"
    )
    return [
        Check(service, "TLS enforced", tls_ok, f"rds.force_ssl={found.get('rds.force_ssl')}"),
        Check(
            service,
            "Connection logging",
            logging_ok,
            f"log_connections={found.get('log_connections')}, "
            f"log_disconnections={found.get('log_disconnections')}",
        ),
    ]


def check_log_groups(service: str, logs) -> list[Check]:
    checks = []
    for stream in sorted(REQUIRED_LOG_EXPORTS):
        name = f"/aws/rds/instance/{service}/{stream}"
        response = logs.describe_log_groups(logGroupNamePrefix=name)
        group = next(
            (g for g in response.get("logGroups", []) if g["logGroupName"] == name), None
        )
        if group is None:
            checks.append(Check(service, f"Log retention ({stream})", False, "log group missing"))
            continue
        retention = group.get("retentionInDays")
        checks.append(
            Check(
                service,
                f"Log retention ({stream})",
                retention == LOG_RETENTION_DAYS,
                f"{retention or 'never expires'} (want {LOG_RETENTION_DAYS})",
            )
        )
    return checks


def verify(requests_dir: pathlib.Path, region: str, expected_kms: str) -> list[Check]:
    import boto3

    rds = boto3.client("rds", region_name=region)
    logs = boto3.client("logs", region_name=region)

    checks: list[Check] = []
    for path in sorted(requests_dir.glob("*.yaml")):
        request = yaml.safe_load(path.read_text())
        service = request["service"]

        try:
            response = rds.describe_db_instances(DBInstanceIdentifier=service)
        except rds.exceptions.DBInstanceNotFoundFault:
            checks.append(Check(service, "Database exists", False, "no such DB instance"))
            continue

        instance = response["DBInstances"][0]
        checks.append(Check(service, "Database exists", True, instance["DBInstanceStatus"]))
        checks.extend(check_instance(service, instance, expected_kms, request))

        groups = instance.get("DBParameterGroups") or []
        if groups:
            checks.extend(check_parameters(service, rds, groups[0]["DBParameterGroupName"]))
        else:
            checks.append(Check(service, "TLS enforced", False, "no parameter group"))

        checks.extend(check_log_groups(service, logs))

    return checks


def render_markdown(checks: list[Check]) -> str:
    lines = ["# Guarantee verification", ""]
    if not checks:
        lines.append("No requests to verify.")
        return "\n".join(lines) + "\n"

    failed = [c for c in checks if not c.passed]
    lines.append(
        f"**{len(checks) - len(failed)} of {len(checks)} checks passed.**"
        if failed
        else f"**All {len(checks)} checks passed.**"
    )
    lines.append("")

    for service in sorted({c.service for c in checks}):
        lines += [f"## `{service}`", "", "| Guarantee | Result | Detail |", "|---|---|---|"]
        for check in [c for c in checks if c.service == service]:
            mark = "PASS" if check.passed else "**FAIL**"
            lines.append(f"| {check.row} | {mark} | `{check.detail}` |")
        lines.append("")
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--requests", type=pathlib.Path, default=DEFAULT_REQUESTS)
    parser.add_argument("--region", default="eu-west-1")
    parser.add_argument("--kms-key-arn", required=True, help="the platform key every datastore must use")
    parser.add_argument("--markdown", type=pathlib.Path, help="also write a markdown report here")
    args = parser.parse_args(argv)

    checks = verify(args.requests, args.region, args.kms_key_arn)

    for check in checks:
        print(f"{check.mark:4}  {check.service:28}  {check.row:36}  {check.detail}")

    if args.markdown:
        args.markdown.parent.mkdir(parents=True, exist_ok=True)
        args.markdown.write_text(render_markdown(checks))

    failed = [c for c in checks if not c.passed]
    print()
    if failed:
        print(f"{len(failed)} of {len(checks)} guarantee checks FAILED.")
        return 1
    if not checks:
        print("No requests to verify.")
        return 0
    print(f"All {len(checks)} guarantee checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

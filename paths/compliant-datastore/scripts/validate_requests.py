#!/usr/bin/env python3
"""Validate every datastore request, and flag the ones a human must look at.

Two jobs, deliberately separate:

  Errors      stop the pull request. The request is malformed, contradicts
              another request, or asks for something the MVP does not build.
  Judgment    do not stop anything. A human from Security reads these.
  cases       In the MVP the merge is still allowed; the flag is the thing
              being tested (build brief, "Judgment cases").

Exit status is 0 when there are no errors, 1 when there are. Judgment cases
alone never change the exit status.

Usage:
    validate_requests.py [--requests DIR] [--schema FILE] [--json]
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from dataclasses import dataclass, field

import yaml
from jsonschema import Draft202012Validator

HERE = pathlib.Path(__file__).resolve().parent
DEFAULT_REQUESTS = HERE.parent / "requests"
DEFAULT_SCHEMA = HERE.parent / "schema" / "request.schema.json"

# An RDS DB instance identifier: 1-63 characters, starts with a letter, letters
# digits and hyphens only, no two hyphens in a row, does not end with a hyphen.
# The service name becomes the identifier, so it has to satisfy this.
RDS_IDENTIFIER = re.compile(r"^[a-z][a-z0-9]*(-[a-z0-9]+)*$")
RDS_IDENTIFIER_MAX = 63


@dataclass
class Result:
    errors: list[str] = field(default_factory=list)
    flags: list[str] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not self.errors


def rds_identifier_problem(service: str) -> str | None:
    """Why this service name cannot be an RDS identifier, or None."""
    if not service:
        return "is empty"
    if len(service) > RDS_IDENTIFIER_MAX:
        return f"is {len(service)} characters; the maximum is {RDS_IDENTIFIER_MAX}"
    if not service[0].isalpha():
        return "must start with a letter"
    if service.endswith("-"):
        return "must not end with a hyphen"
    if "--" in service:
        return "must not contain two consecutive hyphens"
    if not RDS_IDENTIFIER.match(service):
        return "must be lowercase letters, digits and single hyphens only"
    return None


def judgment_cases(request: dict) -> list[str]:
    """Reasons this request needs a human from Security, in plain language."""
    reasons = []
    if request.get("classification") == "unsure":
        reasons.append(
            "classification is 'unsure': someone has to decide whether this "
            "holds patient data before it is used"
        )
    leaves = request.get("data_leaves_meridian")
    if leaves is not None and leaves != "no":
        reasons.append(
            f"data leaves Meridian to '{leaves}': the destination needs a "
            f"review of what is sent and under which agreement"
        )
    return reasons


def validate_file(path: pathlib.Path, validator: Draft202012Validator) -> Result:
    result = Result()

    try:
        raw = yaml.safe_load(path.read_text())
    except yaml.YAMLError as exc:
        result.errors.append(f"{path.name}: is not valid YAML: {exc}")
        return result

    if not isinstance(raw, dict):
        result.errors.append(
            f"{path.name}: should be a mapping of fields, got {type(raw).__name__}"
        )
        return result

    for error in sorted(validator.iter_errors(raw), key=lambda e: list(e.path)):
        where = ".".join(str(p) for p in error.path) or "(top level)"
        result.errors.append(f"{path.name}: {where}: {error.message}")

    service = raw.get("service")
    if isinstance(service, str):
        # The file name is the index a human reads. Keep it honest.
        expected = f"{service}.yaml"
        if path.name != expected:
            result.errors.append(
                f"{path.name}: service is '{service}', so the file should be "
                f"named '{expected}'"
            )

        problem = rds_identifier_problem(service)
        if problem:
            result.errors.append(
                f"{path.name}: service '{service}' cannot be a database "
                f"identifier: it {problem}"
            )

    for reason in judgment_cases(raw):
        result.flags.append(f"{path.name}: {reason}")

    return result


def validate_all(requests_dir: pathlib.Path, schema_path: pathlib.Path) -> Result:
    schema = json.loads(schema_path.read_text())
    validator = Draft202012Validator(schema)

    combined = Result()
    seen: dict[str, str] = {}

    files = sorted(requests_dir.glob("*.yaml"))
    for path in files:
        result = validate_file(path, validator)
        combined.errors.extend(result.errors)
        combined.flags.extend(result.flags)

        try:
            raw = yaml.safe_load(path.read_text())
        except yaml.YAMLError:
            continue
        if isinstance(raw, dict) and isinstance(raw.get("service"), str):
            service = raw["service"]
            if service in seen:
                combined.errors.append(
                    f"{path.name}: service '{service}' is already requested in "
                    f"{seen[service]}; service names must be unique"
                )
            else:
                seen[service] = path.name

    # A stray .yml would be silently ignored by the Terraform fileset too.
    for stray in sorted(requests_dir.glob("*.yml")):
        combined.errors.append(
            f"{stray.name}: requests must use the .yaml extension, or Terraform "
            f"will not see this file"
        )

    return combined


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--requests", type=pathlib.Path, default=DEFAULT_REQUESTS)
    parser.add_argument("--schema", type=pathlib.Path, default=DEFAULT_SCHEMA)
    parser.add_argument(
        "--json",
        action="store_true",
        help="machine-readable output, for the pull-request comment in phase 4",
    )
    args = parser.parse_args(argv)

    if not args.requests.is_dir():
        print(f"no requests directory at {args.requests}", file=sys.stderr)
        return 1

    result = validate_all(args.requests, args.schema)

    if args.json:
        print(json.dumps({"errors": result.errors, "flags": result.flags}, indent=2))
        return 0 if result.ok else 1

    count = len(sorted(args.requests.glob("*.yaml")))
    print(f"Checked {count} request file{'' if count == 1 else 's'}.")

    if result.errors:
        print(f"\n{len(result.errors)} error{'' if len(result.errors) == 1 else 's'}:")
        for error in result.errors:
            print(f"  - {error}")

    if result.flags:
        print(
            f"\n{len(result.flags)} judgment "
            f"case{'' if len(result.flags) == 1 else 's'} "
            f"(label: needs-security-review):"
        )
        for flag in result.flags:
            print(f"  - {flag}")
        print(
            "\nThese do not block the merge in the sandbox. A human from "
            "Security & Compliance decides."
        )

    if result.ok and not result.flags:
        print("\nAll requests valid, no judgment cases.")
    elif result.ok:
        print("\nAll requests valid.")

    return 0 if result.ok else 1


if __name__ == "__main__":
    raise SystemExit(main())

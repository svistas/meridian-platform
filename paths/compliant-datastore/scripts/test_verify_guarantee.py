#!/usr/bin/env python3
"""Unit tests for the guarantee checks.

These exercise the checking logic against recorded AWS API shapes, so they run
without AWS and without boto3 installed.
"""

from __future__ import annotations

import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import verify_guarantee as g  # noqa: E402

KEY = "arn:aws:kms:eu-west-1:111122223333:key/abcd-1234"
OTHER_KEY = "arn:aws:kms:eu-west-1:111122223333:key/9999-9999"

REQUEST = {
    "service": "appointment-reminders",
    "team": "appointments",
    "cost_center": "patient-app",
    "classification": "phi",
    "data_leaves_meridian": "no",
}

TAGS = [
    {"Key": "service", "Value": "appointment-reminders"},
    {"Key": "team", "Value": "appointments"},
    {"Key": "cost-center", "Value": "patient-app"},
    {"Key": "classification", "Value": "phi"},
    {"Key": "managed-by", "Value": "meridian-platform"},
    {"Key": "path", "Value": "compliant-datastore"},
    {"Key": "data-leaves-meridian", "Value": "no"},
]


def compliant_instance(**overrides) -> dict:
    instance = {
        "StorageEncrypted": True,
        "KmsKeyId": KEY,
        "PubliclyAccessible": False,
        "BackupRetentionPeriod": 35,
        "EnabledCloudwatchLogsExports": ["postgresql", "upgrade"],
        "MasterUserSecret": {"SecretArn": "arn:aws:secretsmanager:...", "KmsKeyId": KEY},
        "TagList": list(TAGS),
    }
    instance.update(overrides)
    return instance


def results(instance: dict, request: dict | None = None) -> dict[str, g.Check]:
    checks = g.check_instance("appointment-reminders", instance, KEY, request or REQUEST)
    return {c.row: c for c in checks}


class TestCompliantInstance(unittest.TestCase):
    def test_everything_passes(self):
        for row, check in results(compliant_instance()).items():
            with self.subTest(row=row):
                self.assertTrue(check.passed, f"{row}: {check.detail}")


class TestEachGuaranteeCanFail(unittest.TestCase):
    """Every row must actually be able to fail, or it is not a check."""

    def test_unencrypted_storage_fails(self):
        r = results(compliant_instance(StorageEncrypted=False, KmsKeyId=""))
        self.assertFalse(r["Storage encrypted"].passed)

    def test_wrong_kms_key_fails(self):
        r = results(compliant_instance(KmsKeyId=OTHER_KEY))
        self.assertFalse(r["Storage encrypted"].passed)

    def test_public_instance_fails(self):
        r = results(compliant_instance(PubliclyAccessible=True))
        self.assertFalse(r["Publicly accessible"].passed)

    def test_short_backup_retention_fails(self):
        r = results(compliant_instance(BackupRetentionPeriod=7))
        self.assertFalse(r["Backup retention"].passed)

    def test_missing_log_export_fails(self):
        r = results(compliant_instance(EnabledCloudwatchLogsExports=["postgresql"]))
        self.assertFalse(r["Logs exported"].passed)

    def test_no_managed_secret_fails(self):
        r = results(compliant_instance(MasterUserSecret={}))
        self.assertFalse(r["Master password managed"].passed)

    def test_secret_on_the_wrong_key_fails(self):
        r = results(
            compliant_instance(
                MasterUserSecret={"SecretArn": "arn:...", "KmsKeyId": OTHER_KEY}
            )
        )
        self.assertFalse(r["Secret encrypted with platform key"].passed)
        self.assertTrue(r["Master password managed"].passed)

    def test_missing_tag_fails(self):
        tags = [t for t in TAGS if t["Key"] != "cost-center"]
        r = results(compliant_instance(TagList=tags))
        self.assertFalse(r["Tags"].passed)
        self.assertIn("cost-center", r["Tags"].detail)

    def test_wrong_managed_by_tag_fails(self):
        tags = [dict(t) for t in TAGS]
        next(t for t in tags if t["Key"] == "managed-by")["Value"] = "someone-else"
        r = results(compliant_instance(TagList=tags))
        self.assertFalse(r["Tags"].passed)

    def test_classification_tag_must_match_the_request(self):
        tags = [dict(t) for t in TAGS]
        next(t for t in tags if t["Key"] == "classification")["Value"] = "non-phi"
        r = results(compliant_instance(TagList=tags))
        self.assertFalse(r["Tags"].passed)


class TestDataLeavesTagNormalisation(unittest.TestCase):
    """An unquoted `no` is YAML False; the tag should still read "no"."""

    def test_boolean_false_request_matches_no_tag(self):
        request = dict(REQUEST, data_leaves_meridian=False)
        self.assertTrue(results(compliant_instance(), request)["Tags"].passed)

    def test_capitalised_no_matches(self):
        request = dict(REQUEST, data_leaves_meridian="NO")
        self.assertTrue(results(compliant_instance(), request)["Tags"].passed)

    def test_destination_must_match_the_tag(self):
        request = dict(REQUEST, data_leaves_meridian="sms-vendor")
        self.assertFalse(results(compliant_instance(), request)["Tags"].passed)

        tags = [dict(t) for t in TAGS]
        next(t for t in tags if t["Key"] == "data-leaves-meridian")["Value"] = "sms-vendor"
        self.assertTrue(results(compliant_instance(TagList=tags), request)["Tags"].passed)

    def test_normalise_leaves(self):
        self.assertEqual(g.normalise_leaves(False), "no")
        self.assertEqual(g.normalise_leaves("No"), "no")
        self.assertEqual(g.normalise_leaves("false"), "no")
        self.assertEqual(g.normalise_leaves("sms-vendor"), "sms-vendor")


class TestMarkdownReport(unittest.TestCase):
    def test_passing_report_says_so(self):
        checks = g.check_instance("appointment-reminders", compliant_instance(), KEY, REQUEST)
        report = g.render_markdown(checks)
        self.assertIn("All", report)
        self.assertIn("`appointment-reminders`", report)
        self.assertNotIn("**FAIL**", report)

    def test_failing_report_marks_the_row(self):
        checks = g.check_instance(
            "appointment-reminders", compliant_instance(PubliclyAccessible=True), KEY, REQUEST
        )
        report = g.render_markdown(checks)
        self.assertIn("**FAIL**", report)
        self.assertIn("Publicly accessible", report)

    def test_empty_report(self):
        self.assertIn("No requests", g.render_markdown([]))


if __name__ == "__main__":
    unittest.main()

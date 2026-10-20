#!/usr/bin/env python3
"""Unit tests for inventory.py."""

from __future__ import annotations

import pathlib
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import inventory as inv  # noqa: E402

REQUEST = """\
service: {service}
team: {team}
cost_center: patient-app
environment: sandbox
engine: postgres
size: small
classification: {classification}
data_leaves_meridian: {leaves}
"""


class TestJudgmentFlag(unittest.TestCase):
    def test_clean_request_has_no_flag(self):
        self.assertEqual(inv.judgment_flag({"classification": "phi", "data_leaves_meridian": "no"}), "-")

    def test_unquoted_no_has_no_flag(self):
        self.assertEqual(inv.judgment_flag({"classification": "phi", "data_leaves_meridian": False}), "-")

    def test_unsure_is_flagged(self):
        flag = inv.judgment_flag({"classification": "unsure", "data_leaves_meridian": "no"})
        self.assertIn("unsure", flag)

    def test_destination_is_flagged(self):
        flag = inv.judgment_flag({"classification": "phi", "data_leaves_meridian": "sms-vendor"})
        self.assertIn("sms-vendor", flag)

    def test_both_reasons_appear(self):
        flag = inv.judgment_flag({"classification": "unsure", "data_leaves_meridian": "sms-vendor"})
        self.assertIn("unsure", flag)
        self.assertIn("sms-vendor", flag)


class TestRender(unittest.TestCase):
    def test_empty_inventory(self):
        self.assertIn("No datastores", inv.render([]))

    def test_counts_and_rows(self):
        rows = [
            {"service": "a", "team": "t", "classification": "phi", "flag": "-",
             "requested_by": "Someone", "requested_on": "2026-01-01"},
            {"service": "b", "team": "t", "classification": "unsure", "flag": "classification unsure",
             "requested_by": "Someone", "requested_on": "2026-01-02"},
        ]
        out = inv.render(rows)
        self.assertIn("2 datastores", out)
        self.assertIn("1 classified `phi`", out)
        self.assertIn("1 `unsure`", out)
        self.assertIn("1 awaiting a judgment call", out)
        self.assertIn("`a`", out)
        self.assertIn("`b`", out)


class TestGitAttribution(unittest.TestCase):
    """Requested-by comes from the commit that added the file."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)
        self.requests = self.root / "requests"
        self.requests.mkdir()
        for args in (
            ["init", "-q"],
            ["config", "user.email", "asker@example.com"],
            ["config", "user.name", "The Asker"],
        ):
            subprocess.run(["git", *args], cwd=self.root, check=True, capture_output=True)

    def commit(self, message: str):
        subprocess.run(["git", "add", "-A"], cwd=self.root, check=True, capture_output=True)
        subprocess.run(["git", "commit", "-q", "-m", message], cwd=self.root, check=True, capture_output=True)

    def test_author_of_the_adding_commit_is_used(self):
        path = self.requests / "care-notes.yaml"
        path.write_text(REQUEST.format(service="care-notes", team="carenotes",
                                       classification="phi", leaves='"no"'))
        self.commit("add care-notes")

        # A later edit by someone else must not change who asked for it.
        subprocess.run(["git", "config", "user.name", "Someone Else"], cwd=self.root, check=True, capture_output=True)
        path.write_text(REQUEST.format(service="care-notes", team="carenotes",
                                       classification="non-phi", leaves='"no"'))
        self.commit("reclassify")

        rows = inv.collect(self.requests, self.root)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["requested_by"], "The Asker")
        self.assertEqual(rows[0]["classification"], "non-phi")

    def test_uncommitted_request_is_unknown_not_a_crash(self):
        (self.requests / "new.yaml").write_text(
            REQUEST.format(service="new", team="t", classification="phi", leaves='"no"')
        )
        rows = inv.collect(self.requests, self.root)
        self.assertEqual(rows[0]["requested_by"], "unknown")


if __name__ == "__main__":
    unittest.main()

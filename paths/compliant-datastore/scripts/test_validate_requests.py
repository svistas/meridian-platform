#!/usr/bin/env python3
"""Unit tests for validate_requests.py.

Run with:  python3 -m unittest discover -s scripts -v
"""

from __future__ import annotations

import json
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import validate_requests as v  # noqa: E402

SCHEMA = pathlib.Path(__file__).resolve().parent.parent / "schema" / "request.schema.json"

VALID = """\
service: appointment-reminders
team: appointments
cost_center: patient-app
environment: sandbox
engine: postgres
size: small
classification: phi
data_leaves_meridian: "no"
"""


def request_text(**overrides) -> str:
    """The valid request with fields replaced, removed (None) or added."""
    fields = {}
    for line in VALID.splitlines():
        key, _, value = line.partition(": ")
        fields[key] = value
    fields.update(overrides)
    return "".join(
        f"{k}: {val}\n" for k, val in fields.items() if val is not None
    )


class ValidatorCase(unittest.TestCase):
    """Writes request files into a temporary directory and validates them."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.dir = pathlib.Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)

    def write(self, name: str, text: str) -> pathlib.Path:
        path = self.dir / name
        path.write_text(text)
        return path

    def run_validation(self) -> v.Result:
        return v.validate_all(self.dir, SCHEMA)


class TestValidRequests(ValidatorCase):
    def test_the_example_request_passes_with_no_errors_or_flags(self):
        self.write("appointment-reminders.yaml", VALID)
        result = self.run_validation()
        self.assertEqual(result.errors, [])
        self.assertEqual(result.flags, [])
        self.assertTrue(result.ok)

    def test_medium_and_non_phi_are_valid(self):
        self.write(
            "care-notes.yaml",
            request_text(service="care-notes", size="medium", classification="non-phi"),
        )
        result = self.run_validation()
        self.assertEqual(result.errors, [])

    def test_several_distinct_requests_are_valid(self):
        self.write("appointment-reminders.yaml", VALID)
        self.write("care-notes.yaml", request_text(service="care-notes"))
        self.write("lab-results.yaml", request_text(service="lab-results"))
        result = self.run_validation()
        self.assertEqual(result.errors, [])

    def test_the_real_requests_directory_is_valid(self):
        """The requests actually in the repository must pass."""
        real = pathlib.Path(__file__).resolve().parent.parent / "requests"
        result = v.validate_all(real, SCHEMA)
        self.assertEqual(result.errors, [], f"real requests have errors: {result.errors}")


class TestJudgmentCases(ValidatorCase):
    def test_unsure_classification_is_flagged_but_not_an_error(self):
        self.write("care-notes.yaml", request_text(service="care-notes", classification="unsure"))
        result = self.run_validation()
        self.assertEqual(result.errors, [])
        self.assertTrue(result.ok, "a judgment case must not block the merge")
        self.assertEqual(len(result.flags), 1)
        self.assertIn("unsure", result.flags[0])

    def test_data_leaving_meridian_is_flagged(self):
        self.write(
            "care-notes.yaml",
            request_text(service="care-notes", data_leaves_meridian='"sms-vendor"'),
        )
        result = self.run_validation()
        self.assertEqual(result.errors, [])
        self.assertEqual(len(result.flags), 1)
        self.assertIn("sms-vendor", result.flags[0])

    def test_both_judgment_cases_raise_two_flags(self):
        self.write(
            "care-notes.yaml",
            request_text(
                service="care-notes",
                classification="unsure",
                data_leaves_meridian='"sms-vendor"',
            ),
        )
        result = self.run_validation()
        self.assertEqual(len(result.flags), 2)
        self.assertTrue(result.ok)

    def test_no_is_not_a_judgment_case(self):
        self.write("appointment-reminders.yaml", VALID)
        self.assertEqual(self.run_validation().flags, [])


class TestDataLeavesMeridian(ValidatorCase):
    """"no" has several spellings, and YAML turns an unquoted no into False."""

    def assert_clean(self, value: str):
        self.write("care-notes.yaml", request_text(service="care-notes", data_leaves_meridian=value))
        result = self.run_validation()
        self.assertEqual(result.errors, [], f"{value!r} should be valid")
        self.assertEqual(result.flags, [], f"{value!r} should not be a judgment case")

    def test_unquoted_no_is_accepted(self):
        """YAML parses an unquoted no as the boolean False."""
        self.assert_clean("no")

    def test_quoted_no_is_accepted(self):
        self.assert_clean('"no"')

    def test_capital_no_is_accepted(self):
        self.assert_clean('"No"')

    def test_shouting_no_is_accepted(self):
        self.assert_clean('"NO"')

    def test_yaml_false_is_accepted(self):
        self.assert_clean("false")

    def test_all_spellings_normalise_to_no(self):
        for raw in [False, "no", "No", "NO", " no ", "false", "False"]:
            with self.subTest(raw=raw):
                self.assertEqual(v.normalise_data_leaves(raw), "no")

    def test_destination_is_a_judgment_case_not_an_error(self):
        self.write(
            "care-notes.yaml",
            request_text(service="care-notes", data_leaves_meridian='"sms-vendor"'),
        )
        result = self.run_validation()
        self.assertEqual(result.errors, [])
        self.assertTrue(result.ok)
        self.assertEqual(len(result.flags), 1)
        self.assertIn("sms-vendor", result.flags[0])

    def test_destination_with_spaces_is_an_error_in_plain_language(self):
        self.write(
            "care-notes.yaml",
            request_text(service="care-notes", data_leaves_meridian='"SMS Vendor"'),
        )
        result = self.run_validation()
        self.assertFalse(result.ok)
        message = next(e for e in result.errors if "data_leaves_meridian" in e)
        # Plain language: says what to write, and does not quote a regex.
        self.assertIn("SMS Vendor", message)
        self.assertIn("sms-vendor", message)
        self.assertNotIn("^", message)
        self.assertNotIn("does not match", message)

    def test_only_one_error_for_a_bad_destination(self):
        """The schema and the script must not both complain."""
        self.write(
            "care-notes.yaml",
            request_text(service="care-notes", data_leaves_meridian='"SMS Vendor"'),
        )
        errors = [e for e in self.run_validation().errors if "data_leaves_meridian" in e]
        self.assertEqual(len(errors), 1, errors)

    def test_true_is_an_error(self):
        self.write("care-notes.yaml", request_text(service="care-notes", data_leaves_meridian="true"))
        result = self.run_validation()
        self.assertFalse(result.ok)
        self.assertTrue(
            any("does not say anything" in e for e in result.errors), result.errors
        )

    def test_uppercase_destination_is_rejected(self):
        self.write(
            "care-notes.yaml",
            request_text(service="care-notes", data_leaves_meridian='"SMS-VENDOR"'),
        )
        self.assertFalse(self.run_validation().ok)

    def test_normalise_rejects_unusable_values(self):
        for raw in [True, "SMS Vendor", "sms vendor", "-leading", "SMS-VENDOR", 42, None]:
            with self.subTest(raw=raw):
                self.assertIsNone(v.normalise_data_leaves(raw))


class TestInvalidRequests(ValidatorCase):
    def test_missing_required_field(self):
        self.write("care-notes.yaml", request_text(service="care-notes", cost_center=None))
        result = self.run_validation()
        self.assertFalse(result.ok)
        self.assertTrue(any("cost_center" in e for e in result.errors), result.errors)

    def test_unknown_field_is_rejected(self):
        """The request must not be able to set path-owned properties."""
        self.write(
            "care-notes.yaml",
            request_text(service="care-notes", backup_retention_period="1"),
        )
        result = self.run_validation()
        self.assertFalse(result.ok)
        self.assertTrue(
            any("backup_retention_period" in e for e in result.errors), result.errors
        )

    def test_production_environment_is_rejected(self):
        self.write("care-notes.yaml", request_text(service="care-notes", environment="production"))
        result = self.run_validation()
        self.assertFalse(result.ok)

    def test_non_postgres_engine_is_rejected(self):
        self.write("care-notes.yaml", request_text(service="care-notes", engine="redis"))
        result = self.run_validation()
        self.assertFalse(result.ok)

    def test_unknown_size_is_rejected(self):
        self.write("care-notes.yaml", request_text(service="care-notes", size="enormous"))
        result = self.run_validation()
        self.assertFalse(result.ok)

    def test_unknown_classification_is_rejected(self):
        self.write("care-notes.yaml", request_text(service="care-notes", classification="maybe"))
        result = self.run_validation()
        self.assertFalse(result.ok)

    def test_not_a_mapping(self):
        self.write("care-notes.yaml", "- just\n- a\n- list\n")
        result = self.run_validation()
        self.assertFalse(result.ok)
        self.assertTrue(any("mapping" in e for e in result.errors), result.errors)

    def test_broken_yaml(self):
        self.write("care-notes.yaml", "service: [unclosed\n")
        result = self.run_validation()
        self.assertFalse(result.ok)
        self.assertTrue(any("not valid YAML" in e for e in result.errors), result.errors)

    def test_yml_extension_is_rejected(self):
        """Terraform's fileset only matches *.yaml, so a .yml file is invisible."""
        self.write("care-notes.yml", request_text(service="care-notes"))
        result = self.run_validation()
        self.assertFalse(result.ok)
        self.assertTrue(any(".yaml extension" in e for e in result.errors), result.errors)


class TestFileNameMatchesService(ValidatorCase):
    def test_file_name_must_equal_the_service_field(self):
        self.write("reminders.yaml", request_text(service="appointment-reminders"))
        result = self.run_validation()
        self.assertFalse(result.ok)
        self.assertTrue(
            any("should be named 'appointment-reminders.yaml'" in e for e in result.errors),
            result.errors,
        )

    def test_matching_name_passes(self):
        self.write("appointment-reminders.yaml", VALID)
        self.assertEqual(self.run_validation().errors, [])


class TestUniqueServiceNames(ValidatorCase):
    def test_duplicate_service_across_two_files_is_an_error(self):
        # Both files cannot be named after the service, so the name check fires
        # too; what matters is that the duplicate itself is reported.
        self.write("appointment-reminders.yaml", VALID)
        self.write("appointment-reminders-copy.yaml", VALID)
        result = self.run_validation()
        self.assertFalse(result.ok)
        self.assertTrue(
            any("must be unique" in e for e in result.errors), result.errors
        )

    def test_distinct_services_are_not_duplicates(self):
        self.write("appointment-reminders.yaml", VALID)
        self.write("care-notes.yaml", request_text(service="care-notes"))
        result = self.run_validation()
        self.assertFalse(any("must be unique" in e for e in result.errors))


class TestRdsIdentifierRules(unittest.TestCase):
    """The service name becomes the RDS instance identifier."""

    def test_accepted(self):
        for name in ["a", "appointment-reminders", "svc1", "a-b-c", "x" * 63]:
            with self.subTest(name=name):
                self.assertIsNone(v.rds_identifier_problem(name))

    def test_rejected(self):
        cases = {
            "": "is empty",
            "1service": "must start with a letter",
            "-service": "must start with a letter",
            "service-": "must not end with a hyphen",
            "two--hyphens": "must not contain two consecutive hyphens",
            "UPPERCASE": "lowercase letters, digits and single hyphens",
            "under_score": "lowercase letters, digits and single hyphens",
            "has space": "lowercase letters, digits and single hyphens",
            "x" * 64: "the maximum is 63",
        }
        for name, expected in cases.items():
            with self.subTest(name=name):
                problem = v.rds_identifier_problem(name)
                self.assertIsNotNone(problem, f"{name!r} should be rejected")
                self.assertIn(expected, problem)

    def test_invalid_identifier_reported_through_the_validator(self):
        with tempfile.TemporaryDirectory() as tmp:
            d = pathlib.Path(tmp)
            (d / "bad_name.yaml").write_text(request_text(service="bad_name"))
            result = v.validate_all(d, SCHEMA)
            self.assertFalse(result.ok)
            self.assertTrue(
                any("cannot be a database identifier" in e for e in result.errors),
                result.errors,
            )


class TestExitStatus(ValidatorCase):
    def test_exit_zero_when_valid(self):
        self.write("appointment-reminders.yaml", VALID)
        self.assertEqual(v.main(["--requests", str(self.dir), "--schema", str(SCHEMA)]), 0)

    def test_exit_zero_with_only_judgment_cases(self):
        self.write("care-notes.yaml", request_text(service="care-notes", classification="unsure"))
        self.assertEqual(v.main(["--requests", str(self.dir), "--schema", str(SCHEMA)]), 0)

    def test_exit_one_on_error(self):
        self.write("care-notes.yaml", request_text(service="care-notes", engine="redis"))
        self.assertEqual(v.main(["--requests", str(self.dir), "--schema", str(SCHEMA)]), 1)

    def test_json_output_is_parseable(self):
        import contextlib
        import io

        self.write("care-notes.yaml", request_text(service="care-notes", classification="unsure"))
        buffer = io.StringIO()
        with contextlib.redirect_stdout(buffer):
            v.main(["--requests", str(self.dir), "--schema", str(SCHEMA), "--json"])
        payload = json.loads(buffer.getvalue())
        self.assertEqual(payload["errors"], [])
        self.assertEqual(len(payload["flags"]), 1)


if __name__ == "__main__":
    unittest.main()

"""Synthetic behavioural tests of preparation and failure isolation."""
import itertools
import unittest
from dataclasses import replace
from typing import cast

from reference.credentialing_checks import Check, Colour, Kind, Result, assess, delivery_key


class ChecksTest(unittest.TestCase):
    def setUp(self) -> None:
        self.check = Check("evidence", "1", Kind.DETERMINISTIC, True, True, frozenset({"source-1"}))
        self.result = Result("evidence", "1", "revision-1", Colour.GREEN, "checked", ("source-1",))

    def test_green_is_prepared_not_a_decision(self) -> None:
        value = assess([self.check], {"evidence": lambda: self.result}, "revision-1")
        self.assertTrue(value.ready_for_decision_review)
        self.assertEqual(value.colour, Colour.GREEN)
        self.assertEqual(value.information_requests, ())
        self.assertFalse(hasattr(value, "approved"))

    def test_only_approved_objective_information_requests_are_automatic(self) -> None:
        for kind, colour, enabled, permission, reason in itertools.product(
            list(Kind), [Colour.RED, Colour.AMBER], [False, True], [False, True],
            ["missing-evidence", "invalid-format", "expired-document", "competence-concern"],
        ):
            check = replace(self.check, kind=kind, automatic_information_request=permission)
            result = replace(self.result, colour=colour, reason=reason)
            value = assess([check], {"evidence": lambda: result}, "revision-1",
                           automatic_requests_enabled=enabled)
            expected = enabled and permission and kind == Kind.DETERMINISTIC and reason != "competence-concern"
            with self.subTest(kind=kind, colour=colour, reason=reason, enabled=enabled, permission=permission):
                self.assertEqual(bool(value.information_requests), expected)
                self.assertEqual(bool(value.human_review), not expected)
                self.assertFalse(value.ready_for_decision_review)

    def test_failure_does_not_stop_other_workers_or_disclose_errors(self) -> None:
        executed: list[str] = []

        def failed() -> Result:
            raise RuntimeError("sensitive exception content")

        def successful() -> Result:
            executed.append("completed")
            return replace(self.result, check_id="second")

        value = assess([self.check, replace(self.check, identifier="second")],
                       {"evidence": failed, "second": successful}, "revision-1")
        self.assertEqual(executed, ["completed"])
        self.assertEqual(value.colour, Colour.UNAVAILABLE)
        self.assertEqual(value.results[0].reason, "worker-failed")
        self.assertEqual(value.results[1].colour, Colour.GREEN)
        self.assertNotIn("sensitive", repr(value))

    def test_unconfigured_worker_is_not_a_negative_practitioner_finding(self) -> None:
        value = assess([self.check], {}, "revision-1")
        self.assertEqual(value.unavailable, ("evidence",))
        self.assertEqual(value.information_requests, ())
        self.assertFalse(value.ready_for_decision_review)

    def test_optional_failure_does_not_block_mandatory_preparation(self) -> None:
        value = assess([replace(self.check, mandatory=False)], {}, "revision-1")
        self.assertTrue(value.ready_for_decision_review)
        self.assertEqual(value.colour, Colour.UNAVAILABLE)

    def test_all_non_green_required_results_block_readiness(self) -> None:
        for colour in [Colour.RED, Colour.AMBER, Colour.UNAVAILABLE]:
            value = assess([self.check], {"evidence": lambda: replace(self.result, colour=colour)}, "revision-1")
            self.assertFalse(value.ready_for_decision_review)

    def test_stale_identity_version_and_revision_are_unavailable(self) -> None:
        for field in ["check_id", "check_version", "revision"]:
            result = replace(self.result, **{field: "wrong"})
            value = assess([self.check], {"evidence": lambda: result}, "revision-1")
            self.assertEqual(value.results[0].reason, "stale-or-mismatched-response")

    def test_invalid_results_never_become_green(self) -> None:
        invalid = [
            replace(self.result, colour=cast(Colour, "green")),
            replace(self.result, reason=" "), replace(self.result, evidence=()),
            replace(self.result, evidence=("",)),
            replace(self.result, evidence=("untrusted-source",)),
            replace(self.result, evidence=(" ",)),
        ]
        for result in invalid:
            value = assess([self.check], {"evidence": lambda: result}, "revision-1")
            self.assertEqual(value.colour, Colour.UNAVAILABLE)

    def test_not_applicable_requires_authority(self) -> None:
        result = replace(self.result, colour=Colour.NOT_APPLICABLE, evidence=())
        denied = assess([self.check], {"evidence": lambda: result}, "revision-1")
        self.assertEqual(denied.colour, Colour.UNAVAILABLE)
        allowed = assess([replace(self.check, exemption_authority="verified-policy-1")], {"evidence": lambda: replace(result, exemption_authority="verified-policy-1")}, "revision-1")
        self.assertTrue(allowed.ready_for_decision_review)
        forged = assess([self.check], {"evidence": lambda: replace(result, exemption_authority="forged")}, "revision-1")
        self.assertEqual(forged.colour, Colour.UNAVAILABLE)

    def test_red_and_unavailable_remain_separately_visible(self) -> None:
        second = replace(self.check, identifier="second")
        value = assess([self.check, second], {"evidence": lambda: replace(self.result, colour=Colour.RED)}, "revision-1")
        self.assertEqual(value.colour, Colour.RED)
        self.assertEqual(value.unavailable, ("second",))

    def test_definition_validation(self) -> None:
        bad_sets = [[], [self.check, self.check], [replace(self.check, identifier="")],
                    [replace(self.check, version="")], [replace(self.check, kind=cast(Kind, "unknown"))]]
        for checks in bad_sets:
            with self.assertRaises(ValueError):
                assess(checks, {}, "revision-1")
        with self.assertRaises(ValueError):
            assess([self.check], {}, " ")

    def test_deduplication_key_is_revision_bound_and_unambiguous(self) -> None:
        key = delivery_key("case-1", "revision-1", self.check)
        self.assertEqual(key, delivery_key("case-1", "revision-1", self.check))
        self.assertNotEqual(key, delivery_key("case-1", "revision-2", self.check))
        self.assertNotEqual(key, delivery_key("case-2", "revision-1", self.check))
        self.assertNotEqual(key, delivery_key("case-1", "revision-1", replace(self.check, version="2")))
        with self.assertRaises(ValueError):
            delivery_key("", "revision-1", self.check)

"""Independent synthetic jobs: leases, bounded retries and no adverse decisions."""
import unittest
from dataclasses import replace
from datetime import UTC, datetime, timedelta
from typing import cast

from reference.check_jobs import Job, Phase
from reference.credentialing_checks import Check, Colour, Kind, Result


class JobTest(unittest.TestCase):
    def setUp(self) -> None:
        self.at = datetime(2026, 9, 22, tzinfo=UTC)
        self.check = Check("evidence", "1", Kind.DETERMINISTIC,
                           evidence_manifest=frozenset({"manifest-1"}))
        self.job = Job("case-1", "revision-1", self.check, timeout_seconds=10,
                       retry_seconds=5, max_attempts=2)
        self.result = Result("evidence", "1", "revision-1", Colour.GREEN,
                             "requirements-present", ("manifest-1",))

    def test_one_job_completes_while_another_times_out(self) -> None:
        working = self.job.start(self.at)
        failing = replace(self.job, check=replace(self.check, identifier="other")).start(self.at)
        complete = working.finish(working.token, self.result, self.at)
        timed_out = failing.expire(self.at + timedelta(seconds=10))
        self.assertEqual(complete.phase, Phase.COMPLETE)
        self.assertEqual(timed_out.phase, Phase.RETRY)
        self.assertEqual(complete.result, self.result)
        self.assertEqual(working.phase, Phase.RUNNING)
        self.assertEqual(self.job.phase, Phase.QUEUED)

    def test_timeout_boundary_and_nonrunning_expiry(self) -> None:
        job = self.job.start(self.at)
        self.assertIs(job.expire(self.at + timedelta(seconds=9)), job)
        self.assertEqual(job.expire(self.at + timedelta(seconds=10)).phase, Phase.RETRY)
        self.assertIs(self.job.expire(self.at), self.job)

    def test_retry_has_a_new_token_and_a_finite_limit(self) -> None:
        first = self.job.start(self.at)
        retry = first.fail(first.token, self.at)
        with self.assertRaises(ValueError):
            retry.start(self.at + timedelta(seconds=4))
        second = retry.start(self.at + timedelta(seconds=5))
        self.assertNotEqual(second.token, first.token)
        self.assertEqual(second.attempt, 2)
        with self.assertRaises(ValueError):
            second.finish(first.token, self.result, self.at + timedelta(seconds=5))
        exhausted = second.fail(second.token, self.at + timedelta(seconds=5))
        self.assertEqual(exhausted.phase, Phase.SUPPORT)
        self.assertIsNotNone(exhausted.result)
        self.assertEqual(exhausted.result.colour if exhausted.result else None, Colour.UNAVAILABLE)
        with self.assertRaises(ValueError):
            exhausted.start(self.at + timedelta(seconds=30))

    def test_late_response_is_a_technical_timeout_not_a_red_finding(self) -> None:
        job = self.job.start(self.at)
        late = job.finish(job.token, self.result, self.at + timedelta(seconds=10))
        self.assertEqual(late.phase, Phase.RETRY)
        self.assertEqual(late.result, Result("evidence", "1", "revision-1",
                                            Colour.UNAVAILABLE, "timeout"))

    def test_mismatched_evidence_and_revision_do_not_complete(self) -> None:
        job = self.job.start(self.at)
        for result in (replace(self.result, revision="previous"),
                       replace(self.result, evidence=("not-in-manifest",)),
                       replace(self.result, colour=Colour.UNAVAILABLE)):
            with self.subTest(result=result):
                failed = job.finish(job.token, result, self.at)
                self.assertEqual(failed.phase, Phase.RETRY)
                self.assertEqual(failed.result.reason if failed.result else "", "worker-failed")

    def test_complete_replay_is_idempotent_but_altered_replay_is_rejected(self) -> None:
        job = self.job.start(self.at)
        complete = job.finish(job.token, self.result, self.at)
        self.assertIs(complete.finish(job.token, self.result, self.at), complete)
        with self.assertRaises(ValueError):
            complete.finish(job.token, replace(self.result, colour=Colour.RED), self.at)
        with self.assertRaises(ValueError):
            complete.fail(job.token, self.at)
        with self.assertRaises(ValueError):
            complete.start(self.at)

    def test_business_findings_do_not_trigger_technical_retry(self) -> None:
        for kind in Kind:
            for colour in (Colour.GREEN, Colour.AMBER, Colour.RED):
                with self.subTest(kind=kind, colour=colour):
                    job = replace(self.job, check=replace(self.check, kind=kind)).start(self.at)
                    result = replace(self.result, colour=colour)
                    complete = job.finish(job.token, result, self.at)
                    self.assertEqual(complete.phase, Phase.COMPLETE)
                    self.assertEqual(complete.result, result)
                    self.assertFalse(hasattr(complete, "approved"))
                    self.assertFalse(hasattr(complete, "send_to_applicant"))

    def test_forged_tokens_and_raw_errors_are_rejected(self) -> None:
        job = self.job.start(self.at)
        for token in ("", "other"):
            with self.assertRaises(ValueError):
                job.fail(token, self.at)
        with self.assertRaises(ValueError):
            job.fail(job.token, self.at, "private document contents")
        self.assertEqual(job.fail(job.token, self.at, "adapter-unavailable").phase, Phase.RETRY)

    def test_numeric_limits_reject_booleans_and_nonpositive_values(self) -> None:
        for field in ("timeout_seconds", "retry_seconds", "max_attempts"):
            for value in (0, -1, True, 0.5):
                with self.subTest(field=field, value=value), self.assertRaises(ValueError):
                    replace(self.job, **{field: cast(int, value)})

    def test_naive_time_and_missing_identity_are_rejected(self) -> None:
        with self.assertRaises(ValueError):
            self.job.start(self.at.replace(tzinfo=None))
        with self.assertRaises(ValueError):
            replace(self.job, case_id="")

    def test_new_application_revision_is_not_an_old_retry(self) -> None:
        first = self.job.start(self.at)
        next_revision = replace(self.job, revision="revision-2").start(self.at)
        self.assertNotEqual(first.token, next_revision.token)
        with self.assertRaises(ValueError):
            next_revision.finish(first.token, self.result, self.at)

    def test_check_version_changes_delivery_identity(self) -> None:
        first = self.job.start(self.at)
        new_check = replace(self.job, check=replace(self.check, version="2")).start(self.at)
        self.assertNotEqual(first.token, new_check.token)
        self.assertEqual(new_check.attempt, 1)

    def test_clock_reversal_and_corrupted_retry_counter_do_not_progress(self) -> None:
        job = self.job.start(self.at)
        earlier = self.at - timedelta(seconds=1)
        with self.assertRaises(ValueError):
            job.finish(job.token, self.result, earlier)
        with self.assertRaises(ValueError):
            job.fail(job.token, earlier)
        with self.assertRaises(ValueError):
            replace(self.job, attempt=self.job.max_attempts).start(self.at)

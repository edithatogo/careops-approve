"""Per-check leases and bounded retries; no worker execution or external writes.

Each object belongs to one immutable application revision. A protected durable
adapter must authenticate worker events and perform atomic compare-and-swap.
Nothing waits for a worker, and one job transition cannot mutate another job.
"""
from dataclasses import dataclass, replace
from datetime import UTC, datetime, timedelta
from enum import StrEnum
from hashlib import sha256

from reference.credentialing_checks import Check, Colour, Result, assess, delivery_key


class Phase(StrEnum):
    QUEUED = "queued"
    RUNNING = "running"
    COMPLETE = "complete"
    RETRY = "retry"
    SUPPORT = "technical-attention"


def _utc(value: datetime) -> datetime:
    if value.tzinfo is None or value.utcoffset() is None:
        raise ValueError("Timezone-aware timestamp required")
    return value.astimezone(UTC)


@dataclass(frozen=True)
class Job:
    """An independent check job; technical status is distinct from check colour."""

    case_id: str
    revision: str
    check: Check
    timeout_seconds: int = 120
    retry_seconds: int = 30
    max_attempts: int = 2
    phase: Phase = Phase.QUEUED
    attempt: int = 0
    token: str = ""
    deadline: datetime | None = None
    ready_at: datetime | None = None
    result: Result | None = None

    def __post_init__(self) -> None:
        delivery_key(self.case_id, self.revision, self.check)
        for number in (self.timeout_seconds, self.retry_seconds, self.max_attempts):
            if type(number) is not int or number < 1:
                raise ValueError("Timeout, retry delay and attempt limit must be positive integers")

    def start(self, at: datetime) -> "Job":
        """Plan one attempt; callers dispatch an isolated worker after committing."""
        instant = _utc(at)
        if self.phase not in {Phase.QUEUED, Phase.RETRY} or self.attempt >= self.max_attempts:
            raise ValueError("Job is not dispatchable")
        if self.ready_at is not None and instant < self.ready_at:
            raise ValueError("Retry backoff has not elapsed")
        attempt = self.attempt + 1
        identity = f"{delivery_key(self.case_id, self.revision, self.check)}:{attempt}"
        return replace(self, phase=Phase.RUNNING, attempt=attempt,
                       token=sha256(identity.encode()).hexdigest(),
                       deadline=instant + timedelta(seconds=self.timeout_seconds),
                       ready_at=None, result=None)

    def _check_token(self, token: str) -> None:
        if not token or token != self.token:
            raise ValueError("Stale or mismatched attempt token")

    def fail(self, token: str, at: datetime, reason: str = "worker-failed") -> "Job":
        """Record only an allowlisted technical cause, never raw exception text."""
        self._check_token(token)
        instant = _utc(at)
        if self.phase != Phase.RUNNING or self.deadline is None:
            raise ValueError("Only a running attempt can fail")
        if instant < self.deadline - timedelta(seconds=self.timeout_seconds):
            raise ValueError("Event predates the running attempt")
        if reason not in {"worker-failed", "timeout", "adapter-unavailable"}:
            raise ValueError("Unsupported technical reason")
        retry = self.attempt < self.max_attempts
        result = Result(self.check.identifier, self.check.version, self.revision,
                        Colour.UNAVAILABLE, reason)
        return replace(self, phase=Phase.RETRY if retry else Phase.SUPPORT,
                       deadline=None, ready_at=instant + timedelta(seconds=self.retry_seconds),
                       result=result)

    def finish(self, token: str, result: Result, at: datetime) -> "Job":
        """Accept a version-bound response; findings are not technical failures.

        Exact successful replay is harmless. Late/forged events cannot replace
        current results. Validation reuses the existing evidence-bound kernel.
        """
        self._check_token(token)
        instant = _utc(at)
        if self.phase == Phase.COMPLETE and result == self.result:
            return self
        if self.phase != Phase.RUNNING or self.deadline is None:
            raise ValueError("No running lease for this result")
        if instant < self.deadline - timedelta(seconds=self.timeout_seconds):
            raise ValueError("Event predates the running attempt")
        if instant >= self.deadline:
            return self.fail(token, instant, "timeout")
        checked = assess([self.check], {self.check.identifier: lambda: result},
                         self.revision).results[0]
        if checked.colour == Colour.UNAVAILABLE:
            return self.fail(token, instant, "worker-failed")
        return replace(self, phase=Phase.COMPLETE, deadline=None, result=checked)

    def expire(self, at: datetime) -> "Job":
        """A watchdog advances only this lease; no worker needs to return first."""
        instant = _utc(at)
        if self.phase == Phase.RUNNING and self.deadline is not None and instant >= self.deadline:
            return self.fail(self.token, instant, "timeout")
        return self

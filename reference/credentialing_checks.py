"""Pure reference implementation of independent credentialing checks.

No connectors, messages, register writes or credentialing decisions are made.
Workers must be isolated and time-bounded by their hosting adapter. Inputs must
come from an authorised, immutable case revision; never from an agent's prompt.
"""
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass
from enum import StrEnum
from hashlib import sha256
from json import dumps


class Colour(StrEnum):
    """Check outcome, never a rating of a practitioner."""

    GREEN = "green"
    AMBER = "amber"
    RED = "red"
    UNAVAILABLE = "unavailable"
    NOT_APPLICABLE = "not-applicable"


class Kind(StrEnum):
    """Who or what produced a check."""

    DETERMINISTIC = "deterministic"
    AGENTIC = "agentic"
    HUMAN = "human"


@dataclass(frozen=True)
class Check:
    """An approved check definition, not agent-editable configuration."""

    identifier: str
    version: str
    kind: Kind
    mandatory: bool = True
    automatic_information_request: bool = False
    evidence_manifest: frozenset[str] = frozenset()
    exemption_authority: str = ""


@dataclass(frozen=True)
class Result:
    """Version-bound worker response containing references, not raw evidence."""

    check_id: str
    check_version: str
    revision: str
    colour: Colour
    reason: str
    evidence: tuple[str, ...] = ()
    exemption_authority: str = ""


@dataclass(frozen=True)
class Assessment:
    """Preparation summary; decision authority is deliberately not represented."""

    colour: Colour
    results: tuple[Result, ...]
    information_requests: tuple[str, ...]
    human_review: tuple[str, ...]
    unavailable: tuple[str, ...]
    ready_for_decision_review: bool


Worker = Callable[[], Result]
_SAFE_INFORMATION_REASONS = frozenset({"missing-evidence", "invalid-format", "expired-document"})


def _unavailable(check: Check, revision: str, reason: str) -> Result:
    return Result(check.identifier, check.version, revision, Colour.UNAVAILABLE, reason)


def _validate(check: Check, result: Result, revision: str) -> Result:
    if (result.check_id, result.check_version, result.revision) != (
        check.identifier, check.version, revision,
    ):
        return _unavailable(check, revision, "stale-or-mismatched-response")
    if not isinstance(result.colour, Colour) or not result.reason.strip():
        return _unavailable(check, revision, "invalid-response")
    if result.colour == Colour.NOT_APPLICABLE:
        if not check.exemption_authority.strip() or result.exemption_authority != check.exemption_authority:
            return _unavailable(check, revision, "missing-exemption-authority")
    elif result.colour != Colour.UNAVAILABLE and any(not ref.strip() or ref not in check.evidence_manifest for ref in result.evidence):
        return _unavailable(check, revision, "invalid-evidence-reference")
    if result.colour not in {Colour.UNAVAILABLE, Colour.NOT_APPLICABLE} and not result.evidence:
        return _unavailable(check, revision, "missing-evidence-reference")
    return result


def assess(
    checks: Sequence[Check],
    workers: Mapping[str, Worker],
    revision: str,
    *,
    automatic_requests_enabled: bool = False,
) -> Assessment:
    """Run independent workers and deterministically prepare the next actions.

    A deterministic worker may identify an absent field by referencing the
    application revision. Agentic red/amber results never cause an automatic
    applicant return. This returns an action plan, not external communications.
    """
    identifiers = [check.identifier for check in checks]
    if not checks or not revision.strip() or len(set(identifiers)) != len(identifiers):
        raise ValueError("A case revision and nonempty, unique check definitions are required")
    if any(not check.identifier.strip() or not check.version.strip() for check in checks):
        raise ValueError("Each check requires an identifier and version")
    if any(not isinstance(check.kind, Kind) for check in checks):
        raise ValueError("Each check requires a supported kind")
    results: list[Result] = []
    requests: list[str] = []
    review: list[str] = []
    unavailable: list[str] = []
    ready = True
    for check in checks:
        worker = workers.get(check.identifier)
        if worker is None:
            result = _unavailable(check, revision, "worker-not-configured")
        else:
            try:
                result = _validate(check, worker(), revision)
            except Exception:  # Worker boundary: do not expose exception text or raw data.
                result = _unavailable(check, revision, "worker-failed")
        results.append(result)
        if result.colour == Colour.UNAVAILABLE:
            unavailable.append(check.identifier)
        if result.colour not in {Colour.GREEN, Colour.NOT_APPLICABLE}:
            if check.mandatory:
                ready = False
            if (
                automatic_requests_enabled
                and check.kind == Kind.DETERMINISTIC
                and check.automatic_information_request
                and result.colour in {Colour.RED, Colour.AMBER}
                and result.reason in _SAFE_INFORMATION_REASONS
            ):
                requests.append(check.identifier)
            else:
                review.append(check.identifier)
    colours = {result.colour for result in results}
    if Colour.RED in colours:
        colour = Colour.RED
    elif Colour.AMBER in colours:
        colour = Colour.AMBER
    elif Colour.UNAVAILABLE in colours:
        colour = Colour.UNAVAILABLE
    else:
        colour = Colour.GREEN
    return Assessment(
        colour, tuple(results), tuple(requests), tuple(review), tuple(unavailable), ready,
    )


def delivery_key(case_id: str, revision: str, check: Check) -> str:
    """Stable, unambiguous key for adapter-side deduplication of an action.

    A new application/renewal revision is not a replay of the old revision.
    Persistent delivery and atomic outbox writes remain adapter responsibilities.
    """
    parts = (case_id, revision, check.identifier, check.version)
    if not all(part.strip() for part in parts):
        raise ValueError("Delivery identity fields cannot be empty")
    return sha256(dumps(parts, separators=(",", ":")).encode()).hexdigest()

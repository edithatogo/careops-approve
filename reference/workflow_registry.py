"""Reference lifecycle store for versioned CareOps workflow definitions.

This in-memory implementation specifies registry semantics only. Production
adapters must provide durable transactional storage, authorization, audit,
backup/recovery and cross-instance concurrency controls.
"""
from copy import deepcopy
from dataclasses import dataclass, replace
from enum import StrEnum
from typing import cast

from reference.workflow_compiler import compile_workflow, definition_hash


class VersionState(StrEnum):
    DRAFT = "draft"
    ACTIVE = "active"
    RETIRED = "retired"


@dataclass(frozen=True)
class WorkflowVersionRecord:
    workflow_id: str
    version: str
    state: VersionState
    definition_hash: str
    etag: str
    revision: int
    definition: dict[str, object]


@dataclass(frozen=True)
class PublicationRequest:
    workflow_id: str
    version: str
    definition_hash: str
    requested_by_role: str
    validation_status: str
    test_status: str
    governance_status: str
    requested_action: str
    migration_policy: str
    supersedes_version: str = ""


def _clone(definition: dict[str, object]) -> dict[str, object]:
    return cast(dict[str, object], deepcopy(definition))


def _identity(definition: dict[str, object]) -> tuple[str, str]:
    workflow_id = definition.get("workflowId")
    version = definition.get("version")
    if not isinstance(workflow_id, str) or not workflow_id.strip():
        raise ValueError("workflowId must be a nonempty string")
    if not isinstance(version, str) or not version.strip():
        raise ValueError("version must be a nonempty string")
    return workflow_id, version


def _etag(revision: int, digest: str) -> str:
    if revision < 1 or not digest.startswith("sha256:"):
        raise ValueError("ETag inputs are invalid")
    return f'"{revision}-{digest[7:23]}"'


def _copy_record(record: WorkflowVersionRecord) -> WorkflowVersionRecord:
    return replace(record, definition=_clone(record.definition))


class WorkflowRegistry:
    """Deterministic version lifecycle with optimistic concurrency."""

    def __init__(self) -> None:
        self._records: dict[tuple[str, str], WorkflowVersionRecord] = {}

    def get(self, workflow_id: str, version: str) -> WorkflowVersionRecord:
        key = (workflow_id, version)
        if key not in self._records:
            raise KeyError("Workflow version was not found")
        return _copy_record(self._records[key])

    def list_versions(self, workflow_id: str) -> tuple[WorkflowVersionRecord, ...]:
        if not workflow_id.strip():
            raise ValueError("workflowId is required")
        values = [
            _copy_record(record)
            for (candidate_id, _), record in self._records.items()
            if candidate_id == workflow_id
        ]
        return tuple(sorted(values, key=lambda record: record.version))

    def save_draft(
        self,
        definition: dict[str, object],
        *,
        expected_etag: str | None = None,
    ) -> WorkflowVersionRecord:
        workflow_id, version = _identity(definition)
        if definition.get("status") != VersionState.DRAFT.value:
            raise ValueError("Only draft definitions may be saved through the draft operation")

        key = (workflow_id, version)
        current = self._records.get(key)
        if current is not None and current.state != VersionState.DRAFT:
            raise ValueError("Published workflow versions are immutable")

        digest = definition_hash(definition)
        if current is None:
            if expected_etag is not None:
                raise ValueError("A new draft cannot supply an existing ETag")
            revision = 1
        else:
            if expected_etag != current.etag:
                raise ValueError("Workflow draft ETag does not match the current revision")
            revision = current.revision + 1

        stored = WorkflowVersionRecord(
            workflow_id,
            version,
            VersionState.DRAFT,
            digest,
            _etag(revision, digest),
            revision,
            _clone(definition),
        )
        self._records[key] = stored
        return _copy_record(stored)

    def publish(self, request: PublicationRequest) -> WorkflowVersionRecord:
        self._validate_request(request, action="publish")
        key = (request.workflow_id, request.version)
        if key not in self._records:
            raise KeyError("Workflow version was not found")
        draft = self._records[key]
        if draft.state != VersionState.DRAFT:
            raise ValueError("Only a draft workflow version can be published")
        if draft.definition_hash != request.definition_hash:
            raise ValueError("Publication hash does not match the stored draft")

        active = [
            record
            for (workflow_id, _), record in self._records.items()
            if workflow_id == request.workflow_id and record.state == VersionState.ACTIVE
        ]
        if len(active) > 1:
            raise RuntimeError("Registry invariant violated: multiple active workflow versions")
        if active:
            prior = active[0]
            if request.supersedes_version != prior.version:
                raise ValueError("Publishing over an active version requires an explicit supersedesVersion")
        elif request.supersedes_version:
            raise ValueError("supersedesVersion was supplied but no active version exists")

        compile_workflow(draft.definition)

        active_definition = _clone(draft.definition)
        active_definition["status"] = VersionState.ACTIVE.value
        digest = definition_hash(active_definition)
        revision = draft.revision + 1
        published = WorkflowVersionRecord(
            draft.workflow_id,
            draft.version,
            VersionState.ACTIVE,
            digest,
            _etag(revision, digest),
            revision,
            active_definition,
        )

        if active:
            prior = active[0]
            retired_definition = _clone(prior.definition)
            retired_definition["status"] = VersionState.RETIRED.value
            retired_digest = definition_hash(retired_definition)
            retired_revision = prior.revision + 1
            self._records[(prior.workflow_id, prior.version)] = WorkflowVersionRecord(
                prior.workflow_id,
                prior.version,
                VersionState.RETIRED,
                retired_digest,
                _etag(retired_revision, retired_digest),
                retired_revision,
                retired_definition,
            )
        self._records[key] = published
        return _copy_record(published)

    def retire(self, request: PublicationRequest) -> WorkflowVersionRecord:
        self._validate_request(request, action="retire")
        key = (request.workflow_id, request.version)
        if key not in self._records:
            raise KeyError("Workflow version was not found")
        current = self._records[key]
        if current.state != VersionState.ACTIVE:
            raise ValueError("Only an active workflow version can be retired")
        if current.definition_hash != request.definition_hash:
            raise ValueError("Retirement hash does not match the active definition")
        if request.supersedes_version:
            raise ValueError("A retirement request cannot supersede another version")

        definition = _clone(current.definition)
        definition["status"] = VersionState.RETIRED.value
        digest = definition_hash(definition)
        revision = current.revision + 1
        retired = WorkflowVersionRecord(
            current.workflow_id,
            current.version,
            VersionState.RETIRED,
            digest,
            _etag(revision, digest),
            revision,
            definition,
        )
        self._records[key] = retired
        return _copy_record(retired)

    @staticmethod
    def _validate_request(request: PublicationRequest, *, action: str) -> None:
        if request.requested_action != action:
            raise ValueError(f"Publication request action must be '{action}'")
        if not request.workflow_id.strip() or not request.version.strip():
            raise ValueError("Publication request workflow identity is required")
        if not request.definition_hash.startswith("sha256:"):
            raise ValueError("Publication request requires a SHA-256 definition hash")
        if not request.requested_by_role.strip():
            raise ValueError("Publication request requires a requester role")
        if request.validation_status != "passed" or request.test_status != "passed":
            raise ValueError("Publication requires passed validation and test evidence")
        if request.governance_status not in {"approved", "not-required"}:
            raise ValueError("Publication governance status is invalid")
        if request.migration_policy not in {
            "no-running-case-migration",
            "explicit-reviewed-migration",
        }:
            raise ValueError("Publication request requires an approved migration policy")

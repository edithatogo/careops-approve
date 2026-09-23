"""Reference service binding workflow registry versions to runtime execution.

This layer demonstrates how API adapters should combine registry lifecycle,
semantic compilation and case execution without allowing draft workflows to run.
"""
from dataclasses import dataclass

from reference.workflow_compiler import compile_active_workflow, compile_workflow
from reference.workflow_registry import VersionState, WorkflowRegistry
from reference.workflow_runtime import Case, Progress, complete_current, start_case


@dataclass(frozen=True)
class ValidationResult:
    workflow_id: str
    version: str
    definition_hash: str
    deployable: bool
    errors: tuple[str, ...]


class WorkflowService:
    """Bounded orchestration facade over a workflow registry."""

    def __init__(self, registry: WorkflowRegistry) -> None:
        self._registry = registry

    def validate_version(self, workflow_id: str, version: str) -> ValidationResult:
        record = self._registry.get(workflow_id, version)
        try:
            compile_workflow(record.definition)
        except ValueError as exc:
            return ValidationResult(
                workflow_id,
                version,
                record.definition_hash,
                False,
                (str(exc),),
            )
        return ValidationResult(
            workflow_id,
            version,
            record.definition_hash,
            True,
            (),
        )

    def create_case(
        self,
        workflow_id: str,
        version: str,
        case_id: str,
        revision: str,
    ) -> Progress:
        record = self._registry.get(workflow_id, version)
        if record.state != VersionState.ACTIVE:
            raise ValueError("New cases require an active workflow version")
        workflow = compile_active_workflow(record.definition)
        return start_case(workflow, case_id, revision)

    def advance_case(
        self,
        case: Case,
        *,
        next_sequence: int,
        route: str = "",
    ) -> Progress:
        record = self._registry.get(case.workflow_id, case.workflow_version)
        if record.state == VersionState.DRAFT:
            raise ValueError("Running cases cannot execute a draft workflow version")
        workflow = compile_workflow(record.definition)
        return complete_current(
            workflow,
            case,
            next_sequence=next_sequence,
            route=route,
        )

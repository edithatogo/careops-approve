"""Tests for registry-backed workflow service execution."""
import unittest
from typing import cast

from reference.workflow_compiler import TrustedBindings
from reference.workflow_registry import PublicationRequest, WorkflowRegistry
from reference.workflow_runtime import Case, CaseStatus, Task
from reference.workflow_service import WorkflowService


def definition(version: str = "1.0.0") -> dict[str, object]:
    return {
        "workflowId": "generic.review",
        "version": version,
        "status": "draft",
        "displayName": "Generic review",
        "entryNodeId": "intake",
        "nodes": [
            {"id": "intake", "type": "input", "displayName": "Intake", "config": {}},
            {
                "id": "review",
                "type": "human_review",
                "displayName": "Review",
                "config": {"assignedRole": "reviewer"},
            },
            {"id": "done", "type": "end", "displayName": "Done", "config": {}},
        ],
        "transitions": [
            {"from": "intake", "to": "review"},
            {"from": "review", "to": "done"},
        ],
    }


def request(value: dict[str, object], *, supersedes: str = "") -> PublicationRequest:
    from reference.workflow_compiler import definition_hash

    return PublicationRequest(
        workflow_id="generic.review",
        version=str(value["version"]),
        definition_hash=definition_hash(value),
        requested_by_role="workflow-admin",
        validation_status="passed",
        test_status="passed",
        governance_status="approved",
        requested_action="publish",
        migration_policy="no-running-case-migration",
        supersedes_version=supersedes,
    )


TRUSTED_BINDINGS = TrustedBindings(frozenset({"reviewer"}), frozenset())


class WorkflowServiceTest(unittest.TestCase):
    def test_service_exposes_safe_trusted_binding_contract(self) -> None:
        service = WorkflowService(WorkflowRegistry(TRUSTED_BINDINGS))
        self.assertEqual(
            service.trusted_bindings_contract(),
            {
                "schemaVersion": 1,
                "roles": [{"roleKey": "reviewer"}],
                "agents": [],
            },
        )

    def test_validate_deployable_and_reserved_drafts(self) -> None:
        registry = WorkflowRegistry(TRUSTED_BINDINGS)
        service = WorkflowService(registry)

        good = registry.save_draft(definition())
        valid = service.validate_version("generic.review", "1.0.0")
        self.assertTrue(valid.deployable)
        self.assertEqual(valid.definition_hash, good.definition_hash)
        self.assertEqual(valid.errors, ())
        self.assertEqual(
            valid.to_contract(),
            {
                "workflowId": "generic.review",
                "version": "1.0.0",
                "definitionHash": good.definition_hash,
                "deployable": True,
                "errors": [],
            },
        )

        reserved = definition("2.0.0")
        nodes = cast(list[dict[str, object]], reserved["nodes"])
        nodes[1] = {
            "id": "review",
            "type": "handoff",
            "displayName": "Handoff",
            "config": {"target": "external"},
        }
        registry.save_draft(reserved)
        invalid = service.validate_version("generic.review", "2.0.0")
        self.assertFalse(invalid.deployable)
        self.assertIn("reserved", invalid.errors[0])
        contract = invalid.to_contract()
        self.assertFalse(contract["deployable"])
        self.assertEqual(contract["errors"], list(invalid.errors))

    def test_validation_blocks_untrusted_role_reference(self) -> None:
        registry = WorkflowRegistry(TRUSTED_BINDINGS)
        service = WorkflowService(registry)
        forged = definition()
        nodes = cast(list[dict[str, object]], forged["nodes"])
        nodes[1]["config"] = {"assignedRole": "forged-role"}
        registry.save_draft(forged)
        result = service.validate_version("generic.review", "1.0.0")
        self.assertFalse(result.deployable)
        self.assertIn("trusted role", result.errors[0])

    def test_new_case_requires_active_version(self) -> None:
        registry = WorkflowRegistry(TRUSTED_BINDINGS)
        service = WorkflowService(registry)
        draft = registry.save_draft(definition())
        with self.assertRaisesRegex(ValueError, "active"):
            service.create_case("generic.review", "1.0.0", "CA-12345678", "r1")

        registry.publish(request(draft.definition))
        started = service.create_case("generic.review", "1.0.0", "CA-12345678", "r1")
        self.assertEqual(started.case.current_node, "intake")
        self.assertEqual(started.case.status, CaseStatus.RUNNING)

    def test_retired_version_cannot_start_new_case_but_existing_case_can_continue(self) -> None:
        registry = WorkflowRegistry(TRUSTED_BINDINGS)
        service = WorkflowService(registry)
        first = registry.save_draft(definition("1.0.0"))
        registry.publish(request(first.definition))
        started = service.create_case("generic.review", "1.0.0", "CA-EXISTING1", "r1")

        second = registry.save_draft(definition("2.0.0"))
        registry.publish(request(second.definition, supersedes="1.0.0"))

        with self.assertRaisesRegex(ValueError, "active"):
            service.create_case("generic.review", "1.0.0", "CA-NEWCASE01", "r1")

        review = service.advance_case(started.case, next_sequence=3)
        self.assertEqual(review.case.status, CaseStatus.WAITING_HUMAN)
        task = cast(Task, review.task)
        self.assertEqual(task.assigned_role, "reviewer")

        completed = service.advance_case(review.case, next_sequence=5)
        self.assertEqual(completed.case.status, CaseStatus.COMPLETED)

    def test_draft_version_cannot_advance_case(self) -> None:
        registry = WorkflowRegistry(TRUSTED_BINDINGS)
        service = WorkflowService(registry)
        registry.save_draft(definition())
        case = Case(
            "CA-DRAFT-001",
            "generic.review",
            "1.0.0",
            "r1",
            "intake",
            CaseStatus.RUNNING,
        )
        with self.assertRaisesRegex(ValueError, "draft"):
            service.advance_case(case, next_sequence=3)

    def test_missing_registry_version_propagates_not_found(self) -> None:
        service = WorkflowService(WorkflowRegistry(TRUSTED_BINDINGS))
        with self.assertRaises(KeyError):
            service.validate_version("missing.workflow", "1.0.0")
        with self.assertRaises(KeyError):
            service.create_case("missing.workflow", "1.0.0", "CA-MISSING01", "r1")

        case = Case(
            "CA-MISSING02",
            "missing.workflow",
            "1.0.0",
            "r1",
            "intake",
            CaseStatus.RUNNING,
        )
        with self.assertRaises(KeyError):
            service.advance_case(case, next_sequence=3)

    def test_runtime_route_is_forwarded(self) -> None:
        registry = WorkflowRegistry(TRUSTED_BINDINGS)
        service = WorkflowService(registry)
        routed = definition()
        routed["nodes"] = [
            {"id": "choice", "type": "condition", "displayName": "Choice", "config": {"ruleSet": "route.v1"}},
            {"id": "yes", "type": "end", "displayName": "Yes", "config": {}},
            {"id": "no", "type": "end", "displayName": "No", "config": {}},
        ]
        routed["entryNodeId"] = "choice"
        routed["transitions"] = [
            {"from": "choice", "to": "yes", "label": "yes"},
            {"from": "choice", "to": "no", "label": "no"},
        ]
        draft = registry.save_draft(routed)
        registry.publish(request(draft.definition))
        started = service.create_case("generic.review", "1.0.0", "CA-ROUTED001", "r1")
        done = service.advance_case(started.case, next_sequence=3, route="yes")
        self.assertEqual(done.case.status, CaseStatus.COMPLETED)


if __name__ == "__main__":
    unittest.main()

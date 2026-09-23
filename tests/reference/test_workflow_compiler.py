"""Tests for compiling GUI/API workflow definitions into runtime objects."""
import unittest
from math import nan

from reference.workflow_compiler import (
    compile_active_workflow,
    compile_workflow,
    definition_hash,
)
from reference.workflow_runtime import NodeType


def workflow_definition(*, status: str = "draft") -> dict[str, object]:
    return {
        "workflowId": "generic.review",
        "version": "1.0.0",
        "status": status,
        "displayName": "Generic review",
        "entryNodeId": "intake",
        "nodes": [
            {
                "id": "intake",
                "type": "input",
                "displayName": "Intake",
                "config": {"inputContract": "request.v1"},
            },
            {
                "id": "review",
                "type": "human_review",
                "displayName": "Review",
                "config": {"assignedRole": "reviewer"},
            },
            {
                "id": "done",
                "type": "end",
                "displayName": "Done",
                "config": {"outcome": "complete"},
            },
        ],
        "transitions": [
            {"from": "intake", "to": "review"},
            {"from": "review", "to": "done"},
        ],
    }


class WorkflowCompilerTest(unittest.TestCase):
    def test_compile_supported_definition(self) -> None:
        workflow = compile_workflow(workflow_definition())
        self.assertEqual(workflow.identifier, "generic.review")
        self.assertEqual(workflow.version, "1.0.0")
        self.assertEqual(workflow.entry_node, "intake")
        self.assertEqual(workflow.nodes[1].kind, NodeType.HUMAN_REVIEW)
        self.assertEqual(workflow.nodes[1].assigned_role, "reviewer")

    def test_active_compilation_requires_active_status(self) -> None:
        with self.assertRaisesRegex(ValueError, "active workflow"):
            compile_active_workflow(workflow_definition())
        workflow = compile_active_workflow(workflow_definition(status="active"))
        self.assertEqual(workflow.identifier, "generic.review")

    def test_reserved_and_unknown_node_types_fail_closed(self) -> None:
        reserved = workflow_definition()
        reserved_nodes = list(reserved["nodes"])  # type: ignore[arg-type]
        reserved_nodes[1] = {
            "id": "review",
            "type": "handoff",
            "displayName": "Handoff",
            "config": {"target": "external"},
        }
        reserved["nodes"] = reserved_nodes
        with self.assertRaisesRegex(ValueError, "reserved"):
            compile_workflow(reserved)

        unknown = workflow_definition()
        unknown_nodes = list(unknown["nodes"])  # type: ignore[arg-type]
        unknown_nodes[1] = {
            "id": "review",
            "type": "magic",
            "displayName": "Unknown",
            "config": {},
        }
        unknown["nodes"] = unknown_nodes
        with self.assertRaisesRegex(ValueError, "unsupported"):
            compile_workflow(unknown)

    def test_caller_may_not_supply_empty_supported_set(self) -> None:
        with self.assertRaisesRegex(ValueError, "At least one"):
            compile_workflow(workflow_definition(), supported_node_types=frozenset())

    def test_human_and_agent_configuration_is_semantically_checked(self) -> None:
        missing_role = workflow_definition()
        nodes = list(missing_role["nodes"])  # type: ignore[arg-type]
        nodes[1] = {
            "id": "review",
            "type": "approval",
            "displayName": "Approve",
            "config": {},
        }
        missing_role["nodes"] = nodes
        with self.assertRaisesRegex(ValueError, "assignedRole"):
            compile_workflow(missing_role)

        agent = workflow_definition()
        agent_nodes = list(agent["nodes"])  # type: ignore[arg-type]
        agent_nodes[1] = {
            "id": "review",
            "type": "agent",
            "displayName": "Agent",
            "config": {
                "humanReviewRequired": True,
                "failureMode": "ordinary-human-path",
            },
        }
        agent["nodes"] = agent_nodes
        compiled = compile_workflow(agent)
        self.assertTrue(compiled.nodes[1].human_review_required)
        self.assertEqual(compiled.nodes[1].failure_mode, "ordinary-human-path")

        bad_bool = workflow_definition()
        bad_bool_nodes = list(bad_bool["nodes"])  # type: ignore[arg-type]
        bad_bool_nodes[1] = {
            "id": "review",
            "type": "agent",
            "displayName": "Agent",
            "config": {
                "humanReviewRequired": "yes",
                "failureMode": "ordinary-human-path",
            },
        }
        bad_bool["nodes"] = bad_bool_nodes
        with self.assertRaisesRegex(ValueError, "boolean"):
            compile_workflow(bad_bool)

        bad_fallback = workflow_definition()
        bad_fallback_nodes = list(bad_fallback["nodes"])  # type: ignore[arg-type]
        bad_fallback_nodes[1] = {
            "id": "review",
            "type": "agent",
            "displayName": "Agent",
            "config": {
                "humanReviewRequired": True,
                "failureMode": "",
            },
        }
        bad_fallback["nodes"] = bad_fallback_nodes
        with self.assertRaisesRegex(ValueError, "failureMode"):
            compile_workflow(bad_fallback)

    def test_malformed_structures_are_rejected(self) -> None:
        cases: list[tuple[str, object]] = [
            ("workflowId", ""),
            ("version", 1),
            ("entryNodeId", None),
            ("nodes", "not-an-array"),
            ("transitions", {"from": "x"}),
        ]
        for field, value in cases:
            definition = workflow_definition()
            definition[field] = value
            with self.subTest(field=field):
                with self.assertRaises(ValueError):
                    compile_workflow(definition)

        bad_node = workflow_definition()
        bad_node["nodes"] = [123]
        with self.assertRaisesRegex(ValueError, "node must be an object"):
            compile_workflow(bad_node)

        nonstring_key = workflow_definition()
        nonstring_key["nodes"] = [{1: "invalid"}]
        with self.assertRaisesRegex(ValueError, "string keys"):
            compile_workflow(nonstring_key)

        missing_config = workflow_definition()
        missing_config["nodes"] = [
            {"id": "intake", "type": "input"},
            {"id": "done", "type": "end", "config": {}},
        ]
        missing_config["transitions"] = [{"from": "intake", "to": "done"}]
        with self.assertRaisesRegex(ValueError, "config"):
            compile_workflow(missing_config)

    def test_transition_shape_and_label_are_checked(self) -> None:
        nonobject = workflow_definition()
        nonobject["transitions"] = [123]
        with self.assertRaisesRegex(ValueError, "transition must be an object"):
            compile_workflow(nonobject)

        bad_source = workflow_definition()
        bad_source["transitions"] = [{"from": "", "to": "review"}]
        with self.assertRaisesRegex(ValueError, "transition.from"):
            compile_workflow(bad_source)

        bad_target = workflow_definition()
        bad_target["transitions"] = [{"from": "intake", "to": ""}]
        with self.assertRaisesRegex(ValueError, "transition.to"):
            compile_workflow(bad_target)

        bad_label = workflow_definition()
        bad_label["transitions"] = [
            {"from": "intake", "to": "review", "label": 7},
            {"from": "review", "to": "done"},
        ]
        with self.assertRaisesRegex(ValueError, "transition.label"):
            compile_workflow(bad_label)

    def test_runtime_graph_validation_remains_authoritative(self) -> None:
        definition = workflow_definition()
        definition["transitions"] = [{"from": "intake", "to": "review"}]
        with self.assertRaisesRegex(ValueError, "outgoing transition"):
            compile_workflow(definition)

    def test_definition_hash_is_canonical_and_rejects_non_json_values(self) -> None:
        first = workflow_definition()
        second = dict(reversed(list(first.items())))
        self.assertEqual(definition_hash(first), definition_hash(second))
        self.assertTrue(definition_hash(first).startswith("sha256:"))

        invalid = workflow_definition()
        invalid["bad"] = object()
        with self.assertRaisesRegex(ValueError, "JSON serializable"):
            definition_hash(invalid)

        nonfinite = workflow_definition()
        nonfinite["bad"] = nan
        with self.assertRaisesRegex(ValueError, "JSON serializable"):
            definition_hash(nonfinite)


if __name__ == "__main__":
    unittest.main()

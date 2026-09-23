"""Behavioural tests for the generic workflow runtime reference."""
import unittest
from dataclasses import replace
from typing import cast

from reference.workflow_runtime import (
    Case,
    CaseStatus,
    Node,
    NodeType,
    Transition,
    Workflow,
    _event,
    _stable_id,
    complete_current,
    start_case,
    validate_workflow,
)


def linear_workflow(*, middle_kind: NodeType = NodeType.HUMAN_REVIEW) -> Workflow:
    middle = Node(
        "review",
        middle_kind,
        assigned_role="reviewer" if middle_kind in {NodeType.HUMAN_REVIEW, NodeType.APPROVAL} else "",
        human_review_required=middle_kind == NodeType.AGENT,
        failure_mode="ordinary-human-path" if middle_kind == NodeType.AGENT else "",
    )
    return Workflow(
        "generic.review",
        "1.0.0",
        "intake",
        (Node("intake", NodeType.INPUT), middle, Node("done", NodeType.END)),
        (Transition("intake", "review"), Transition("review", "done")),
    )


class WorkflowRuntimeTest(unittest.TestCase):
    def test_linear_human_workflow_creates_and_completes_task(self) -> None:
        workflow = linear_workflow()
        started = start_case(workflow, "CA-12345678", "revision-1")
        self.assertEqual(started.case.status, CaseStatus.RUNNING)
        self.assertEqual(started.case.current_node, "intake")
        self.assertIsNone(started.task)
        self.assertEqual([event.event_type for event in started.events], ["case.created", "node.entered"])

        review = complete_current(workflow, started.case, next_sequence=3)
        self.assertEqual(review.case.status, CaseStatus.WAITING_HUMAN)
        self.assertIsNotNone(review.task)
        assert review.task is not None
        self.assertEqual(review.task.task_type, "human-review")
        self.assertEqual(review.task.assigned_role, "reviewer")
        self.assertEqual([event.event_type for event in review.events], ["node.entered", "task.created"])

        completed = complete_current(workflow, review.case, next_sequence=5)
        self.assertEqual(completed.case.status, CaseStatus.COMPLETED)
        self.assertIsNone(completed.case.current_node)
        self.assertEqual(
            [event.event_type for event in completed.events],
            ["task.completed", "node.entered", "case.completed"],
        )
        self.assertEqual(completed.events[0].task_id, review.task.identifier)

    def test_approval_creates_approval_task(self) -> None:
        workflow = linear_workflow(middle_kind=NodeType.APPROVAL)
        started = start_case(workflow, "CA-ABCDEFGH", "revision-1")
        review = complete_current(workflow, started.case, next_sequence=3)
        assert review.task is not None
        self.assertEqual(review.task.task_type, "approval")

    def test_agent_is_runtime_work_not_a_human_task(self) -> None:
        workflow = linear_workflow(middle_kind=NodeType.AGENT)
        started = start_case(workflow, "CA-AGENT-1234", "revision-1")
        agent = complete_current(workflow, started.case, next_sequence=3)
        self.assertEqual(agent.case.current_node, "review")
        self.assertEqual(agent.case.status, CaseStatus.RUNNING)
        self.assertIsNone(agent.task)

    def test_condition_requires_explicit_route_when_ambiguous(self) -> None:
        workflow = Workflow(
            "generic.route",
            "1.0.0",
            "choice",
            (
                Node("choice", NodeType.CONDITION),
                Node("yes_end", NodeType.END),
                Node("no_end", NodeType.END),
            ),
            (
                Transition("choice", "yes_end", "yes"),
                Transition("choice", "no_end", "no"),
            ),
        )
        case = start_case(workflow, "CA-ROUTE-1234", "revision-1").case
        with self.assertRaisesRegex(ValueError, "route is required"):
            complete_current(workflow, case, next_sequence=3)
        with self.assertRaisesRegex(ValueError, "exactly one"):
            complete_current(workflow, case, next_sequence=3, route="missing")
        completed = complete_current(workflow, case, next_sequence=3, route="yes")
        self.assertEqual(completed.case.status, CaseStatus.COMPLETED)

    def test_start_at_human_or_end_settles_immediately(self) -> None:
        human = Workflow(
            "generic.human",
            "1.0.0",
            "review",
            (Node("review", NodeType.HUMAN_REVIEW, assigned_role="reviewer"), Node("done", NodeType.END)),
            (Transition("review", "done"),),
        )
        started = start_case(human, "CA-HUMAN-1234", "r1")
        self.assertEqual(started.case.status, CaseStatus.WAITING_HUMAN)
        self.assertEqual(started.events[-1].event_type, "task.created")

        terminal = Workflow(
            "generic.terminal",
            "1.0.0",
            "done",
            (Node("done", NodeType.END),),
            (),
        )
        ended = start_case(terminal, "CA-ENDED-1234", "r1")
        self.assertEqual(ended.case.status, CaseStatus.COMPLETED)
        self.assertEqual(ended.events[-1].event_type, "case.completed")

    def test_definition_rejects_invalid_identity_and_graphs(self) -> None:
        good = linear_workflow()
        invalid = [
            replace(good, identifier=""),
            replace(good, version=""),
            replace(good, entry_node=""),
            replace(good, nodes=()),
            replace(good, nodes=(Node("", NodeType.INPUT), Node("done", NodeType.END)),
                    transitions=(Transition("", "done"),), entry_node="done"),
            replace(good, nodes=(Node("intake", NodeType.INPUT), Node("intake", NodeType.END))),
            replace(good, entry_node="missing"),
            replace(good, nodes=(Node("intake", NodeType.INPUT),),
                    transitions=(Transition("intake", "intake"),)),
        ]
        for workflow in invalid:
            with self.subTest(workflow=workflow):
                with self.assertRaises(ValueError):
                    validate_workflow(workflow)

    def test_definition_rejects_unsupported_or_unsafe_nodes(self) -> None:
        good = linear_workflow()
        unsupported = replace(
            good,
            nodes=(Node("intake", cast(NodeType, "unknown")), Node("done", NodeType.END)),
            transitions=(Transition("intake", "done"),),
        )
        no_role = linear_workflow()
        no_role = replace(
            no_role,
            nodes=(Node("intake", NodeType.INPUT), Node("review", NodeType.HUMAN_REVIEW), Node("done", NodeType.END)),
        )
        unsafe_agent_review = linear_workflow(middle_kind=NodeType.AGENT)
        unsafe_agent_review = replace(
            unsafe_agent_review,
            nodes=tuple(
                replace(node, human_review_required=False) if node.identifier == "review" else node
                for node in unsafe_agent_review.nodes
            ),
        )
        unsafe_agent_fallback = linear_workflow(middle_kind=NodeType.AGENT)
        unsafe_agent_fallback = replace(
            unsafe_agent_fallback,
            nodes=tuple(
                replace(node, failure_mode="unsafe") if node.identifier == "review" else node
                for node in unsafe_agent_fallback.nodes
            ),
        )
        for workflow in [unsupported, no_role, unsafe_agent_review, unsafe_agent_fallback]:
            with self.assertRaises(ValueError):
                validate_workflow(workflow)

    def test_definition_rejects_bad_transitions_and_reachability(self) -> None:
        good = linear_workflow()
        bad_reference_source = replace(
            good,
            transitions=(Transition("missing", "review"), Transition("review", "done")),
        )
        bad_reference_target = replace(
            good,
            transitions=(Transition("intake", "missing"), Transition("review", "done")),
        )
        self_loop = replace(
            good,
            transitions=(
                Transition("intake", "intake"),
                Transition("intake", "review"),
                Transition("review", "done"),
            ),
        )
        end_outgoing = replace(
            good,
            transitions=(
                Transition("intake", "review"),
                Transition("review", "done"),
                Transition("done", "review"),
            ),
        )
        missing_outgoing = replace(good, transitions=(Transition("intake", "review"),))
        unreachable = Workflow(
            "generic.unreachable",
            "1.0.0",
            "intake",
            (
                Node("intake", NodeType.INPUT),
                Node("done", NodeType.END),
                Node("orphan", NodeType.END),
            ),
            (Transition("intake", "done"),),
        )
        for workflow in [
            bad_reference_source,
            bad_reference_target,
            self_loop,
            end_outgoing,
            missing_outgoing,
            unreachable,
        ]:
            with self.assertRaises(ValueError):
                validate_workflow(workflow)

    def test_case_and_event_identity_guards(self) -> None:
        workflow = linear_workflow()
        with self.assertRaisesRegex(ValueError, "Case ID"):
            start_case(workflow, "", "r1")
        with self.assertRaisesRegex(ValueError, "Case ID"):
            start_case(workflow, "CA-12345678", "")
        self.assertEqual(_stable_id("TA", "a", "b"), _stable_id("TA", "a", "b"))
        with self.assertRaisesRegex(ValueError, "cannot be empty"):
            _stable_id("TA", "", "b")
        with self.assertRaisesRegex(ValueError, "positive"):
            _event("CA-12345678", 0, "case.created")

    def test_case_cannot_cross_versions_or_advance_after_completion(self) -> None:
        workflow = linear_workflow()
        case = start_case(workflow, "CA-STATE-1234", "r1").case
        with self.assertRaisesRegex(ValueError, "does not match"):
            complete_current(replace(workflow, version="2.0.0"), case, next_sequence=3)
        with self.assertRaisesRegex(ValueError, "positive"):
            complete_current(workflow, case, next_sequence=0)

        completed = Case(
            case.identifier,
            workflow.identifier,
            workflow.version,
            case.revision,
            None,
            CaseStatus.COMPLETED,
        )
        with self.assertRaisesRegex(ValueError, "cannot advance"):
            complete_current(workflow, completed, next_sequence=3)

    def test_invalid_current_node_and_manual_end_state_fail_closed(self) -> None:
        workflow = linear_workflow()
        base = start_case(workflow, "CA-NODE-1234", "r1").case
        outside = replace(base, current_node="outside")
        with self.assertRaisesRegex(ValueError, "outside"):
            complete_current(workflow, outside, next_sequence=3)

        manual_end = replace(base, current_node="done")
        with self.assertRaisesRegex(ValueError, "End nodes"):
            complete_current(workflow, manual_end, next_sequence=3)


if __name__ == "__main__":
    unittest.main()

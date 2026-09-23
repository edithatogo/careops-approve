"""Small runtime reference for generic CareOps workflow orchestration.

This module does not execute agents, call APIs, send messages, resolve identities
or make decisions. Hosting adapters remain responsible for authorization,
durability, retries, secrets, queues, connector execution and audit persistence.
"""
from dataclasses import dataclass, replace
from enum import StrEnum
from hashlib import sha256


class NodeType(StrEnum):
    INPUT = "input"
    DETERMINISTIC_CHECK = "deterministic_check"
    AGENT = "agent"
    HUMAN_REVIEW = "human_review"
    APPROVAL = "approval"
    CONDITION = "condition"
    PARALLEL = "parallel"
    JOIN = "join"
    WAIT = "wait"
    NOTIFICATION = "notification"
    API_CALL = "api_call"
    HANDOFF = "handoff"
    END = "end"


class CaseStatus(StrEnum):
    RUNNING = "running"
    WAITING_HUMAN = "waiting-human"
    COMPLETED = "completed"


@dataclass(frozen=True)
class Node:
    identifier: str
    kind: NodeType
    assigned_role: str = ""
    human_review_required: bool = False
    failure_mode: str = ""


@dataclass(frozen=True)
class Transition:
    source: str
    target: str
    label: str = ""


@dataclass(frozen=True)
class Workflow:
    identifier: str
    version: str
    entry_node: str
    nodes: tuple[Node, ...]
    transitions: tuple[Transition, ...]


@dataclass(frozen=True)
class Case:
    identifier: str
    workflow_id: str
    workflow_version: str
    revision: str
    current_node: str | None
    status: CaseStatus


@dataclass(frozen=True)
class Task:
    identifier: str
    case_id: str
    node_id: str
    task_type: str
    assigned_role: str
    status: str = "open"


@dataclass(frozen=True)
class Event:
    identifier: str
    case_id: str
    sequence: int
    event_type: str
    node_id: str | None = None
    task_id: str | None = None


@dataclass(frozen=True)
class Progress:
    case: Case
    task: Task | None
    events: tuple[Event, ...]


def _stable_id(prefix: str, *parts: str) -> str:
    if any(not part.strip() for part in parts):
        raise ValueError("Stable identifier inputs cannot be empty")
    digest = sha256("\x1f".join(parts).encode()).hexdigest().upper()[:24]
    return f"{prefix}-{digest}"


def _event(
    case_id: str,
    sequence: int,
    event_type: str,
    *,
    node_id: str | None = None,
    task_id: str | None = None,
) -> Event:
    if sequence < 1:
        raise ValueError("Event sequence must be positive")
    identifier = _stable_id("EV", case_id, str(sequence), event_type)
    return Event(identifier, case_id, sequence, event_type, node_id, task_id)


def validate_workflow(workflow: Workflow) -> None:
    """Fail closed on malformed graphs or unsafe agent/human nodes."""
    if not workflow.identifier.strip() or not workflow.version.strip() or not workflow.entry_node.strip():
        raise ValueError("Workflow identity, version and entry node are required")
    if not workflow.nodes:
        raise ValueError("Workflow requires at least one node")

    identifiers = [node.identifier for node in workflow.nodes]
    if any(not identifier.strip() for identifier in identifiers):
        raise ValueError("Node identifiers cannot be empty")
    if len(identifiers) != len(set(identifiers)):
        raise ValueError("Node identifiers must be unique")
    if workflow.entry_node not in identifiers:
        raise ValueError("Entry node must exist")
    if not any(node.kind == NodeType.END for node in workflow.nodes):
        raise ValueError("Workflow requires at least one end node")

    by_id = {node.identifier: node for node in workflow.nodes}
    for node in workflow.nodes:
        if not isinstance(node.kind, NodeType):
            raise ValueError("Unsupported node type")
        if node.kind in {NodeType.HUMAN_REVIEW, NodeType.APPROVAL} and not node.assigned_role.strip():
            raise ValueError("Human nodes require an assigned role")
        if node.kind == NodeType.AGENT and (
            not node.human_review_required or node.failure_mode != "ordinary-human-path"
        ):
            raise ValueError("Agent nodes must preserve mandatory human review and fallback")

    outgoing: dict[str, list[str]] = {identifier: [] for identifier in identifiers}
    for transition in workflow.transitions:
        if transition.source not in by_id or transition.target not in by_id:
            raise ValueError("Transitions must reference existing nodes")
        if transition.source == transition.target:
            raise ValueError("Self loops are not allowed")
        outgoing[transition.source].append(transition.target)

    for node in workflow.nodes:
        if node.kind == NodeType.END and outgoing[node.identifier]:
            raise ValueError("End nodes cannot have outgoing transitions")
        if node.kind != NodeType.END and not outgoing[node.identifier]:
            raise ValueError("Non-end nodes require an outgoing transition")

    seen: set[str] = set()
    stack = [workflow.entry_node]
    while stack:
        current = stack.pop()
        if current in seen:
            continue
        seen.add(current)
        stack.extend(outgoing[current])
    if seen != set(identifiers):
        raise ValueError("Every node must be reachable from the entry node")


def _node(workflow: Workflow, identifier: str) -> Node:
    for node in workflow.nodes:
        if node.identifier == identifier:
            return node
    raise ValueError("Case references a node outside the workflow")


def _outgoing(workflow: Workflow, identifier: str) -> tuple[Transition, ...]:
    return tuple(edge for edge in workflow.transitions if edge.source == identifier)


def _settle(case: Case, node: Node, sequence: int) -> Progress:
    events: list[Event] = []
    if node.kind == NodeType.END:
        completed = replace(case, current_node=None, status=CaseStatus.COMPLETED)
        events.append(_event(case.identifier, sequence, "case.completed", node_id=node.identifier))
        return Progress(completed, None, tuple(events))
    if node.kind in {NodeType.HUMAN_REVIEW, NodeType.APPROVAL}:
        task_type = "human-review" if node.kind == NodeType.HUMAN_REVIEW else "approval"
        task_id = _stable_id("TA", case.identifier, case.revision, node.identifier)
        task = Task(task_id, case.identifier, node.identifier, task_type, node.assigned_role)
        waiting = replace(case, status=CaseStatus.WAITING_HUMAN)
        events.append(
            _event(
                case.identifier,
                sequence,
                "task.created",
                node_id=node.identifier,
                task_id=task_id,
            )
        )
        return Progress(waiting, task, tuple(events))
    return Progress(case, None, ())


def start_case(workflow: Workflow, case_id: str, revision: str) -> Progress:
    """Create a case at the immutable workflow version and settle its entry node."""
    validate_workflow(workflow)
    if not case_id.strip() or not revision.strip():
        raise ValueError("Case ID and revision are required")
    case = Case(
        case_id,
        workflow.identifier,
        workflow.version,
        revision,
        workflow.entry_node,
        CaseStatus.RUNNING,
    )
    entered = _event(case_id, 1, "case.created", node_id=workflow.entry_node)
    node_event = _event(case_id, 2, "node.entered", node_id=workflow.entry_node)
    settled = _settle(case, _node(workflow, workflow.entry_node), 3)
    return Progress(case=settled.case, task=settled.task, events=(entered, node_event, *settled.events))


def complete_current(
    workflow: Workflow,
    case: Case,
    *,
    next_sequence: int,
    route: str = "",
) -> Progress:
    """Advance an explicitly completed node; this does not execute the node itself."""
    validate_workflow(workflow)
    if (case.workflow_id, case.workflow_version) != (workflow.identifier, workflow.version):
        raise ValueError("Case workflow version does not match")
    if case.status == CaseStatus.COMPLETED or case.current_node is None:
        raise ValueError("Completed cases cannot advance")
    if next_sequence < 1:
        raise ValueError("Next event sequence must be positive")

    current = _node(workflow, case.current_node)
    if current.kind == NodeType.END:
        raise ValueError("End nodes cannot be completed through node advancement")

    edges = _outgoing(workflow, current.identifier)
    if route:
        matches = tuple(edge for edge in edges if edge.label == route)
        if len(matches) != 1:
            raise ValueError("Route must select exactly one transition")
        edge = matches[0]
    else:
        if len(edges) != 1:
            raise ValueError("A route is required when multiple transitions are available")
        edge = edges[0]

    events: list[Event] = []
    sequence = next_sequence
    if case.status == CaseStatus.WAITING_HUMAN:
        task_id = _stable_id("TA", case.identifier, case.revision, current.identifier)
        events.append(
            _event(
                case.identifier,
                sequence,
                "task.completed",
                node_id=current.identifier,
                task_id=task_id,
            )
        )
        sequence += 1

    advanced = replace(case, current_node=edge.target, status=CaseStatus.RUNNING)
    events.append(_event(case.identifier, sequence, "node.entered", node_id=edge.target))
    sequence += 1
    settled = _settle(advanced, _node(workflow, edge.target), sequence)
    return Progress(settled.case, settled.task, (*events, *settled.events))

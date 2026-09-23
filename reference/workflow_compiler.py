"""Compile source-neutral workflow definitions into the bounded runtime model.

Schema validation belongs at the API/editor boundary. This module provides the
second, semantic gate: only supported node semantics are translated into runtime
objects. Reserved nodes remain design-time data until their adapters are
implemented and tested.
"""
from collections.abc import Mapping, Sequence
from hashlib import sha256
from json import dumps
from typing import cast

from reference.workflow_runtime import Node, NodeType, Transition, Workflow, validate_workflow

DEFAULT_SUPPORTED_NODE_TYPES = frozenset(
    {
        NodeType.INPUT,
        NodeType.DETERMINISTIC_CHECK,
        NodeType.AGENT,
        NodeType.HUMAN_REVIEW,
        NodeType.APPROVAL,
        NodeType.CONDITION,
        NodeType.END,
    }
)


def _mapping(value: object, field: str) -> Mapping[str, object]:
    if not isinstance(value, Mapping) or any(not isinstance(key, str) for key in value):
        raise ValueError(f"{field} must be an object with string keys")
    return cast(Mapping[str, object], value)


def _sequence(value: object, field: str) -> Sequence[object]:
    if isinstance(value, (str, bytes)) or not isinstance(value, Sequence):
        raise ValueError(f"{field} must be an array")
    return cast(Sequence[object], value)


def _string(value: object, field: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{field} must be a nonempty string")
    return value


def _boolean(value: object, field: str) -> bool:
    if not isinstance(value, bool):
        raise ValueError(f"{field} must be a boolean")
    return value


def _node(
    value: object,
    supported_node_types: frozenset[NodeType],
) -> Node:
    item = _mapping(value, "node")
    identifier = _string(item.get("id"), "node.id")
    kind_value = _string(item.get("type"), f"node[{identifier}].type")
    try:
        kind = NodeType(kind_value)
    except ValueError as exc:
        raise ValueError(f"node[{identifier}].type is unsupported") from exc
    if kind not in supported_node_types:
        raise ValueError(f"node type '{kind.value}' is reserved and cannot be compiled")

    config = _mapping(item.get("config"), f"node[{identifier}].config")
    assigned_role = ""
    human_review_required = False
    failure_mode = ""
    if kind in {NodeType.HUMAN_REVIEW, NodeType.APPROVAL}:
        assigned_role = _string(config.get("assignedRole"), f"node[{identifier}].assignedRole")
    if kind == NodeType.AGENT:
        human_review_required = _boolean(
            config.get("humanReviewRequired"),
            f"node[{identifier}].humanReviewRequired",
        )
        failure_mode = _string(config.get("failureMode"), f"node[{identifier}].failureMode")

    return Node(
        identifier=identifier,
        kind=kind,
        assigned_role=assigned_role,
        human_review_required=human_review_required,
        failure_mode=failure_mode,
    )


def _transition(value: object) -> Transition:
    item = _mapping(value, "transition")
    source = _string(item.get("from"), "transition.from")
    target = _string(item.get("to"), "transition.to")
    label_value = item.get("label", "")
    if not isinstance(label_value, str):
        raise ValueError("transition.label must be a string")
    return Transition(source, target, label_value)


def compile_workflow(
    definition: Mapping[str, object],
    *,
    supported_node_types: frozenset[NodeType] = DEFAULT_SUPPORTED_NODE_TYPES,
) -> Workflow:
    """Compile a schema-validated definition and apply runtime semantic checks."""
    if not supported_node_types:
        raise ValueError("At least one supported node type is required")
    identifier = _string(definition.get("workflowId"), "workflowId")
    version = _string(definition.get("version"), "version")
    entry = _string(definition.get("entryNodeId"), "entryNodeId")
    nodes = tuple(
        _node(value, supported_node_types)
        for value in _sequence(definition.get("nodes"), "nodes")
    )
    transitions = tuple(
        _transition(value)
        for value in _sequence(definition.get("transitions"), "transitions")
    )
    workflow = Workflow(identifier, version, entry, nodes, transitions)
    validate_workflow(workflow)
    return workflow


def compile_active_workflow(
    definition: Mapping[str, object],
    *,
    supported_node_types: frozenset[NodeType] = DEFAULT_SUPPORTED_NODE_TYPES,
) -> Workflow:
    """Compile only an explicitly active workflow for case creation."""
    if definition.get("status") != "active":
        raise ValueError("Only an active workflow version may create new cases")
    return compile_workflow(definition, supported_node_types=supported_node_types)


def definition_hash(definition: Mapping[str, object]) -> str:
    """Return the canonical hash used to bind a publication request to a draft."""
    try:
        canonical = dumps(
            definition,
            sort_keys=True,
            separators=(",", ":"),
            ensure_ascii=False,
            allow_nan=False,
        )
    except (TypeError, ValueError) as exc:
        raise ValueError("Workflow definition must be JSON serializable") from exc
    return f"sha256:{sha256(canonical.encode()).hexdigest()}"

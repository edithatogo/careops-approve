"""Compile source-neutral workflow definitions into the bounded runtime model.

Schema validation belongs at the API/editor boundary. This module provides the
second, semantic gate: only supported node semantics are translated into runtime
objects. Reserved nodes remain design-time data until their adapters are
implemented and tested.
"""
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
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


@dataclass(frozen=True)
class TrustedBindings:
    """Deployment-approved authority and agent references."""

    roles: frozenset[str]
    agents: frozenset[tuple[str, str]]

    def __post_init__(self) -> None:
        if any(not role.strip() for role in self.roles):
            raise ValueError("Trusted role keys cannot be empty")
        if any(not agent_id.strip() or not version.strip() for agent_id, version in self.agents):
            raise ValueError("Trusted agent identity and version cannot be empty")

    def to_contract(self) -> dict[str, object]:
        """Expose reference keys only; deployment identities remain private."""
        return {
            "schemaVersion": 1,
            "roles": [{"roleKey": role} for role in sorted(self.roles)],
            "agents": [
                {"agentId": agent_id, "version": version}
                for agent_id, version in sorted(self.agents)
            ],
        }


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
    trusted_bindings: TrustedBindings | None,
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
        if trusted_bindings is not None and assigned_role not in trusted_bindings.roles:
            raise ValueError(f"node[{identifier}].assignedRole is not a trusted role")
    if kind == NodeType.AGENT:
        agent_id = _string(config.get("agentId"), f"node[{identifier}].agentId")
        agent_version = _string(config.get("agentVersion"), f"node[{identifier}].agentVersion")
        if (
            trusted_bindings is not None
            and (agent_id, agent_version) not in trusted_bindings.agents
        ):
            raise ValueError(f"node[{identifier}] references an untrusted agent version")
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


def _compile_workflow(
    definition: Mapping[str, object],
    *,
    supported_node_types: frozenset[NodeType],
    trusted_bindings: TrustedBindings | None,
) -> Workflow:
    if not supported_node_types:
        raise ValueError("At least one supported node type is required")
    identifier = _string(definition.get("workflowId"), "workflowId")
    version = _string(definition.get("version"), "version")
    entry = _string(definition.get("entryNodeId"), "entryNodeId")
    nodes = tuple(
        _node(value, supported_node_types, trusted_bindings)
        for value in _sequence(definition.get("nodes"), "nodes")
    )
    transitions = tuple(
        _transition(value)
        for value in _sequence(definition.get("transitions"), "transitions")
    )
    workflow = Workflow(identifier, version, entry, nodes, transitions)
    validate_workflow(workflow)
    return workflow


def compile_workflow(
    definition: Mapping[str, object],
    *,
    supported_node_types: frozenset[NodeType] = DEFAULT_SUPPORTED_NODE_TYPES,
) -> Workflow:
    """Compile structural semantics without deployment authority binding."""
    return _compile_workflow(
        definition,
        supported_node_types=supported_node_types,
        trusted_bindings=None,
    )


def compile_trusted_workflow(
    definition: Mapping[str, object],
    trusted_bindings: TrustedBindings,
    *,
    supported_node_types: frozenset[NodeType] = DEFAULT_SUPPORTED_NODE_TYPES,
) -> Workflow:
    """Compile with deployment-approved role and agent references."""
    return _compile_workflow(
        definition,
        supported_node_types=supported_node_types,
        trusted_bindings=trusted_bindings,
    )


def compile_active_workflow(
    definition: Mapping[str, object],
    *,
    supported_node_types: frozenset[NodeType] = DEFAULT_SUPPORTED_NODE_TYPES,
) -> Workflow:
    """Compile only an explicitly active workflow without deployment binding."""
    if definition.get("status") != "active":
        raise ValueError("Only an active workflow version may create new cases")
    return compile_workflow(definition, supported_node_types=supported_node_types)


def compile_trusted_active_workflow(
    definition: Mapping[str, object],
    trusted_bindings: TrustedBindings,
    *,
    supported_node_types: frozenset[NodeType] = DEFAULT_SUPPORTED_NODE_TYPES,
) -> Workflow:
    """Compile an active workflow with trusted authority and agent binding."""
    if definition.get("status") != "active":
        raise ValueError("Only an active workflow version may create new cases")
    return compile_trusted_workflow(
        definition,
        trusted_bindings,
        supported_node_types=supported_node_types,
    )


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

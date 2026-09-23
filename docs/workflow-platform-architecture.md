# Configurable workflow platform architecture

## Purpose

CareOps Approve treats credentialing, equipment requests, research governance
and other approval processes as workflow packs over one stable orchestration
core. The core must not encode organisation-specific authority or clinical
policy.

The workflow definition in `contracts/workflow-definition.schema.json` is the
source-neutral contract that future GUI, API, Power Platform and other adapters
should produce or consume.

## Design principles

1. **Workflow as data.** Ordinary process changes alter a versioned definition
   rather than application code.
2. **Reusable node types.** Input, deterministic checks, approved agents, human
   review, approvals, branching, parallel work, waits, notifications, API calls,
   handoffs and terminal states are composable primitives.
3. **Authority is separate from orchestration.** A workflow may reference roles
   and authority profiles, but cannot invent or alter delegations.
4. **Agents are registered capabilities.** Workflow authors choose approved,
   versioned agents from a registry. They do not create unrestricted executable
   agents inside a workflow.
5. **Safe failure.** AI or integration failure preserves a defined fallback path
   and cannot silently bypass a mandatory control.
6. **Immutable publication.** Draft workflow versions are validated and approved
   before activation. Running cases retain their starting version unless an
   explicit, auditable migration occurs.
7. **API first, UI optional.** Teams and Power Apps may be primary interfaces,
   but orchestration contracts remain usable by other approved applications.
8. **No shared database assumption.** Modules integrate through versioned
   contracts, stable identifiers and events.

## Configuration layers

| Layer | Typical owner | Examples |
|---|---|---|
| Form/process content | Process owner | labels, required fields, notifications |
| Workflow | Workflow administrator | stages, branches, SLAs, routing |
| Agent registry | Agent administrator | approved agent versions and capabilities |
| Authority | Governance owner | roles, delegations, decision gates |
| Integration | Integration administrator | approved APIs and connection bindings |
| Runtime/security | Platform administrator | environments, identity, DLP, secrets |
| Extension SDK | Developer | genuinely new node or connector types |

A GUI should expose only controls appropriate to the user's configuration role.

## Publication lifecycle

Draft -> Validate -> Test -> Governance approval -> Publish -> Active -> Retire.

Validation should reject duplicate node identifiers, missing entry nodes,
transitions to missing nodes, unknown node or agent types, unapproved authority
or integration references, autonomous adverse-action agents, unsafe unbounded
cycles, and sensitive workflows without an approved data-handling profile.

## Runtime boundary

The first implementation may use Power Automate and Microsoft 365. The workflow
contract deliberately does not require that runtime. An adapter is responsible
for durable case state, retries, queues, authorization, secrets, connection
bindings and delivery deduplication.

The runtime should emit stable case and task events so CareOps Process, CareOps
Decisions and approved external applications can integrate without sharing
operational tables.

## GUI objective

A future Workflow Studio should edit draft definitions, validate them, simulate
synthetic cases, show a visual graph, and submit a version for governance
approval. The GUI is a controlled editor for the contract, not an alternative
source of business logic.

## API objective

A future API layer should support, subject to authorization, creating and
inspecting cases, submitting evidence or corrections, listing and completing
assigned human tasks, retrieving allowed workflow versions, publishing approved
event subscriptions, and invoking approved external actions.

API contracts should be versioned separately from workflow definitions so the
orchestration model can evolve without breaking consuming applications.


## Workflow Studio contract

The first source-neutral editor metadata is defined by
`contracts/workflow-editor-catalog.schema.json` with an example catalogue in
`config/workflow-editor-catalog.example.json`. A user interface should render
controls from this catalogue rather than hard-code per-process forms.

The catalogue distinguishes ordinary configuration from authority, agent,
integration and platform-governed settings. Process owners cannot independently
change authority-bearing approval roles, agent identity is selected from the
approved agent registry, and integration nodes require an integration
administrator.

Node types may be listed as `reserved` before their runtime or adapter
semantics are implemented. Reserved nodes can be shown for roadmap/design
purposes but must not be publishable in an active workflow.

## Publication controls

Saving a draft does not change a live workflow. Publication uses the separate
`workflow-publication.schema.json` contract, binds the request to the SHA-256
hash of the exact definition, and requires passed validation/testing plus an
explicit running-case migration policy.

The API contract now separates:

- editing a draft workflow version;
- validating that draft;
- requesting governed publication or retirement; and
- reading the permitted Workflow Studio node catalogue.

Until bounded-loop semantics are implemented, the reference runtime rejects
cycles. This is deliberate fail-closed behaviour rather than silently allowing
a GUI-created workflow to loop indefinitely.


## Semantic compilation

A schema-valid draft is not automatically executable. The reference compiler in
`reference/workflow_compiler.py` provides a second semantic gate between a
Workflow Studio/API definition and the runtime model.

The compiler:

- accepts only currently supported node semantics;
- blocks catalogue entries that are still reserved;
- converts human review and approval roles into runtime assignments;
- preserves mandatory agent human-review/fallback settings;
- delegates graph safety, reachability and cycle checks to the runtime validator;
- can require an explicitly `active` workflow before creating new cases; and
- calculates a canonical SHA-256 definition hash for publication binding.

This separates three states that should remain distinct: **well-formed JSON**,
**semantically deployable workflow**, and **governance-approved active version**.

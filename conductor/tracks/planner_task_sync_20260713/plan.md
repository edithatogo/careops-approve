# Implementation plan

## Phase 1: Source contract

- [x] Task: Add Planner configuration, flow contract and operator documentation [local]
    - [x] Define basic-plan, standard-connector and no-email constraints.
    - [x] Define task idempotency, state mapping and sensitive-content exclusions.
- [x] Task: Add executable Planner contract validation [local]
    - [x] Create `scripts/Test-PlannerSync.ps1`.
    - [x] Add the test to `scripts/Test-Repository.ps1` and harness coverage.
- [ ] Task: Conductor - User Manual Verification 'Source contract' (Protocol in workflow.md)

## Phase 2: Plan and flow binding

- [~] Task: Select or create the approved Planner basic plan
    - [ ] Confirm plan membership includes only authorised workflow participants.
    - [ ] Record plan and bucket identifiers in tenant configuration, not Git.
- [ ] Task: Add Planner actions to the live solution-aware flow
    - [ ] Bind the owner-managed Planner connection reference.
    - [ ] Persist Planner task ID and last-sync fields in the approved state store.
- [ ] Task: Conductor - User Manual Verification 'Plan and flow binding' (Protocol in workflow.md)

## Phase 3: Pilot and reconciliation

- [ ] Task: Execute create, replay, update, decision and connector-failure scenarios
    - [ ] Confirm one task per request and no outbound email.
    - [ ] Confirm Planner edits cannot alter approval decisions.
- [ ] Task: Record sanitized evidence and enable the tenant configuration
- [ ] Task: Conductor - User Manual Verification 'Pilot and reconciliation' (Protocol in workflow.md)


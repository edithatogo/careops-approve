# Implementation plan

## Phase 1: Authenticated inventory

- [x] Task: Establish delegated PAC/maker authentication
    - [x] Confirm the target environment and permitted solution scope.
    - [x] Capture only sanitized authentication and inventory evidence.
- [x] Task: Authenticate and exercise the PACX fork for solution-aware flow inventory
    - [x] Build `edithatogo/pacx` locally for the available .NET 10 SDK.
    - [x] Authenticate PACX and query the managed operational solution's workflow records.
    - [x] Record the management-plane token limitation without storing credentials.
- [~] Task: Export and map live flows
    - [x] Inventory relevant names, states, owner boundary and contract mappings.
    - [x] Record the one maker-surface corruption warning and the managed-solution export boundary.
    - [ ] Obtain source-readable definitions for the intended CareOps flows.
    - [ ] Identify duplicates, invalid parameters and missing bindings.
- [ ] Task: Conductor - User Manual Verification 'Authenticated inventory' (Protocol in workflow.md)

## Phase 2: Reconciliation and release

- [ ] Task: Reconcile source and live definitions
    - [ ] Repair authorised components and preserve rollback artifacts.
    - [ ] Validate pack, checker and import settings.
- [ ] Task: Execute the live pilot matrix and record sanitized evidence
- [ ] Task: Conductor - User Manual Verification 'Reconciliation and release' (Protocol in workflow.md)

# Project Workflow

## Guiding Principles

1. The active track plan is the source of truth.
2. Changes to the technology stack are documented before implementation.
3. Write validation checks before creating or changing deployable artifacts.
4. Keep tenant-specific configuration outside source control.
5. Treat governance and environment validation as release gates.
6. Commit after coherent tasks and checkpoint every completed phase.

## Standard Task Workflow

1. Select the next task and mark it `[~]` in `plan.md`.
2. Define or update the automated validation that demonstrates the expected result.
3. Run the validation and confirm it fails when the capability is absent.
4. Implement the minimum artifact or documentation change needed.
5. Run static checks and relevant tests until they pass.
6. Perform tenant validation when the task depends on Microsoft 365 behaviour.
7. Update operational documentation and record known limitations.
8. Commit the implementation, then mark the task `[x]` with its short commit SHA.

## Phase Completion Verification and Checkpointing Protocol

At the end of every phase:

1. Run all automated checks relevant to the phase.
2. Review changed files for secrets, tenant identifiers, and personal data.
3. Present a concrete manual verification procedure and expected results.
4. Obtain explicit user confirmation for tenant-dependent behaviour.
5. Create a checkpoint commit and record its short SHA in the phase heading.

## Quality Gates

- No secrets, connection credentials, or fixed personal identifiers are committed.
- Configuration changes are restricted to authorised owners and are auditable.
- In-flight requests are not silently reassigned by configuration changes.
- Success, rejection, cancellation, timeout, and configuration failure paths are tested.
- Documentation distinguishes workflow evidence from formal delegated authority.

## Definition of Done

A task is complete when its validation passes, documentation is current, tenant
behaviour has been manually verified where required, and the corresponding commit
is recorded in the track plan.

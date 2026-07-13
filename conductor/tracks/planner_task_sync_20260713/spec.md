# Planner task synchronization

## Objective

Create and maintain one sanitized Planner task per CareOps approval so the owner,
EAs and authorised collaborators can track pending work and follow-up.

## Inputs and outputs

- Input: persisted request ID, safe title, template, status, due date and authorised link.
- Output: Planner task ID, last synchronized state/time and exception status.
- Source files: `config/planner-sync.example.json`,
  `flows/planner-task-sync.contract.json`, `docs/planner-integration.md`.

## Functional requirements

- Use the standard Planner connector and a basic plan.
- Create a task only after the request ID exists and only when no task ID is stored.
- Map pending, follow-up, completed and exception states to configured buckets.
- Update task details idempotently and suppress email actions.
- Keep Planner subordinate to native Teams Approvals.

## Acceptance criteria

- `scripts/Test-PlannerSync.ps1` and the repository harness pass.
- Create/replay/update/decision/failure scenarios create no duplicate tasks.
- Planner completion cannot alter the approval outcome.
- A live pilot records sanitized task and flow-run evidence.

## Stop conditions

Stop at the tenant gate if no approved basic plan, Planner connection, maker access
or safe plan membership exists. Do not create a Graph app or request admin consent.


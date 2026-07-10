# Product Guidelines

## Experience Principles

1. Keep submission and decision-making understandable without training.
2. Show the requester what was submitted, who received it, and its current state.
3. Make Approve and Reject explicit; never infer approval from silence.
4. Require comments on rejection and permit comments on approval.
5. Use plain language and avoid implementation terminology in user-facing text.

## Governance Principles

1. Use named Microsoft Entra identities; do not use shared credentials.
2. Restrict approver configuration changes to authorised workflow owners.
3. Record configuration changes and approval events where platform capability allows.
4. Apply configuration changes prospectively; never silently reassign in-flight work.
5. Use standard Microsoft 365 connectors unless a documented design change is approved.
6. Store links to source records where possible instead of duplicating sensitive data.

## Accessibility and Support

- The workflow must work in Teams desktop, web, and mobile approval surfaces.
- Labels and outcomes must not rely on colour alone.
- Failure messages must state what happened and what the user can do next.
- The owner documentation must include recovery, reassignment, and support steps.

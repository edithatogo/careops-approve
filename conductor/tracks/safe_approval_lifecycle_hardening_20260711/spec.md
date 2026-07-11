# Specification

Harden the tenant-neutral approval contract with explicit timeout escalation, requester cancellation, restricted visibility, and idempotent audit behavior. This track must not add tenant identifiers, credentials, live connections, email notifications, or claims of live deployment.

## Acceptance criteria

- The blueprint models a 14-day timeout to the EDMS escalation approver.
- Escalation and requester acknowledgement suppress email notifications.
- Visibility is restricted to the workflow owner, requester, and assigned approver.
- Cancellation requires an authenticated requester identity and reason and preserves the first final outcome.
- Contract validation fails closed when any control is removed.

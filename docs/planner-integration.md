# Planner task projection

CareOps Approve can project each approval into a Microsoft Planner basic-plan task
for operational tracking. Planner is not an approval authority: completing, moving
or editing a Planner task cannot approve, reject, reassign or cancel the native
Teams approval.

## Lifecycle

1. Persist the CareOps request and immutable request ID.
2. Create one Planner task using that request ID as the idempotency key.
3. Store the Planner task ID on the authorised submission record.
4. Update bucket, due date, percentage and sanitized details as approval state changes.
5. Route connector failures to the owner-only exception queue without email.
6. Reconcile missing or duplicate task projections through the operational
   reconciliation track.

The default buckets are Awaiting decision, Approved follow-up, Completed and
Exceptions. Actual plan, group and bucket identifiers are tenant configuration and
must not be committed.

## Permission and connector boundary

- Use the Microsoft Planner standard connector and a basic plan.
- The workflow owner creates the Planner connection; the connection is not shared
  through source control.
- Plan membership controls who can see task metadata. Keep titles and descriptions
  sanitized and link to an authorised record rather than copying request content.
- Premium Planner features, Graph automation and organisation-wide task publishing
  are outside the current no-admin scope.

## Live activation gate

Select or create an approved basic plan, authorize the Planner connection, supply
the plan/bucket identifiers outside Git, and execute create/update/complete/failure
pilot scenarios. Until that evidence exists, the integration remains disabled.

Reference: https://learn.microsoft.com/en-au/connectors/planner/


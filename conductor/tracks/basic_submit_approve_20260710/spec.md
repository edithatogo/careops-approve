# Specification: Configurable Basic Submit and Approve Workflow

## Overview

Build a deliberately small Microsoft Teams and Power Automate workflow in which a
user submits an administrative request and a configured named approver approves or
rejects it. The workflow must support controlled changes to the approver roster
without editing flow logic.

## Roles

- **Requester:** creates and monitors a request.
- **Approver:** approves or rejects an assigned request.
- **Workflow owner:** manages the approver configuration and supports failed requests.
- **Executive assistant:** may hold any of the above roles when authorised.

No personal identity is hard-coded to a role. Initial role assignments are deployment
configuration.

## Functional Requirements

### Submission

1. A requester can submit a title, description, and optional supporting URL.
2. The workflow validates required fields before creating an approval.
3. Each accepted submission receives a unique request identifier and `Submitted` status.
4. The requester receives confirmation identifying the assigned approver.

### Approver configuration

1. Authorised workflow owners can add, replace, deactivate, and reorder named approvers.
2. The active configuration is stored separately from flow logic.
3. The MVP supports one active primary approver and an optional delegate or fallback.
4. Configuration changes affect only requests submitted after the change.
5. Every request records the approver resolved at submission time.
6. Invalid or empty configuration stops routing and produces an actionable owner alert.

### Decision

1. The assigned approver receives an Approve/Reject request in Microsoft Teams.
2. Rejection requires a comment; approval permits an optional comment.
3. The final record stores the outcome, comments, approver identity, and decision time.
4. The requester receives the final outcome.
5. Duplicate responses cannot create conflicting final outcomes.

### Audit and operation

1. Request, routing, and outcome records are retained according to tenant policy.
2. Owners can identify pending, approved, rejected, failed, and cancelled requests.
3. Operational documentation covers configuration changes, reassignment limitations,
   failed routing, cancellation, and support escalation.

## Non-Functional Requirements

- Use Microsoft 365 standard connectors only.
- Use named Microsoft Entra identities and least-privilege access.
- Do not store secrets or fixed personal identifiers in source control.
- Work through supported Teams approval surfaces on desktop, web, and mobile.
- Keep the interaction suitable for a two-person pilot while allowing later roster growth.
- Clearly state that technical approval does not create delegated organisational authority.
- Package all deployable components in a custom solution with connection references
  and environment variables suitable for automated ALM.
- Build and validate solution artifacts with Microsoft Power Platform GitHub Actions.
- Support governed promotion with Power Platform Pipelines when an approved host and
  target environments are available.
- Maintain GitHub.com and GitHub Enterprise copies without embedding enterprise
  credentials or endpoint secrets in the repository.
- Evaluate Microsoft Business Approvals Kit and preview capabilities against explicit
  adoption gates; do not make a preview feature mandatory for the MVP.

## Acceptance Criteria

1. A valid submission creates exactly one approval for the configured primary approver.
2. Approve and Reject both produce a stable final record and requester notification.
3. Rejection without a comment is prevented or returned for completion.
4. An authorised owner can change the primary approver without editing or redeploying the flow.
5. A changed approver receives new requests; existing requests retain their original assignee.
6. An unauthorised user cannot change the approver configuration.
7. Missing or invalid approver configuration does not silently lose a request.
8. Source validation finds no credentials, tenant-specific connection IDs, or hard-coded people.
9. CI can validate and pack the solution without interactive credentials.
10. Environment deployment is gated, uses a service principal or approved pipeline
    identity, and consumes protected configuration.
11. The repository documents and tests the procedure for publishing branches and tags
    to both GitHub.com and an approved GitHub Enterprise repository.
12. Every preview or frontier feature has a dated status, fallback, and adoption decision.

## Out of Scope

- Multi-stage, quorum, financial delegation, procurement, or clinical approval logic.
- Approval delegation based on organisational hierarchy or HR data.
- Retrospective reassignment of active approvals.
- Custom connectors, premium services, external users, or public submission endpoints.
- Replacing formal records-management, privacy, security, or delegation processes.

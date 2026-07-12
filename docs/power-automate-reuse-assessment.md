# Power Automate reuse assessment

The signed-in Power Automate personal environment and the workspace
superstructure were inspected on 2026-07-11. The folder superstructure contains
many historical solution and deployment directory names, but the non-CareOps
files available locally are empty OneDrive placeholders and cannot be treated
as source artifacts. The useful implementation evidence is therefore the live
flow structure plus the validated CareOps contracts.

## Live assets assessed

| Flow | Observed structure | Reuse decision |
| --- | --- | --- |
| Leader Rounding - Teams Escalation Approvals v2 | SharePoint trigger, classify escalation, create action item, Teams adaptive card, persist outcome | Adapt the SharePoint state and Teams presentation patterns; do not clone invalid parameters |
| Leader Rounding - Dynamic Roster Reallocation v2 | Scheduled roster/exception reads, leader candidate selection, readiness summary | Adapt for approver, fallback, urgent-delegate, and EDMS resolution |
| Leader Rounding - Weekly Collation | Recurrence, SharePoint roster/action reads, summary composition, Teams channel post | Adapt for an owner-only pending/escalated summary without email |
| Leader Rounding - Dual Calendar Sync and Delegate Invite | Roster/leader reads and delegate assignment resolution; definition reports invalid parameters | Adapt only the delegate-resolution design; exclude calendar creation |
| MSCG - M+M - Action Overdue Escalation | Flow list reports corrupted data | Exclude from reuse |

The existing TESL capture solution also contributes four safe patterns to the
CareOps intake boundary: idempotent message/reference keys, processed and
failed-extraction routing, sanitized flow telemetry, and an owner-only manual
correction queue. These are now represented in
`config/tesl-intake-controls.example.json` and the TESL BPMN/visual artefacts.

The Teams escalation v2 flow is off, has a flow-checker warning, and exposes
invalid SharePoint/Teams parameters. The earlier escalation flow is a draft with
an invalid SharePoint connection. Co-owner sharing is disabled in the personal
environment. These conditions make direct cloning unsafe.

## CareOps composition

CareOps will use native Teams Approvals as the decision system of record. The
existing adaptive-card pattern is reused only to present a Teams-only status or
action surface with outbound email disabled. SharePoint carries immutable
submission, decision, escalation, and delegation state. Roster resolution is
prospective: it selects the approver for a new request but never silently
reassigns an existing approval.

The weekly collation pattern is narrowed to an owner-only Teams summary of
pending, overdue, escalated, failed, and urgent-delegation records. It must not
post to a broad channel or send email.

The machine inventory remains empty, so no existing desktop-flow or intranet
gateway can be reused for the post-approval execution stage.

The existing Dataverse submission app remains a possible future correction and
reporting surface, but it is not made authoritative: native Teams Approvals
continues to own the decision, and no app-side correction can create or finalize
an approval without the normal human path.

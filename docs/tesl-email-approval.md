# TESL email to Teams approval

The repository does not currently contain a usable TESL BPMN or an accessible
tenant flow. The live Power Automate default environment was inspected on
2026-07-11: the signed-in account had two personal cloud flows, no TESL-named
flow, no shared TESL flow, and no TESL-named solution visible in that
environment. The local TESL source directories are present as OneDrive
placeholders, but the tracked TESL submission schema is empty.

This repository therefore provides a tenant-neutral implementation boundary:

- [`workflows/tesl-email-to-approval.bpmn`](../workflows/tesl-email-to-approval.bpmn)
  is a BPMN 2.0 process blueprint.
- [`config/tesl-email-mapping.example.json`](../config/tesl-email-mapping.example.json)
  defines configurable TESL field aliases and email metadata preservation.
- [`flows/tesl-email-to-approval.contract.json`](../flows/tesl-email-to-approval.contract.json)
  maps the process to Office 365 Outlook, SharePoint, Power Automate, and Teams
  Approvals actions.
- [`config/approval-templates.example.json`](../config/approval-templates.example.json)
  defines TESL and EDMS escalation templates.
- [`config/role-assignments.example.json`](../config/role-assignments.example.json)
  defines submitter, editor, normal approver, and urgent delegated-approver
  roles without committing tenant UPNs.

## Intended flow

1. Outlook receives an email in the workflow owner's mailbox in the configured
   TESL folder. The live tenant owner mailbox is configured outside source
   control.
2. The flow filters by the configured folder, sender allow-list, and subject
   marker. Non-TESL messages are ignored without creating an approval.
3. TESL fields are extracted from configured header/body aliases. Required
   fields are `teslId`, `teslTitle`, `teslStatus`, and `teslSummary`.
4. The original message metadata and unknown TESL fields are preserved in the
   submission record.
5. The active CareOps approver is resolved and copied immutably to the
   submission.
6. Teams Approvals receives a request containing the TESL details and a link to
   the source email.
7. The decision, comments, approver, timestamps, and request ID are persisted;
   status is surfaced in Teams and SharePoint. Outbound email notifications are
   disabled.
8. If the primary approval remains pending for 14 days, the flow escalates to
   the EDMS approver and records the escalation stage.
9. Only an approved outcome may invoke the future desktop flow for the
   intranet-accessed platform. See
   [`config/desktop-intranet-execution.example.json`](../config/desktop-intranet-execution.example.json).

## Urgent verbal delegation

Natalie Degidio and Kathryn Meharg are represented as the executive-assistant
and medical-workforce-manager delegate roles. They may respond in an urgent
case only when the delegated approval record captures the delegator, delegate,
request ID, reason, and time, and notifies the workflow owner. This is an audit
and routing control; it does not silently reassign an existing approval or
create unrestricted approval authority.

## Tenant setup still required

The following values must be supplied in Power Automate and must not be
committed here:

- the TESL mailbox or folder;
- sender allow-list and subject marker;
- the actual TESL field syntax if it differs from the alias examples;
- SharePoint site/list connection references;
- the active CareOps approver configuration;
- the exact approved UPNs for the executive assistant, medical workforce
  manager, and EDMS escalation approver;
- the authorised workflow editors/co-owners and their connection ownership;
- the approved Power Automate environment and connection owners.
- a registered desktop-flow machine or machine group with approved intranet
  access for the future execution stage.

The flow must be built or imported only after these values are confirmed by the
tenant owner. The contract intentionally remains a blueprint rather than a
claim that a live TESL flow has been deployed.

The live environment currently has no registered desktop machine or machine
group, so the intranet execution stage remains deferred. Power Automate's
direct machine connectivity is the preferred future route; an on-premises
gateway is only a legacy fallback if the tenant already approves and supports
one.

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

## Intended flow

1. Outlook receives an email in the configured TESL folder.
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
   the requester and TESL owner are notified.

## Tenant setup still required

The following values must be supplied in Power Automate and must not be
committed here:

- the TESL mailbox or folder;
- sender allow-list and subject marker;
- the actual TESL field syntax if it differs from the alias examples;
- SharePoint site/list connection references;
- the active CareOps approver configuration;
- the approved Power Automate environment and connection owners.

The flow must be built or imported only after these values are confirmed by the
tenant owner. The contract intentionally remains a blueprint rather than a
claim that a live TESL flow has been deployed.

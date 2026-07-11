# careops-approve

CareOps Approve is a small, Teams-first submit and approve workflow built with
Microsoft 365 standard capabilities. It is intentionally scoped as a bounded
administrative pilot for a requester, an executive assistant, and configurable
named approvers.

The initial implementation is planned under
[`conductor/tracks/basic_submit_approve_20260710/`](conductor/tracks/basic_submit_approve_20260710/).

The MVP deliberately repurposes Microsoft’s native Teams Approvals surface with
standard Forms, SharePoint, and Power Automate capabilities. It is not a custom
Teams app, agent, Entra app, or tenant-admin deployment.

The engineering baseline is solution-aware Power Platform ALM with Microsoft
Power Platform GitHub Actions, Power Platform Pipelines, and a controlled
technology-radar process for preview features. See [ALM strategy](docs/alm.md)
and [technology radar](docs/technology-radar.md).

## Intended workflow

1. A user submits a request with a title, details, and optional supporting link.
2. The flow resolves the currently active named approver configuration.
3. The approver receives an Approve/Reject request in Microsoft Teams.
4. The outcome, comments, timestamps, requester, and approver are recorded.

TESL emails can enter the same approval path through the source-controlled
[TESL email-to-approval blueprint](docs/tesl-email-approval.md), which includes
a BPMN 2.0 process, configurable TESL field mapping, and a Power Automate flow
contract. Tenant mailbox and field syntax remain deployment configuration.
The implementation also records which existing Power Automate patterns are safe
to adapt in the [reuse assessment](docs/power-automate-reuse-assessment.md).

Changing the approver configuration affects new requests. Existing requests keep
the approver assigned when they were submitted so their audit history remains
stable.

## Repository publication

The current authoritative remote is the private NSW Health GHE repository:
`https://nswhealth.ghe.com/60217257/careops-approve`. The private personal mirror is
`https://github.com/edithatogo/careops-approve`.

Local remote names are deliberately role-based:

- `origin`: current NSW Health GHE authority and upstream for `main`.
- `github`: private personal mirror and intended future authority after organisational exit.

See [repository topology](docs/repository-topology.md) for authentication, publishing,
and authority-transition procedures.

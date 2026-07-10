# careops-approve

CareOps Approve is a small, Teams-first submit and approve workflow built with
Microsoft 365 standard capabilities. It is intentionally scoped as a bounded
administrative pilot for a requester, an executive assistant, and configurable
named approvers.

The initial implementation is planned under
[`conductor/tracks/basic_submit_approve_20260710/`](conductor/tracks/basic_submit_approve_20260710/).

The engineering baseline is solution-aware Power Platform ALM with Microsoft
Power Platform GitHub Actions, Power Platform Pipelines, and a controlled
technology-radar process for preview features. See [ALM strategy](docs/alm.md)
and [technology radar](docs/technology-radar.md).

## Intended workflow

1. A user submits a request with a title, details, and optional supporting link.
2. The flow resolves the currently active named approver configuration.
3. The approver receives an Approve/Reject request in Microsoft Teams.
4. The outcome, comments, timestamps, requester, and approver are recorded.

Changing the approver configuration affects new requests. Existing requests keep
the approver assigned when they were submitted so their audit history remains
stable.

## Repository publication

The authoritative GitHub.com remote is
`https://github.com/edithatogo/careops-approve.git`. A second GitHub Enterprise
remote is supported by the repository tooling but cannot be activated until its
hostname and repository URL are supplied and reachable from an approved runner.

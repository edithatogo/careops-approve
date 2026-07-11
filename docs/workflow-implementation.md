# Workflow implementation boundary

The first flow implementation must preserve the tested contract in
`config/workflow-scenarios.example.json`:

1. Validate title and description before creating a record.
2. Generate one request ID and create the submission with `Submitted` status.
3. Resolve the active approver configuration once.
4. Copy the resolved approver and configuration version into the submission.
5. If configuration is empty, inactive, duplicated, or otherwise invalid, keep
   the submission and alert a workflow owner.
6. A requester acknowledgement must include the request ID and resolved approver.

The Teams-accessible trigger and Power Automate actions are deployed tenant
artifacts. This repository provides the contract, scenarios, deployment
attestation, and validation gate without embedding a SharePoint site,
connection ID, or identity.

`flows/submit-and-route.contract.json` is the tenant-neutral source contract
for the deployed flow. The deployment remains outside source control and is
tracked by executive confirmation in `docs/deployment-attestation.md`.

`config/decision-scenarios.example.json` is the decision-state test contract. A
rejection cannot finalize without a comment, and a later response cannot replace
an existing final outcome. Connector failure is recorded as failed and alerts an
owner so the request remains operationally visible.

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

The eventual Teams-accessible trigger and Power Automate actions remain tenant
artifacts. This repository currently provides the contract, scenarios, and
validation gate without embedding a SharePoint site, connection ID, or identity.

`flows/submit-and-route.contract.json` is the build blueprint for those actions.
It must be translated into a solution-aware cloud flow only after the tenant
owner confirms the permitted Forms, SharePoint, Power Automate, and Teams
Approvals surfaces.

`config/decision-scenarios.example.json` is the decision-state test contract. A
rejection cannot finalize without a comment, and a later response cannot replace
an existing final outcome. Connector failure is recorded as failed and alerts an
owner so the request remains operationally visible.

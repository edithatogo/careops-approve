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

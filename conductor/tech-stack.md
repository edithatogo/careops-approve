# Technology Stack

## Microsoft 365 Runtime

- Microsoft Teams Approvals app for approver interaction.
- Power Automate cloud flow using standard connectors.
- SharePoint Online lists for submissions, approval outcomes, and approver configuration.
- Microsoft Entra ID user identities for requesters, owners, and approvers.

## Solution and Source Control

- Power Platform solution-aware cloud flow where tenant policy permits.
- Power Platform CLI (`pac`) for solution export, unpack, validation, and deployment.
- Unpacked solution artifacts stored as text in Git.
- Environment-specific values represented by connection references and environment
  variables rather than hard-coded tenant identifiers.

## Testing and Validation

- Static validation of unpacked solution and configuration artifacts.
- Automated checks for required flow actions, connection references, and configuration.
- Manual end-to-end tests in a non-production Microsoft 365 environment.

## Constraints

- No premium or custom connectors in the MVP.
- No hard-coded user object IDs or email addresses in flow logic.
- No external data stores or public endpoints.
- Deployment remains subject to tenant app, environment, DLP, retention, and licensing policy.

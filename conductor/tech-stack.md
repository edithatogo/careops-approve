# Technology Stack

## Microsoft 365 Runtime

- Microsoft Teams Approvals app for approver interaction.
- Microsoft Forms or an equivalent standard Teams entry surface for submission.
- Power Automate cloud flow using standard connectors.
- SharePoint Online lists for submissions, approval outcomes, and approver configuration.
- Microsoft Entra ID user identities for requesters, owners, and approvers.

The MVP does not create a custom Teams app, Microsoft 365 agent, Entra app registration,
Graph application, bot, or custom connector. The Agents Toolkit CLI is a local
diagnostic/package tool only until tenant custom-app upload and any required consent
are separately approved.

## Solution and Source Control

- Power Platform solution-aware cloud flow where tenant policy permits.
- Power Platform CLI (`pac`) for solution export, unpack, validation, and deployment.
- Microsoft Power Platform GitHub Actions for pack, solution checker, artifact,
  and deployment automation.
- Power Platform Pipelines for governed environment promotion, deployment approvals,
  and delegated deployment where tenant administrators permit it.
- Unpacked solution artifacts stored as text in Git.
- Environment-specific values represented by connection references and environment
  variables rather than hard-coded tenant identifiers.
- NSW Health GHE (`nswhealth.ghe.com`) as the current authoritative remote using the
  managed identity `60217257`.
- Private GitHub.com repository under `edithatogo` as the continuity mirror and
  intended future authority after a governed organisational transition.
- Host-specific GitHub CLI authentication and Git credential routing; automation
  must explicitly select its host and must not rely on a global token override.

## Microsoft Kits and Accelerators

- Evaluate the Microsoft Business Approvals Kit before custom-building advanced
  approval administration, delegation, or multi-stage orchestration.
- Reuse compatible Center of Excellence Starter Kit governance conventions rather
  than coupling this workload to the entire CoE kit.
- Keep the basic one-stage workflow independently deployable; adopting a kit must
  be justified by requirements, licensing, supportability, and DLP compatibility.

## Frontier Evaluation Lane

- Microsoft Graph Approvals APIs are an opt-in integration candidate for richer
  Teams experiences, subscriptions, and reporting.
- Power Apps Test Engine ALM remains a preview test lane and is not a production gate.
- Power Platform 2026 release-wave capabilities are reviewed through a dated radar;
  preview features require feature flags, isolated environments, rollback evidence,
  and explicit approval before adoption.
- Native Dataverse Git integration is monitored but not selected for this repository
  because its current supported repository provider is Azure DevOps Git, not GitHub.

## Testing and Validation

- Static validation of unpacked solution and configuration artifacts.
- Automated checks for required flow actions, connection references, and configuration.
- Manual end-to-end tests in a non-production Microsoft 365 environment.

## Local Tooling Baseline

- nvm-managed Node.js 22.23.1 with npm 10.9.8.
- Microsoft 365 Agents Toolkit CLI 1.1.11 (`atk`); `atk doctor` runs successfully
  with warnings that custom app upload is disabled, Azure Functions Core Tools is
  absent, and a local certificate is absent.
- MicrosoftTeams PowerShell module 7.8.0 installed for the current user.
- `Connect-MicrosoftTeams -AccountId` attempted delegated WAM authentication but
  failed with a WAM internal error; `dsregcmd` reports `WamDefaultSet: NO` and
  `AzureAdPrt: NO`.
- These local authentication facts do not imply tenant admin access and are not
  sufficient to deploy or install a custom app.

## Constraints

- No premium or custom connectors in the MVP.
- No custom Teams app, agent, Entra app registration, Graph application permission,
  or tenant-wide admin dependency in the MVP.
- No hard-coded user object IDs or email addresses in flow logic.
- No external data stores or public endpoints.
- Deployment remains subject to tenant app, environment, DLP, retention, and licensing policy.
- Preview capabilities must not become production dependencies without a recorded
  architecture decision and a supported fallback.

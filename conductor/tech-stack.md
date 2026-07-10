# Technology Stack

## Microsoft 365 Runtime

- Microsoft Teams Approvals app for approver interaction.
- Power Automate cloud flow using standard connectors.
- SharePoint Online lists for submissions, approval outcomes, and approver configuration.
- Microsoft Entra ID user identities for requesters, owners, and approvers.

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

## Constraints

- No premium or custom connectors in the MVP.
- No hard-coded user object IDs or email addresses in flow logic.
- No external data stores or public endpoints.
- Deployment remains subject to tenant app, environment, DLP, retention, and licensing policy.
- Preview capabilities must not become production dependencies without a recorded
  architecture decision and a supported fallback.

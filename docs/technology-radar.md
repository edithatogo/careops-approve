# Technology Radar

Last reviewed: 2026-07-10

## Adopt

| Capability | Use | Reason |
| --- | --- | --- |
| Solution-aware cloud flows | Production baseline | Supported Power Platform ALM unit |
| Power Platform CLI | Build and diagnostics | Microsoft-supported automation surface |
| Microsoft Power Platform GitHub Actions | CI, pack, checker, deploy | Official actions wrapping Power Platform CLI |
| Power Platform Pipelines | Governed promotion | Native environment promotion and approval controls |
| Connection references and environment variables | Configuration | Prevent tenant-specific values in source control |
| Service-principal deployment | CI identity | Separates deployment from individual maker accounts |

## Trial

| Capability | Trial boundary | Exit criteria |
| --- | --- | --- |
| Microsoft Business Approvals Kit | Isolated Dataverse environment | Licensing, DLP, support, and complexity are proportionate |
| Power Apps Test Engine ALM preview | Non-production test lane only | Stable runner behaviour and useful coverage for this workflow |
| Microsoft Graph Approvals APIs | Isolated prototype | Required permissions approved and clear benefit over standard actions |
| Delegated Power Platform Pipeline deployment | Pilot pipeline stage | Service principal ownership and approval controls accepted by admins |

## Watch

| Capability | Current constraint |
| --- | --- |
| Native Dataverse Git integration | Current setup documentation supports Azure DevOps Git, not GitHub |
| 2026 wave 1 GitHub integration and deploy-from-Git capabilities | Availability and tenant geography must be verified before adoption |
| Graph subscriptions for approval responses | Requires app registration, permissions, lifecycle handling, and support ownership |
| Agentic or Copilot-authored flow capabilities | Unnecessary for deterministic one-stage approval and introduces governance overhead |

## Hold

| Capability | Reason |
| --- | --- |
| Preview-only production dependency | No support or rollback guarantee suitable for the pilot |
| Username/password deployment | Incompatible with MFA and individual-account independence |
| Destructive `git push --mirror` automation | Can delete enterprise refs and does not copy repository settings |
| Hard-coded approvers | Prevents controlled roster changes and leaks personal configuration into source |

## Review rule

Review this radar before each pilot release and at least once per Power Platform
release wave. Moving an item between rings requires an architecture decision that
records availability, licensing, security review, fallback, and rollback evidence.

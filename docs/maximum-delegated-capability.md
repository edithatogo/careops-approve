# Maximum delegated capability profile

This profile records the maximum useful CareOps capability that can be operated
with the current maker-level and user-delegated permissions. It is deliberately
separate from tenant-admin or Entra-dependent ambitions.

## Available now, subject to normal pilot evidence

| Process or capability | Permitted implementation | Operational boundary |
| --- | --- | --- |
| Basic submit and approve | Native Teams Approvals, standard Power Automate, SharePoint state | Human approval remains authoritative; suppress email where supported |
| TESL email intake | Outlook trigger, deterministic parser, duplicate key, correction queue, native approval | Use an approved mailbox/folder and sanitized telemetry |
| TESL policy review | Advisory AI Builder/Copilot prompt before approval | Redacted fields only; AI cannot approve, reject, or override a person |
| TESL decision execution | Approval response triggers downstream Power Automate | Intranet execution is deferred until an approved desktop host exists |
| Delegation and escalation | SharePoint roster/configuration, urgent verbal-delegation record, 14-day EDMS escalation | Do not reassign an in-flight approval silently |
| Requester status and feedback | Restricted SharePoint/Teams status surface | No broad visibility of internal comments or subject details |
| Operational tracking | Planner basic-plan task projection and owner-only Teams summaries | Planner cannot change the approval decision; no sensitive payloads |
| Templates and routing | Versioned template catalogue with deterministic request-type routing | Template-owner and pilot approval remain required |
| Quality and reconciliation | Validation, orphan detection, idempotent replay, failure queues, repository CI | Live flow evidence is still required for tenant claims |
| ALM and continuity | GHE primary, private GitHub mirror, solution source, GitHub Actions validation | Runtime connections, secrets, UPNs, and tenant identifiers stay outside Git |

## Conditional with current user permissions

- Advisory AI activation requires an available AI Builder/Copilot action,
  permitted data classification, capacity/licensing, and a controlled pilot.
- Planner projection requires an owner-created basic plan and connected Planner
  account with restricted membership.
- Dataverse can be a read-only review or correction surface if the existing
  environment and connector are available; it must not replace native approval.
- Power Automate Desktop can execute the approved intranet step after a managed
  desktop is registered and the user has an approved machine connection.
- PAC/PACX can support export, inspection, and reconciliation after delegated
  maker access is available; it cannot grant deployment or admin rights.

## Authorized but paused pending the right account or session

The platform/tenant owner has authorized these capabilities. They are paused
only because the current signed-in account does not have the required Entra or
administrator permissions. Do not attempt workarounds or create substitute
identities; resume these tracks when an appropriately privileged, approved
session is available.

- Microsoft Graph Approvals automation requiring Entra app registration,
  application permissions, or admin consent.
- Custom Teams app, bot, or Microsoft 365 Agent deployment requiring app upload,
  Entra identity, or tenant policy approval.
- Tenant DLP, retention, environment, connector, licensing, or Teams app-policy
  changes.
- Managed Power Platform Pipelines requiring a Dataverse/Managed Environment
  and administrator setup.
- Unattended or centrally hosted intranet automation without an approved
  registered machine, gateway, or service identity.

These are not rejected or unauthorized. They are execution-blocked for the
current account and must remain paused until the required platform session is
available.

## Execution order

1. Pilot the existing native Teams, TESL intake, delegation, escalation,
   correction, Planner, and requester-status paths with synthetic or approved
   low-risk records.
2. Bind and pilot the advisory AI prompt, including unavailable and
   low-confidence fallbacks.
3. Register the desktop host and pilot approved-only intranet execution.
4. Reconcile live flow exports against the source contracts and repair only
   flows within the owner's delegated maker scope.
5. Revisit blocked capabilities only when the required tenant authority is
   explicitly granted.

The repository's Conductor tracks and capability matrix remain the detailed
work queue; this document is the permission boundary and prioritisation lens.

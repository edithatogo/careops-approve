# Low-Privilege MVP Architecture

## Decision

Use Microsoft’s native Teams Approvals app as the decision surface, with a standard
Microsoft Form or Teams-accessible submission surface, Power Automate standard
connectors, and SharePoint Online lists for configuration and records.

This is the appropriate boundary for a user who cannot create Entra applications,
cannot obtain tenant-wide admin consent, and cannot upload custom Teams apps.

## Reusable Microsoft surfaces

- **Teams Approvals app:** native request, notification, decision, and history surface.
- **Microsoft Forms:** simple requester input without a custom app registration.
- **SharePoint Online:** request, outcome, and configuration records subject to site policy.
- **Power Automate:** standard connector orchestration and notifications.
- **Teams PowerShell:** optional delegated, read-only discovery where the user owns or
  belongs to the relevant Team; it is not an admin-elevation mechanism.

The repository contains no existing local Teams app manifest, Agents Toolkit project,
or custom Teams kit to import. The native Approvals app is therefore the repurposed
Microsoft asset for this MVP.

## Explicitly excluded from MVP

- Custom Teams app package or sideloading.
- Microsoft 365 agent or bot deployment.
- Entra app registration, application permissions, or admin consent.
- Microsoft Graph application authentication.
- Teams tenant policy changes or app-upload enablement.
- Power Platform service-principal deployment until separately approved.

## Authentication findings

The Agents Toolkit CLI is installed as a local developer diagnostic and reports the
authenticated Microsoft 365 account. Its doctor check reports that custom app upload
is disabled for the tenant account.

MicrosoftTeams PowerShell 7.8.0 is installed for the current user. The delegated
WAM path was attempted with `Connect-MicrosoftTeams -AccountId` and failed with a WAM
internal error. The workstation also reports `WamDefaultSet: NO` and `AzureAdPrt: NO`.
WAM should therefore be treated as unavailable on this workstation until M365 identity
state is repaired; it is not a reason to add an Entra app or request admin privileges.

## Fallback

If a tenant owner confirms the standard connectors and native Approvals app, proceed
with a user-owned or team-owned flow according to policy. If the tenant requires a
different connection owner, stop at the governance gate and request an approved owner
or connection rather than attempting to bypass the restriction.

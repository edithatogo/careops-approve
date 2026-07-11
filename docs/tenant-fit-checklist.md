# Tenant Fit and Governance Evidence Checklist

Status: in progress  
Last reviewed: 2026-07-10

This checklist is the evidence gate for the basic Teams submit-and-approve pilot.
It distinguishes locally verified facts from tenant facts that require a Microsoft
365 or Power Platform administrator. No credentials, secrets, personal data, or
tenant exports belong in this file.

## Locally verified

- [x] GitHub CLI has healthy, separate authentication for `github.com` (`edithatogo`)
      and `nswhealth.ghe.com` (`60217257`).
- [x] NSW Health GHE is the current Git authority and GitHub.com is the private mirror.
- [x] The two remotes contain the same published `main` commit.
- [x] GHE hosted runners are disabled for this repository and no repository runner is assigned.
- [x] Personal GitHub validation passes against the same commit; this is supporting evidence,
      not equivalent GHE-native control.
- [x] Agents Toolkit CLI 1.1.11 is installed and `atk doctor` can run locally.
- [x] `atk doctor` reports custom app upload is disabled for the tenant account.
- [x] MicrosoftTeams PowerShell 7.8.0 is installed for the current user.
- [x] Delegated Teams PowerShell WAM authentication was attempted and failed with a WAM
      internal error; the workstation reports `WamDefaultSet: NO` and `AzureAdPrt: NO`.
- [x] No existing local Teams app manifest or Agents Toolkit project was found to repurpose.

## Tenant administrator evidence required

- [ ] Teams Approvals app is enabled for the pilot users and permitted by app policy.
- [ ] Microsoft Forms is enabled for the pilot users, or an equivalent standard Teams
      submission surface is approved.
- [ ] Power Automate licensing covers the standard Approvals and Microsoft 365 connectors.
- [ ] The target Power Platform environment has Dataverse provisioned if required by the
      selected Approvals or Business Approvals Kit path.
- [ ] The environment is approved for this pilot and is not the default environment if
      policy requires an isolated development or pilot environment.
- [ ] DLP policy permits Teams, Approvals, Power Automate, SharePoint, and Dataverse
      connections in the same business data group.
- [ ] SharePoint site/list ownership, permissions, retention, audit, and restore expectations
      are approved for request and decision records.
- [ ] Data classification confirms the MVP will not receive clinical, emergency, financial,
      procurement, or otherwise restricted content.
- [ ] An authorised workflow owner and backup owner are nominated.
- [ ] Initial requester, approver, and configuration-owner identities are approved.
- [ ] Power Platform Pipelines host and development/pilot/production environments are approved,
      or the reason for deferral is recorded.
- [ ] Service principal or delegated deployment identity is approved with least-privilege roles.
- [ ] AI Builder prompt availability, capacity, region, data classification, retention, and prompt owner are approved before enabling advisory AI review.
- [ ] GHE Actions policy provides an approved hosted runner or repository self-hosted runner.
- [ ] GHE repository rulesets, Actions policy, environments, reviewers, and secrets are configured.

## Decision gates

The track cannot move to implementation of the live flow until the following are true:

1. Teams Approvals and the standard connector path are confirmed available.
2. Data classification and retention are approved for the pilot.
3. An owner and backup owner are named.
4. The deployment identity and target environment are approved.
5. Either GHE-native CI is enabled or the interim personal-mirror CI arrangement is
   explicitly accepted as a temporary exception with no NSW Health secrets.

## Evidence to attach outside the repository

Store approvals, screenshots, tenant policy exports, service-principal records, and
retention decisions in the organisation-approved evidence location. Record only the
evidence reference, decision date, approver role, and expiry/review date in a future
track update.

## References

- Microsoft Teams Approvals administration: https://learn.microsoft.com/en-us/microsoftteams/approval-admin
- Power Platform GitHub Actions: https://learn.microsoft.com/en-us/power-platform/alm/devops-github-actions
- Power Platform Pipelines: https://learn.microsoft.com/en-us/power-platform/alm/pipelines
- Business Approvals Kit FAQ: https://learn.microsoft.com/en-us/power-automate/guidance/business-approvals-templates/frequently-asked-questions

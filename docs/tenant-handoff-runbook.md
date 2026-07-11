# Tenant handoff and pilot runbook

This runbook separates repo-proven behavior from tenant-only verification.

## Before deployment

- Confirm Teams Approvals, Forms, SharePoint, Dataverse, and standard connector
  licensing/DLP policy with a tenant owner.
- Create or identify the pilot environment and approved connection owners.
- Replace only tenant-neutral placeholders in the deployment settings file.
- Configure the approved workflow owner, submitters, primary approver, EDMS
  escalation approver, and urgent-delegation policy in the tenant.
- Confirm no email notifications are enabled for approval creation or status
  updates.

## Deployment

1. Run `scripts/Test-Repository.ps1` and `harness/Test-Harness.ps1`.
2. Pack the solution from `src/solutions/CareOpsApprove`.
3. Run the Power Platform solution checker.
4. Import into pilot using the protected `pilot` environment.
5. Bind connections and environment-specific settings manually through the
   approved deployment process.
6. Record the solution version and deployment evidence outside source control.

## Rollback

- Stop new submissions at the tenant trigger.
- Preserve existing approvals and assigned approvers.
- Export the pilot solution state and record the failed version.
- Restore the previously approved solution version through the governed
  Power Platform deployment path.
- Re-run the smoke and decision scenario checks.

## Manual verification

- Submit a valid request and confirm a request ID and resolved approver.
- Reject without a comment and confirm finalization is refused.
- Reject with a comment and confirm the immutable outcome is persisted.
- Approve and confirm requester status is updated without email.
- Submit with invalid approver configuration and confirm the submission is
  preserved and the owner is alerted.
- Change the approver configuration after submission and confirm the existing
  approval remains assigned to its original approver.
- Verify 14-day pending escalation and urgent verbal-delegation recording.

## Explicit external gates

Custom Entra/Graph registration, desktop-machine registration, tenant-owner
confirmation, connection binding, and live end-to-end tests require tenant
permissions and are not represented as completed by repository validation.

# CareOps Approve deployment attestation

Attestation date: 2026-07-11  
Attested by: executive workflow owner (user confirmation in the implementation record)

## Runtime status

The following workflows are deployed in the Microsoft Teams/Power Automate
environment:

1. CareOps Submit and Route
2. CareOps TESL Email to Approval

The advisory AI review stage is implemented in source contracts but remains
not yet invoked in the live workflows pending AI Builder licensing, region, data
classification, retention, prompt ownership, and pilot evidence.

## Source-control boundary

The repository contracts retain `status: blueprint` because they are
tenant-neutral source artefacts rather than live Power Automate exports. Each
contract also records `deploymentStatus: executive-confirmed-live`.

The repository intentionally excludes tenant URLs, environment IDs, connection
references, flow IDs, UPNs, group IDs, live payloads, screenshots, secrets, and
deployment tokens.

## Remaining operational verification

This attestation confirms deployment status. Separate pilot evidence should
record successful submission, approval, rejection, invalid configuration,
14-day escalation, cancellation, and visibility checks. Store that evidence in
the organisation-approved location and record only a sanitized reference here.

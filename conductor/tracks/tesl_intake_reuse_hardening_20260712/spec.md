# TESL intake reuse hardening

## Overview

Extend the tenant-neutral CareOps TESL approval contract with the verified
operational safeguards found in the existing TESL Power Platform work: stable
idempotency, duplicate suppression, explicit processed/failed routing, sanitized
telemetry, and a human manual-correction path. No tenant URLs, IDs, payloads,
UPNs, or connection references may be copied into this repository.

## Functional requirements

1. The email intake must derive a stable idempotency key from the source message
   identity and TESL reference, and must not create a second submission or
   approval for a duplicate message.
2. Valid messages must record a sanitized intake event and route to the normal
   approval path.
3. Invalid or unparseable messages must be preserved, routed to a configured
   failure state, and surfaced to the workflow owner without outbound email.
4. The workflow must record correlation, processing state, and actionable error
   metadata without storing raw sensitive email content in source control.
5. A human correction/review path must allow the owner to correct extracted
   fields before approval creation; it must never bypass the native approval.
6. The reusable patterns must be represented in the contract, BPMN, Mermaid,
   configuration examples, documentation, and executable validation.

## Acceptance criteria

- Duplicate, malformed, processed, telemetry, and manual-correction scenarios
  are explicitly covered by repository tests.
- The TESL BPMN and visual model show the intake safeguards and correction path.
- All examples remain tenant-neutral and email-free.
- Child and portfolio harnesses pass with no publication-boundary findings.

## Out of scope

- Importing or changing live Power Automate flows without an authenticated PAC
  profile and tenant-owner release evidence.
- Copying the existing tenant solution export, URLs, IDs, or runtime payloads.
- Autonomous AI decisions or automatic intranet execution before approval.

# Approvals app integration roadmap

## Overview

Integrate the verified TESL and Power Platform patterns into CareOps Approve
through staged, testable tracks. Native Teams Approvals remains the decision
system of record; SharePoint/Dataverse provide state and review surfaces; AI
remains advisory; and desktop execution remains an approved-only boundary.

## Capability tracks

1. TESL Outlook intake and deterministic parsing.
2. Idempotency and duplicate suppression.
3. Failed-extraction routing and owner correction.
4. Sanitized telemetry and owner-only reporting.
5. Teams status, escalation, roster, and delegation integration.
6. Dataverse review-surface integration where tenant licensing permits.
7. Approved post-decision desktop/intranet execution boundary.

Existing `safe_approval_lifecycle_hardening` and `advisory_ai_review` tracks are
dependencies rather than duplicated work.

## Global acceptance criteria

- Each capability has source contracts, BPMN/visual coverage where process
  behaviour changes, executable tests, and a tenant handoff procedure.
- No tenant identifiers, raw email, secrets, or live connection references are
  committed.
- No integration can silently approve, reassign, or expose a request.
- Live activation requires PAC-authenticated tenant evidence and owner approval.

## Out of scope

Autonomous approvals, broad channel visibility, unapproved Graph/Entra app
registration, direct cloning of corrupted flows, and unattended intranet access.

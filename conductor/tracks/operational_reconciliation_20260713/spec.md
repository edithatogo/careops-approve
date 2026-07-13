# Operational reconciliation and orphan repair

## Overview

Add an owner-controlled reconciliation process that compares native approval state
with the approved SharePoint/Dataverse record and identifies missing, stale or
inconsistent items.

## Requirements

- Reconciliation is read-only by default and produces an owner-only exception list.
- Repair actions are idempotent, individually approved and auditable.
- Final decisions are never overwritten; conflicts require manual review.
- Raw request content is excluded from telemetry and issue records.

## Acceptance criteria

- Missing approval, missing state, stale pending, conflicting final and replay cases pass.
- Every repair has before/after state, reason, actor and correlation identifier.

## Out of scope

- Tenant-wide discovery or automatic deletion of approval records.


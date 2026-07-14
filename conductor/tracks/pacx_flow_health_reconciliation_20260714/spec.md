# Read-only PACX flow health and reconciliation

## Problem

Live solution inventory is available through Dataverse, but management-plane flow inventory and source-readable definitions are not yet reconciled. The current evidence includes activated and draft records and a maker-surface corruption warning, but no safe machine-readable health report.

## Goal

Add read-only inventory, definition, export and health reporting that maps live flows to source contracts, identifies duplicates or broken bindings, and produces sanitized evidence for review.

## Acceptance criteria

- `flow list`, `flow get` and export/report operations are read-only and clearly labelled.
- Health states include definition found, activated/draft, recent-run evidence, unresolved connection, duplicate and corruption warning.
- Reports map only approved flow names to source contracts and omit secrets, tenant identifiers, raw tokens and sensitive payloads.
- Unknown or draft flows are reported for review and are never activated, deleted or repaired automatically.
- Fixture-based tests cover normal, duplicate, missing-definition and malformed-definition cases.
- An optional live smoke test reads a small approved scope and records only sanitised counts and statuses.

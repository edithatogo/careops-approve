# Live Power Automate flow reconciliation

## Overview

Use delegated maker access to inventory and export the live CareOps flows, compare
them with source contracts, identify duplicate or invalid flows, and produce a
repeatable solution-aware release artifact.

## Requirements

- Authenticate interactively without storing credentials or tenant identifiers.
- Export only authorised solution components and sanitize recorded evidence.
- Compare triggers, actions, parameters, connection references and enabled state.
- Quarantine or retire duplicates only after owner review; preserve run history.
- Repack and validate the reconciled solution through the existing ALM harness.

## Acceptance criteria

- A sanitized inventory maps each live flow to one source contract and owner decision.
- Broken bindings and duplicates have explicit remediation evidence.
- Pilot flows pass solution validation and end-to-end tests.

## Out of scope

- Tenant-wide discovery, admin elevation, secrets in Git, or destructive bulk deletion.


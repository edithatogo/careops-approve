# Implementation plan

- [x] Define trigger, parser, mapping, and validation contracts.
- [x] Add valid/invalid/missing-field fixtures and tests.
- [x] Add tenant handoff settings without tenant identifiers.
- [x] Add cloud-only historical backfill contract with folder inventory,
  exhaustive pagination, minimized Dataverse projection and reconciliation gates.
- [x] Add tenant-owner runbook and sanitized evidence contract for the complete
  historical mailbox backfill.
- [ ] Validate in a pilot mailbox with PAC-authenticated evidence.
- [ ] Conductor - User Manual Verification 'TESL Outlook intake' (Protocol in workflow.md)

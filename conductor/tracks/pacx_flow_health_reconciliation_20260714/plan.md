# Implementation plan

- [x] Task: Define the sanitised flow-health schema and source-contract mapping.
    - [x] Reuse the existing contract and evidence formats.
    - [x] Define stable statuses and an explicit unknown state.
- [x] Task: Implement read-only PACX inventory/report commands.
    - [x] Add a sanitised inventory-to-report path.
    - [x] Refuse mutation verbs from the health command.
    - [x] Require explicit scope and confirmation for any future mutation command.
- [x] Task: Add fixture tests.
    - [x] Test activated and draft records.
    - [x] Test duplicate, missing binding, malformed definition and corruption-warning records.
    - [x] Test redaction of credentials and sensitive identifiers.
- [~] Task: Run a low-privilege live read-only pilot after bearer authentication is fixed.
    - [ ] Compare the result with the source repository.
    - [x] Record unresolved external gates without marking reconciliation complete.

Checkpoint: sanitised report path and nine fixture scenarios passed; live pilot remains externally gated.
- [ ] Task: Conductor - User Manual Verification 'PACX flow health reconciliation' (Protocol in workflow.md)

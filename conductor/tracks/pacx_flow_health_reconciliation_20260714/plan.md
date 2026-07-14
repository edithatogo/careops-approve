# Implementation plan

- [ ] Task: Define the sanitised flow-health schema and source-contract mapping.
    - [ ] Reuse the existing contract and evidence formats.
    - [ ] Define stable statuses and an explicit unknown state.
- [ ] Task: Implement read-only PACX inventory/report commands.
    - [ ] Add list/get/export or equivalent report paths.
    - [ ] Refuse mutation verbs from the health command.
    - [ ] Require explicit scope and confirmation for any future mutation command.
- [ ] Task: Add fixture tests.
    - [ ] Test activated and draft records.
    - [ ] Test duplicate, missing binding, malformed definition and corruption-warning records.
    - [ ] Test redaction of credentials and sensitive identifiers.
- [ ] Task: Run a low-privilege live read-only pilot after bearer authentication is fixed.
    - [ ] Compare the result with the source repository.
    - [ ] Record unresolved external gates without marking reconciliation complete.
- [ ] Task: Conductor - User Manual Verification 'PACX flow health reconciliation' (Protocol in workflow.md)

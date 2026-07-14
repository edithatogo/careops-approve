# Implementation plan

- [ ] Task: Inspect `TokenProvider` and the Power Automate management client.
    - [ ] Identify where the management resource and authentication scheme are selected.
    - [ ] Add a focused regression test before changing behavior.
- [ ] Task: Implement a supported management token path.
    - [ ] Request the management resource explicitly.
    - [ ] Ensure the HTTP request uses Bearer/MSAuth1.0 and never PoP for this client.
    - [ ] Preserve secure token-cache behavior and redact diagnostics.
- [ ] Task: Add low-privilege authentication fallbacks.
    - [ ] Keep silent acquisition first.
    - [ ] Add device-code or WAM fallback where supported by the host.
    - [ ] Keep system-browser fallback for environments where it is available.
- [ ] Task: Verify the change.
    - [ ] Run unit and static tests.
    - [ ] Run one read-only flow-list smoke test.
    - [ ] Record sanitized evidence in the CareOps repo.
- [ ] Task: Conductor - User Manual Verification 'PACX bearer authentication' (Protocol in workflow.md)

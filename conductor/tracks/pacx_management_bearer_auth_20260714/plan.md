# Implementation plan

- [~] Task: Inspect `TokenProvider` and the Power Automate management client.
    - [x] Identify where the management resource and authentication scheme are selected.
    - [x] Add a focused regression test before changing behavior.
- [x] Task: Implement a supported management token path.
    - [x] Request the management resource explicitly.
    - [x] Ensure the HTTP request uses Bearer/MSAuth1.0 and never PoP for this client.
    - [x] Preserve secure token-cache behavior and redact diagnostics.
- [x] Task: Add low-privilege authentication fallbacks.
    - [x] Keep silent acquisition first.
    - [x] Add device-code fallback to avoid broker-issued PoP tokens.
    - [x] Keep system-browser fallback for environments where device code is disabled.
- [~] Task: Verify the change.
    - [x] Run focused unit tests.
    - [x] Build the PACX fork for net10.0.
    - [ ] Complete one read-only flow-list smoke test after interactive device-code sign-in.
    - [x] Record sanitized evidence and the merge-permission blocker in the CareOps repo.

Checkpoint: PACX source implementation `f41168d`; CareOps evidence checkpoint pending commit.
- [ ] Task: Conductor - User Manual Verification 'PACX bearer authentication' (Protocol in workflow.md)

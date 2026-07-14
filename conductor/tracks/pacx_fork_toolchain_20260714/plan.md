# Implementation plan

- [x] Task: Define the supported local toolchain matrix.
    - [x] Document .NET 11 preview as preferred when available.
    - [x] Document the verified .NET 10 fallback and its limitations.
    - [x] Pin or record a reviewed PACX source revision.
- [x] Task: Add a safe user-local installer/runner.
    - [x] Add `scripts/Install-PacxFork.ps1` as a repo-local wrapper.
    - [x] Keep clones and build output outside the repository by default.
    - [x] Fail clearly when required SDKs are missing.
- [x] Task: Add diagnostics and secret-safety checks.
    - [x] Provide version, SDK and command capability output.
    - [x] Redact profiles, tokens, URLs containing tenant data and raw responses.
    - [x] Add fixture tests for generated evidence.
- [~] Task: Verify from a fresh temporary clone and update the tooling guide.
    - [x] Run the wrapper against a fresh clone.
    - [x] Update the tooling guide and repository harness.
- [ ] Task: Conductor - User Manual Verification 'PACX fork toolchain' (Protocol in workflow.md)

Checkpoint: fresh-clone net10.0 build and version smoke test passed; CareOps evidence pending commit.

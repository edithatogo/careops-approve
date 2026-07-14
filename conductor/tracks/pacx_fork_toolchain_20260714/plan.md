# Implementation plan

- [ ] Task: Define the supported local toolchain matrix.
    - [ ] Document .NET 11 preview as preferred when available.
    - [ ] Document the verified .NET 10 fallback and its limitations.
    - [ ] Pin or record a reviewed PACX source revision.
- [ ] Task: Add a safe user-local installer/runner.
    - [ ] Add `scripts/Install-PacxFork.ps1` or an equivalent repo-local wrapper.
    - [ ] Keep clones and build output outside the repository by default.
    - [ ] Fail clearly when required SDKs are missing.
- [ ] Task: Add diagnostics and secret-safety checks.
    - [ ] Provide version, SDK and command capability output.
    - [ ] Redact profiles, tokens, URLs containing tenant data and raw responses.
    - [ ] Add fixture tests for generated evidence.
- [ ] Task: Verify from a fresh temporary clone and update the tooling guide.
- [ ] Task: Conductor - User Manual Verification 'PACX fork toolchain' (Protocol in workflow.md)

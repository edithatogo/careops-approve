# Reproducible PACX fork toolchain

## Problem

The official PACX global tool requires a .NET 8 runtime that is not available in the current user-local installation. The fork requests a .NET 11 preview SDK, while this workstation currently has .NET 10. A temporary, documented build workaround works, but it is not yet a reusable installation path.

## Goal

Provide a user-local, reproducible PACX fork build/install and diagnostic wrapper that works with the available SDK, clearly reports when the preview SDK is required, and never writes credentials into the repository.

## Acceptance criteria

- Source repository, branch/commit and target framework are explicit and validated.
- A PowerShell wrapper can build or locate the fork without administrator rights.
- The wrapper supports the preferred preview SDK when installed and the tested net10.0 fallback when it is not.
- `--version`, auth profile checks and a safe diagnostic command are documented.
- Fresh temporary-clone validation succeeds without changing the source clone permanently.
- Tests reject credentials, tokens, environment IDs and raw flow exports in generated artifacts.

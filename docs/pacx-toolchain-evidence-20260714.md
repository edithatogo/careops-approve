# PACX fork toolchain evidence

Check date: 2026-07-14
Source repository: `edithatogo/pacx`
Source commit: `f57880eb10acfd0d7004f048082e3179f649bad9`
Selected target: `net10.0` fallback; the preferred `net11.0` SDK is not installed
on this workstation.

## Verification

- Manifest and installer safety checks passed.
- Diagnostics reported `credentialFilesCreated: false` and `liveMutation: false`.
- A fresh shallow clone built successfully outside the CareOps repository.
- The wrapper located the built `pacx.dll` and returned PACX version `1.0.0.0`.
- The source clone retained its original `global.json` after the fallback build.

The test used only source code and build output. It did not authenticate, create
profiles, access a tenant, export flows, or mutate Power Platform resources.

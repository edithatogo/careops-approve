# Reproducible Power Platform tooling

The repository pins the no-admin local toolchain in `tooling/powerplatform-tools.json`.
Run this from the repository root on a new workstation:

```powershell
pwsh -File scripts/Install-PowerPlatformTooling.ps1
```

The installer uses user-local .NET and global-tool locations. It does not create,
copy, or commit authentication profiles. Authentication remains an explicit
operator action after reviewing the target tenant:

```powershell
pac auth create --name careops-owner --deviceCode
pac auth list
```

`pac` and `pacx` support repeatable package inspection, solution operations, and
diagnostics. They do not replace tenant permissions, Power Automate deployment
approvals, or a real pilot; those remain external harness gates.

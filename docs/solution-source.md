# Solution source foundation

The source-controlled solution is `src/solutions/CareOpsApprove`. It currently
contains only tenant-neutral Power Platform metadata and no runtime components.
Flows, SharePoint connection references, and environment variables must be
harvested from an approved development environment before they are added here.

## Local validation

```powershell
./scripts/Test-SolutionSource.ps1
```

## Pack and unpack

With Microsoft Power Platform CLI or the Microsoft Power Platform GitHub Actions
tooling available:

```powershell
pac solution pack --zipfile out/CareOpsApprove_unmanaged.zip --folder src/solutions/CareOpsApprove --packagetype Both
pac solution unpack --zipfile .\incoming\CareOpsApprove_managed.zip --folder src/solutions/CareOpsApprove --packagetype Both
```

The repository workflow uses `microsoft/powerplatform-actions` to pack the same
folder in CI. Authenticated checker and import steps remain protected deployment
operations and are not run locally with personal credentials.

On the current workstation, the `pac` command is only a stale Scoop shim whose
target `C:\Users\\<user>\\AppData\\Local\\Microsoft\\PowerAppsCLI\\pac.cmd`
is absent. Local structural validation therefore runs now, while the official
Power Platform pack action remains the authoritative package smoke test until
Power Platform CLI is installed through an approved channel.

## Configuration boundary

`config/solution-contract.example.json` is an example contract only. Real
connection IDs, environment URLs, tenant IDs, and deployment settings stay in
protected environment secrets or approved tenant configuration.

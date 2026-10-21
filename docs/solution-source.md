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

The July workstation note about a missing Windows Scoop target is historical.
Use the exact qualified PAC executable/version for the current host; the installed
VS Code route and isolated NuGet CLI are distinct from a stale PATH shim. Current
PAC 2.14.1 exposes preview cloud-flow/action/run inventory, but no cloud-flow run
command. Command availability does not prove authenticated target access.

The pilot deployment workflow runs `Test-SolutionSource.ps1
-RequireRuntimeComponents` before installing tools or invoking checker/import.
The current empty `RootComponents` scaffold is deliberately refused. Ordinary
source validation and offline package smoke tests remain useful, but their green
results do not establish a deployable intake-to-correction implementation.
A nonempty manifest is necessary, not sufficient: source/component parity,
connections, exact-target rights and scoped recovery still require qualification.

## Configuration boundary

`config/solution-contract.example.json` is an example contract only. Real
connection IDs, environment URLs, tenant IDs, and deployment settings stay in
protected environment secrets or approved tenant configuration.

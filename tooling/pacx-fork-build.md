# PACX fork build

The repository uses the Microsoft PAC package for baseline solution operations
and records `edithatogo/pacx` as the optional cloud-flow automation surface.

The manifest pins the reviewed source commit and prefers `net11.0` when the
preview SDK is installed, with a verified `net10.0` fallback. The repeatable
wrapper keeps source and build output under `%LOCALAPPDATA%`:

```powershell
pwsh -File scripts/Install-PacxFork.ps1 -Diagnostics
pwsh -File scripts/Install-PacxFork.ps1 -Version
```

For a workstation with only the pinned .NET 10 SDK, the wrapper builds the
`net10.0` executable from a disposable clone and restores the source clone's
`global.json` unchanged. The equivalent manual commands are:

```powershell
$clone = Join-Path $env:TEMP 'edithatogo-pacx'
git clone --depth 1 --branch master https://github.com/edithatogo/pacx.git $clone
$dotnet = Join-Path $HOME 'scoop/apps/dotnet-sdk/current/dotnet.exe'
& $dotnet restore "$clone/Greg.Xrm.Command/Greg.Xrm.Command/Greg.Xrm.Command.csproj" `
  -p:TargetFramework=net10.0 --ignore-failed-sources
& $dotnet build "$clone/Greg.Xrm.Command/Greg.Xrm.Command/Greg.Xrm.Command.csproj" `
  -f net10.0 --no-restore
```

Authenticate with `pacx auth create` using the approved interactive account.
Never commit PACX profiles, token caches, exported flow packages, or runtime
payloads. The fork's `flow` commands require a Power Automate management-plane
Bearer token; a Dataverse-only token is insufficient.

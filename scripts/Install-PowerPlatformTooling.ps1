[CmdletBinding()]
param(
    [string]$ManifestPath,
    [switch]$SkipRuntimeInstall
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $ManifestPath) { $ManifestPath = Join-Path $root 'tooling\powerplatform-tools.json' }
$manifestPathResolved = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifest = Get-Content -Raw -LiteralPath $manifestPathResolved | ConvertFrom-Json
$toolsDir = Join-Path $HOME '.dotnet/tools'
$sdkRoot = [Environment]::ExpandEnvironmentVariables($manifest.tools.dotnetSdk.installRoot)
$runtimeRoot = [Environment]::ExpandEnvironmentVariables($manifest.tools.dotnetRuntime.installRoot)

function Ensure-Dotnet([string]$Version, [string]$InstallDir, [switch]$RuntimeOnly) {
    if (Test-Path -LiteralPath (Join-Path $InstallDir 'dotnet.exe')) { return }
    if ($SkipRuntimeInstall) { throw "Missing user-local .NET installation at $InstallDir." }
    $installer = Join-Path $env:TEMP 'dotnet-install-careops.ps1'
    Invoke-WebRequest -UseBasicParsing -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile $installer
    $arguments = @('-Version', $Version, '-InstallDir', $InstallDir, '-NoPath')
    if ($RuntimeOnly) { $arguments += @('-Runtime', 'dotnet') }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer @arguments
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $InstallDir 'dotnet.exe'))) { throw "Unable to install .NET $Version." }
}

Ensure-Dotnet $manifest.tools.dotnetSdk.version $sdkRoot
Ensure-Dotnet $manifest.tools.dotnetRuntime.version $runtimeRoot -RuntimeOnly
$env:PATH = "$toolsDir;$sdkRoot;$env:PATH"
& dotnet tool update --global $manifest.tools.pac.package --version $manifest.tools.pac.version --add-source https://api.nuget.org/v3/index.json
if ($LASTEXITCODE -ne 0) { throw 'PAC installation failed.' }
$env:DOTNET_ROOT = $runtimeRoot
$env:PATH = "$toolsDir;$runtimeRoot;$env:PATH"
& dotnet tool update --global $manifest.tools.pacx.package --version $manifest.tools.pacx.version --add-source https://api.nuget.org/v3/index.json
if ($LASTEXITCODE -ne 0) { throw 'PACX installation failed.' }

& (Join-Path $PSScriptRoot 'Test-ToolingManifest.ps1') -ManifestPath $ManifestPath
Write-Output "Installed PAC $($manifest.tools.pac.version) and PACX $($manifest.tools.pacx.version) user-locally."
Write-Output 'Authentication is intentionally manual; run: pac auth create --name careops-owner --deviceCode'

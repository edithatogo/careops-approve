[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root 'tooling\powerplatform-tools.json'
$manifest = Get-Content -Raw -LiteralPath (Resolve-Path -LiteralPath $manifestPath).Path | ConvertFrom-Json
$sdkRoot = [Environment]::ExpandEnvironmentVariables($manifest.tools.dotnetSdk.installRoot)
$pacPath = Join-Path $HOME '.dotnet\tools\pac.exe'
if (-not (Test-Path -LiteralPath (Join-Path $sdkRoot 'dotnet.exe'))) { throw "Pinned .NET SDK is missing: $sdkRoot" }
if (-not (Test-Path -LiteralPath $pacPath)) { throw "PAC is missing: $pacPath. Run scripts/Install-PowerPlatformTooling.ps1." }

$env:DOTNET_ROOT = $sdkRoot
$env:PATH = "$sdkRoot;$HOME\.dotnet\tools;$env:PATH"
& $pacPath @Arguments
exit $LASTEXITCODE

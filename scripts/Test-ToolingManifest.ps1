[CmdletBinding()]
param([string]$ManifestPath)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $ManifestPath) { $ManifestPath = Join-Path $root 'tooling\powerplatform-tools.json' }
$manifestPathResolved = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifest = Get-Content -Raw -LiteralPath $manifestPathResolved | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1) { throw 'Unsupported Power Platform tooling manifest schema.' }
if ($manifest.installMode -ne 'user-local') { throw 'Tooling must use user-local installation.' }
foreach ($name in @('dotnetSdk', 'dotnetRuntime', 'pac', 'pacx')) {
    if (-not $manifest.tools.$name.version) { throw "Tool '$name' has no pinned version." }
}
if ($manifest.tools.pac.package -ne 'Microsoft.PowerApps.CLI.Tool') { throw 'Unexpected PAC package.' }
if ($manifest.tools.pacx.package -ne 'Greg.Xrm.Command') { throw 'Unexpected PACX package.' }
foreach ($property in @('repository', 'branch', 'sourceCommit', 'preferredTargetFramework', 'fallbackTargetFramework', 'buildProject', 'installRoot', 'buildGuide')) {
    if (-not $manifest.tools.pacxFork.$property) { throw "PACX fork manifest field is missing: $property" }
}
if ($manifest.tools.pacxFork.sourceCommit -notmatch '^[0-9a-f]{40}$') { throw 'PACX fork sourceCommit must be a full commit SHA.' }
if ($manifest.authentication.command -notmatch '^pac auth create ') { throw 'Authentication must remain explicit and interactive.' }
if ($manifest.authentication.secretPolicy -notmatch 'never commit') { throw 'Secret policy must forbid committed auth state.' }
Write-Output 'Power Platform tooling manifest validation passed.'

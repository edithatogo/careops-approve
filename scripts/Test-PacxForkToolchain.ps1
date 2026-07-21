[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -Raw -LiteralPath (Join-Path $root 'tooling\powerplatform-tools.json') | ConvertFrom-Json
$scriptPath = Join-Path $root 'scripts\Install-PacxFork.ps1'
$guidePath = Join-Path $root 'tooling\pacx-fork-build.md'
if (-not (Test-Path -LiteralPath $scriptPath)) { throw 'PACX fork installer is missing.' }
if (-not (Test-Path -LiteralPath $guidePath)) { throw 'PACX fork build guide is missing.' }
$fork = $manifest.tools.pacxFork
foreach ($property in @('repository', 'branch', 'sourceCommit', 'preferredTargetFramework', 'fallbackTargetFramework', 'buildProject', 'installRoot', 'buildGuide')) {
    if (-not $fork.$property) { throw "PACX fork manifest field is missing: $property" }
}
if ($fork.sourceCommit -notmatch '^[0-9a-f]{40}$') { throw 'PACX fork sourceCommit is not a full SHA.' }
if ($fork.preferredTargetFramework -ne 'net11.0' -or $fork.fallbackTargetFramework -ne 'net10.0') { throw 'Unexpected PACX target-framework matrix.' }
$script = Get-Content -Raw -LiteralPath $scriptPath
$guide = Get-Content -Raw -LiteralPath $guidePath
foreach ($required in @('credentialFilesCreated = $false', 'liveMutation = $false', 'sourceCommit', 'global.json')) {
    if ($script -notmatch [regex]::Escape($required)) { throw "PACX installer is missing safety marker: $required" }
}
if ($script -match '(?i)pac auth create|client_secret|password\s*=') { throw 'PACX installer must not create auth profiles or embed secrets.' }
if ($guide -notmatch 'temporary|disposable|user-local') { throw 'PACX build guide must document temporary user-local operation.' }
Write-Output 'PACX fork toolchain validation passed.'

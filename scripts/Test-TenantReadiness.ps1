[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$evidence = Get-Content -Raw -LiteralPath (Join-Path $root 'config/tenant-pilot-evidence.example.json') | ConvertFrom-Json
if ($evidence.status -ne 'pending-live-evidence') { throw 'Tenant evidence template must remain pending until sanitized live evidence is approved.' }
if (@($evidence.controls).Count -ne 4) { throw 'Tenant evidence template must cover four live controls.' }
foreach ($control in $evidence.controls) {
    if (-not $control.id -or @($control.requiredEvidence).Count -eq 0) { throw 'Every tenant control requires an evidence checklist.' }
}
$pacLauncher = Join-Path $root 'scripts/Invoke-Pac.ps1'
if (-not (Test-Path -LiteralPath $pacLauncher -PathType Leaf)) { throw 'PAC launcher is missing.' }
Write-Output 'Tenant readiness template validation passed; live evidence remains pending.'

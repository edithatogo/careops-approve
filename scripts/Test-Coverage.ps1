[CmdletBinding()]
param([string]$MatrixPath)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $MatrixPath) { $MatrixPath = Join-Path $root 'harness\coverage-matrix.json' }
$matrixPathResolved = (Resolve-Path -LiteralPath $MatrixPath).Path
$matrix = Get-Content -Raw -LiteralPath $matrixPathResolved | ConvertFrom-Json
$ids = @($matrix.controls | ForEach-Object id)
if ($ids.Count -ne (@($ids | Sort-Object -Unique).Count)) { throw 'Coverage matrix contains duplicate control IDs.' }
foreach ($control in $matrix.controls) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $control.test))) { throw "Coverage test path is missing: $($control.test)" }
}
$repoControls = @($matrix.controls | Where-Object { $_.scope -eq 'repo' })
$covered = @($repoControls | Where-Object { $_.covered -ne $false })
$coverage = if ($repoControls.Count) { $covered.Count / $repoControls.Count } else { 0 }
$tenantControls = @($matrix.controls | Where-Object { $_.scope -eq 'tenant' })
Write-Output ("Repository control coverage: {0:P0} ({1}/{2}); threshold: {3:P0}" -f $coverage, $covered.Count, $repoControls.Count, $matrix.threshold)
Write-Output ("Tenant controls requiring live evidence: {0}; outstanding: {1}" -f $tenantControls.Count, @($tenantControls | Where-Object { $_.covered -eq $false }).Count)
if ($coverage -lt [double]$matrix.threshold) { throw 'Repository control coverage is below the configured threshold.' }
Write-Output 'Coverage matrix validation passed.'

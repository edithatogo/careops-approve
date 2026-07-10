[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'config/decision-scenarios.example.json'
$model = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json

foreach ($case in $model.scenarios) {
    if ($case.existingOutcome) {
        $actual = 'retain-existing'
    } elseif ($case.outcome -eq 'Rejected' -and [string]::IsNullOrWhiteSpace($case.comment)) {
        $actual = 'needs-comment'
    } elseif ($case.outcome -eq 'Failed') {
        $actual = 'finalized-and-alert-owner'
    } elseif ($case.outcome -in @('Approved', 'Rejected', 'Cancelled')) {
        $actual = 'finalized'
    } else {
        $actual = 'invalid'
    }
    if ($actual -ne $case.expected) { throw "Decision scenario failed: $($case.name); expected '$($case.expected)', got '$actual'." }
}

Write-Output 'Decision scenario validation passed.'

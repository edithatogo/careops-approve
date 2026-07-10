[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'config/administration-scenarios.example.json'
$model = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json

foreach ($case in $model.scenarios) {
    if ($case.actor -ne 'owner') {
        $actual = 'forbidden'
    } elseif ($case.existingAssignment) {
        $actual = 'retain-existing'
    } elseif ($case.operation -in @('replace', 'reorder')) {
        $actual = 'new-submissions-only'
    } elseif ($case.operation -eq 'deactivate') {
        $actual = 'allowed-if-valid-successor'
    } else {
        $actual = 'allowed'
    }
    if ($actual -ne $case.expected) { throw "Administration scenario failed: $($case.name); expected '$($case.expected)', got '$actual'." }
}

Write-Output 'Administration scenario validation passed.'

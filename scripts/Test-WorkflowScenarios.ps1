[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$scenarioPath = Join-Path $root 'config/workflow-scenarios.example.json'
$scenarios = Get-Content -Raw -LiteralPath $scenarioPath | ConvertFrom-Json

function Assert([bool]$condition, [string]$message) {
    if (-not $condition) { throw $message }
}

foreach ($case in $scenarios.submissionScenarios) {
    $accepted = -not [string]::IsNullOrWhiteSpace($case.title) -and -not [string]::IsNullOrWhiteSpace($case.description)
    Assert ($accepted -eq ($case.expected -eq 'accepted')) "Submission scenario failed: $($case.name)"
    if ($accepted -and $case.expectedStatus) { Assert ($case.expectedStatus -eq 'Submitted') "Accepted submissions must start Submitted: $($case.name)" }
}

foreach ($case in $scenarios.routingScenarios) {
    if ($case.duplicateActive -or ([string]::IsNullOrWhiteSpace($case.primary) -and [string]::IsNullOrWhiteSpace($case.fallback))) {
        $resolved = 'configuration-error'
    } elseif ($case.primaryStatus -eq 'Active') {
        $resolved = $case.primary
    } elseif (-not [string]::IsNullOrWhiteSpace($case.fallback)) {
        $resolved = $case.fallback
    } else {
        $resolved = 'configuration-error'
    }
    Assert ($resolved -eq $case.expected) "Routing scenario failed: $($case.name)"
}

Write-Output 'Workflow scenario validation passed.'

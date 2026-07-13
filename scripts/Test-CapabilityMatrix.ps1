[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$matrixPath = Join-Path $root 'docs/capability-matrix.md'
$matrix = Get-Content -Raw -LiteralPath $matrixPath

$requiredTracks = @(
    'live_flow_reconciliation_20260713',
    'template_catalog_routing_20260713',
    'business_calendar_absence_routing_20260713',
    'submission_quality_evidence_20260713',
    'operational_reconciliation_20260713',
    'privacy_retention_accessibility_20260713',
    'planner_task_sync_20260713',
    'service_metrics_capacity_20260713',
    'requester_status_feedback_20260713'
)

foreach ($trackId in $requiredTracks) {
    if ($matrix -notmatch [regex]::Escape($trackId)) { throw "Capability matrix is missing track: $trackId" }
    foreach ($file in @('index.md', 'spec.md', 'plan.md', 'metadata.json')) {
        $path = Join-Path $root "conductor/tracks/$trackId/$file"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing track artifact: $path" }
    }
}

foreach ($boundary in @('Entra application registration', 'Custom Teams app', 'Managed Power Platform Pipelines host', 'Tenant DLP')) {
    if ($matrix -notmatch [regex]::Escape($boundary)) { throw "Capability matrix is missing authority boundary: $boundary" }
}

if ($matrix -match '[A-Za-z0-9._%+-]+@health\.nsw\.gov\.au') {
    throw 'Capability matrix must not contain tenant UPNs.'
}

Write-Output 'Capability matrix validation passed.'

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$required = @(
    'config/approver-resolution.example.json',
    'docs/tenant-handoff-runbook.md',
    'docs/pilot-test-matrix.md',
    'flows/submit-and-route.contract.json',
    'config/decision-scenarios.example.json',
    'config/administration-scenarios.example.json'
)
foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $path) -PathType Leaf)) { throw "Missing handoff artifact: $path" }
}
$resolution = Get-Content -Raw -LiteralPath (Join-Path $root 'config/approver-resolution.example.json') | ConvertFrom-Json
if ($resolution.tenantConfiguration -notmatch 'excluded from source control') { throw 'Approver resolution contract must exclude tenant configuration.' }
$flow = Get-Content -Raw -LiteralPath (Join-Path $root 'flows/submit-and-route.contract.json') | ConvertFrom-Json
if (($flow.steps | Where-Object id -eq 'create-approval').sendEmailNotification) { throw 'Handoff flow must suppress approval email.' }
if (-not ($flow.steps | Where-Object id -eq 'persist-immutable-assignment')) { throw 'Immutable assignment step is missing.' }
Write-Output 'Tenant handoff package validation passed.'

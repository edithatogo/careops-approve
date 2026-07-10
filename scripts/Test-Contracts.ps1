[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contracts = Join-Path $root 'contracts'

function Read-Json([string]$path) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing contract file: $path" }
    try { return (Get-Content -Raw -LiteralPath $path | ConvertFrom-Json) }
    catch { throw "Invalid JSON in $path`: $($_.Exception.Message)" }
}

$schemas = @{
    request = Read-Json (Join-Path $contracts 'request.schema.json')
    decision = Read-Json (Join-Path $contracts 'decision.schema.json')
    approver = Read-Json (Join-Path $contracts 'approver-configuration.schema.json')
}

foreach ($schema in $schemas.GetEnumerator()) {
    if ($schema.Value.'$schema' -ne 'https://json-schema.org/draft/2020-12/schema') { throw "Unexpected schema dialect for $($schema.Key)." }
    if (-not $schema.Value.required -or $schema.Value.required.Count -lt 1) { throw "Schema $($schema.Key) has no required fields." }
    if ($schema.Value.additionalProperties -ne $false) { throw "Schema $($schema.Key) must reject undeclared fields." }
}

$request = Read-Json (Join-Path $contracts 'fixtures/request.valid.json')
$decision = Read-Json (Join-Path $contracts 'fixtures/decision.valid.json')
$approver = Read-Json (Join-Path $contracts 'fixtures/approver-configuration.valid.json')

if ($request.status -ne 'Submitted') { throw 'The request fixture must start in Submitted status.' }
if ([string]::IsNullOrWhiteSpace($request.requestId) -or [string]::IsNullOrWhiteSpace($request.assignedApprover.email)) { throw 'The request fixture must contain an ID and assigned approver.' }
if ($decision.outcome -eq 'Rejected' -and [string]::IsNullOrWhiteSpace($decision.comment)) { throw 'Rejected decisions require a comment.' }
if ($approver.status -ne 'Active' -or [string]::IsNullOrWhiteSpace($approver.primaryApprover.email)) { throw 'The approver fixture must contain an active primary approver.' }

Write-Output 'Contract validation passed.'

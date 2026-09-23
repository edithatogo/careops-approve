[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Read-Json([string]$path) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing API contract: $path"
    }
    try {
        return (Get-Content -Raw -LiteralPath $path | ConvertFrom-Json)
    }
    catch {
        throw "Invalid JSON in $path`: $($_.Exception.Message)"
    }
}

$contracts = Join-Path $root 'contracts'
$pairs = @(
    @('case.schema.json', 'fixtures/case.valid.json'),
    @('task.schema.json', 'fixtures/task.valid.json'),
    @('workflow-event.schema.json', 'fixtures/workflow-event.valid.json'),
    @('workflow-version-record.schema.json', 'fixtures/workflow-version-record.valid.json')
)

foreach ($pair in $pairs) {
    $schemaPath = Join-Path $contracts $pair[0]
    $fixturePath = Join-Path $contracts $pair[1]
    $schema = Read-Json $schemaPath
    $null = Read-Json $fixturePath
    if ($schema.'$schema' -ne 'https://json-schema.org/draft/2020-12/schema') {
        throw "Unexpected JSON Schema dialect in $($pair[0])."
    }
    if ($schema.additionalProperties -ne $false) {
        throw "$($pair[0]) must reject undeclared top-level fields."
    }
    $fixtureRaw = Get-Content -Raw -LiteralPath $fixturePath
    if (-not (Test-Json -Json $fixtureRaw -SchemaFile $schemaPath -ErrorAction Stop)) {
        throw "$($pair[1]) does not validate against $($pair[0])."
    }
}

$apiPath = Join-Path $contracts 'careops-api.v1.openapi.json'
$api = Read-Json $apiPath
if ($api.openapi -ne '3.1.0' -or $api.info.version -ne '1.0.0') {
    throw 'CareOps API contract must declare OpenAPI 3.1.0 and API version 1.0.0.'
}
$requiredPaths = @(
    '/api/v1/cases',
    '/api/v1/cases/{caseId}',
    '/api/v1/tasks/{taskId}/actions',
    '/api/v1/cases/{caseId}/events',
    '/api/v1/workflow-studio/node-types',
    '/api/v1/workflows/{workflowId}/versions/{version}',
    '/api/v1/workflows/{workflowId}/versions',
    '/api/v1/workflows/{workflowId}/versions/{version}/validate',
    '/api/v1/workflows/{workflowId}/versions/{version}/publication-requests'
)
foreach ($path in $requiredPaths) {
    if (-not $api.paths.PSObject.Properties.Name.Contains($path)) {
        throw "CareOps API is missing required path '$path'."
    }
}

$serialized = $api | ConvertTo-Json -Depth 100
foreach ($reference in @(
    './case.schema.json',
    './workflow-event.schema.json',
    './workflow-definition.schema.json',
    './workflow-editor-catalog.schema.json',
    './workflow-publication.schema.json',
    './workflow-version-record.schema.json'
)) {
    if ($serialized -notmatch [regex]::Escape($reference)) {
        throw "CareOps API must reference contract '$reference'."
    }
}

Write-Output 'Workflow API contract validation passed.'

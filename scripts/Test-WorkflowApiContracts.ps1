[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contracts = Join-Path $root 'contracts'

function Read-Json([string]$path) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing API contract: $path"
    }
    try {
        return (Get-Content -Raw -LiteralPath $path | ConvertFrom-Json)
    }
    catch {
        throw ("Invalid JSON in {0}: {1}" -f $path, $_.Exception.Message)
    }
}

$pairs = @(
    @('case.schema.json', 'fixtures/case.valid.json'),
    @('task.schema.json', 'fixtures/task.valid.json'),
    @('workflow-event.schema.json', 'fixtures/workflow-event.valid.json'),
    @('workflow-validation-result.schema.json', 'fixtures/workflow-validation-result.valid.json')
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

$versionRecordSchemaPath = Join-Path $contracts 'workflow-version-record.schema.json'
$versionRecordFixturePath = Join-Path $contracts 'fixtures/workflow-version-record.valid.json'
$versionRecordSchema = Read-Json $versionRecordSchemaPath
$versionRecord = Read-Json $versionRecordFixturePath

if ($versionRecordSchema.'$schema' -ne 'https://json-schema.org/draft/2020-12/schema' -or
    $versionRecordSchema.additionalProperties -ne $false) {
    throw 'Workflow version record schema must use draft 2020-12 and fail closed.'
}
if ($versionRecordSchema.properties.definition.'$ref' -ne './workflow-definition.schema.json') {
    throw 'Workflow version record must reference the canonical workflow definition schema.'
}
foreach ($required in @('workflowId','version','state','definitionHash','etag','revision','definition')) {
    if (@($versionRecordSchema.required) -notcontains $required) {
        throw "Workflow version record schema is missing required field '$required'."
    }
    if (-not $versionRecord.PSObject.Properties.Name.Contains($required)) {
        throw "Workflow version record fixture is missing '$required'."
    }
}
if ($versionRecord.state -notin @('draft','active','retired')) {
    throw 'Workflow version record fixture has an invalid state.'
}
if ($versionRecord.definitionHash -notmatch '^sha256:[0-9a-f]{64}$') {
    throw 'Workflow version record fixture has an invalid definition hash.'
}
if ($versionRecord.etag -notmatch '^"[1-9][0-9]*-[0-9a-f]{16}"$') {
    throw 'Workflow version record fixture has an invalid ETag.'
}
if ([int]$versionRecord.revision -lt 1) {
    throw 'Workflow version record fixture revision must be positive.'
}

$workflowDefinitionSchemaPath = Join-Path $contracts 'workflow-definition.schema.json'
$definitionRaw = $versionRecord.definition | ConvertTo-Json -Depth 100 -Compress
if (-not (Test-Json -Json $definitionRaw -SchemaFile $workflowDefinitionSchemaPath -ErrorAction Stop)) {
    throw 'Workflow version record nested definition does not validate against workflow-definition.schema.json.'
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
    './workflow-version-record.schema.json',
    './workflow-validation-result.schema.json'
)) {
    if ($serialized -notmatch [regex]::Escape($reference)) {
        throw "CareOps API must reference contract '$reference'."
    }
}

$versionPath = $api.paths.'/api/v1/workflows/{workflowId}/versions/{version}'
$ifMatch = @($versionPath.put.parameters | Where-Object {
    $_.name -eq 'If-Match' -and $_.in -eq 'header'
})
if ($ifMatch.Count -ne 1) {
    throw 'Draft update API must expose exactly one If-Match header.'
}
if (-not $versionPath.get.responses.'200'.content.'application/json'.schema.'$ref') {
    throw 'Workflow version read API must return the version-record contract.'
}

$validatePath = $api.paths.'/api/v1/workflows/{workflowId}/versions/{version}/validate'
if ($validatePath.post.responses.'200'.content.'application/json'.schema.'$ref' -ne
    './workflow-validation-result.schema.json') {
    throw 'Workflow validation API must return the structured validation-result contract.'
}

Write-Output 'Workflow API contract validation passed.'

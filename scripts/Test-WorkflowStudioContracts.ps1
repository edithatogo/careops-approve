[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Read-Json([string]$path) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing Workflow Studio artifact: $path"
    }
    try {
        return (Get-Content -Raw -LiteralPath $path | ConvertFrom-Json)
    }
    catch {
        throw "Invalid JSON in $path`: $($_.Exception.Message)"
    }
}

$catalogSchemaPath = Join-Path $root 'contracts/workflow-editor-catalog.schema.json'
$catalogPath = Join-Path $root 'config/workflow-editor-catalog.example.json'
$publicationSchemaPath = Join-Path $root 'contracts/workflow-publication.schema.json'
$publicationFixturePath = Join-Path $root 'contracts/fixtures/workflow-publication.valid.json'

$catalogSchema = Read-Json $catalogSchemaPath
$catalog = Read-Json $catalogPath
$publicationSchema = Read-Json $publicationSchemaPath
$publication = Read-Json $publicationFixturePath

foreach ($schema in @($catalogSchema, $publicationSchema)) {
    if ($schema.'$schema' -ne 'https://json-schema.org/draft/2020-12/schema') {
        throw 'Workflow Studio contracts must use JSON Schema draft 2020-12.'
    }
    if ($schema.additionalProperties -ne $false) {
        throw 'Workflow Studio top-level contracts must reject undeclared fields.'
    }
}

if (-not (Test-Json -Json (Get-Content -Raw -LiteralPath $catalogPath) -SchemaFile $catalogSchemaPath -ErrorAction Stop)) {
    throw 'Workflow editor catalogue does not validate against its schema.'
}
if (-not (Test-Json -Json (Get-Content -Raw -LiteralPath $publicationFixturePath) -SchemaFile $publicationSchemaPath -ErrorAction Stop)) {
    throw 'Workflow publication fixture does not validate against its schema.'
}

$expectedNodeTypes = @(
    'input','deterministic_check','agent','human_review','approval','condition',
    'parallel','join','wait','notification','api_call','handoff','end'
)
$nodeTypes = @($catalog.nodeTypes | ForEach-Object { [string]$_.type })
if ($nodeTypes.Count -ne (@($nodeTypes | Sort-Object -Unique)).Count) {
    throw 'Workflow editor catalogue contains duplicate node types.'
}
foreach ($type in $expectedNodeTypes) {
    if ($nodeTypes -notcontains $type) {
        throw "Workflow editor catalogue is missing node type '$type'."
    }
}

$agent = @($catalog.nodeTypes | Where-Object { $_.type -eq 'agent' })
if ($agent.Count -ne 1) {
    throw 'Workflow editor catalogue requires exactly one agent node definition.'
}
$agentFields = @{}
foreach ($field in @($agent[0].fields)) {
    $agentFields[[string]$field.key] = $field
}
foreach ($required in @('agentId','agentVersion','humanReviewRequired','failureMode')) {
    if (-not $agentFields.ContainsKey($required)) {
        throw "Agent editor is missing governed field '$required'."
    }
}
if ($agentFields['agentId'].control -ne 'agent-picker' -or $agentFields['agentId'].governanceClass -ne 'agent') {
    throw 'Agent identity must be selected from the approved agent registry.'
}
if (@($agentFields['failureMode'].options) -notcontains 'ordinary-human-path') {
    throw 'Agent editor must expose the ordinary human fallback.'
}
if (@($agentFields['failureMode'].options).Count -ne 1) {
    throw 'Agent editor must not expose unsafe fallback options.'
}

foreach ($type in @('human_review','approval')) {
    $node = @($catalog.nodeTypes | Where-Object { $_.type -eq $type })
    if ($node.Count -ne 1) {
        throw "Workflow editor catalogue requires exactly one '$type' definition."
    }
    $roleFields = @($node[0].fields | Where-Object { $_.key -eq 'assignedRole' })
    if ($roleFields.Count -ne 1 -or $roleFields[0].control -ne 'role-picker' -or $roleFields[0].governanceClass -ne 'authority') {
        throw "'$type' must use a governed role picker."
    }
    if (@($node[0].configurableBy) -contains 'process-owner') {
        throw "Process owners cannot independently change authority-bearing '$type' configuration."
    }
}

foreach ($type in @('api_call','handoff')) {
    $node = @($catalog.nodeTypes | Where-Object { $_.type -eq $type })
    if (@($node[0].configurableBy) -notcontains 'integration-admin') {
        throw "'$type' configuration requires integration administrator authority."
    }
}

if ($publication.validationStatus -ne 'passed' -or $publication.testStatus -ne 'passed') {
    throw 'A publication request must carry passed validation and test evidence.'
}
if ([string]::IsNullOrWhiteSpace($publication.definitionHash) -or $publication.definitionHash -notmatch '^sha256:') {
    throw 'A publication request must bind to an immutable definition hash.'
}
if ($publication.migrationPolicy -notin @('no-running-case-migration','explicit-reviewed-migration')) {
    throw 'A publication request requires an explicit running-case migration policy.'
}

Write-Output 'Workflow Studio contract validation passed.'

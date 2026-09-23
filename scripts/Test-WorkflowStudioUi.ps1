[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$uiRoot = Join-Path $root 'pilot/workflow-studio'

$required = @(
    'index.html',
    'styles.css',
    'app.js',
    'README.md',
    'sample.workflow.json'
)
foreach ($file in $required) {
    $path = Join-Path $uiRoot $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Workflow Studio UI is missing '$file'."
    }
}

$html = Get-Content -Raw -LiteralPath (Join-Path $uiRoot 'index.html')
$js = Get-Content -Raw -LiteralPath (Join-Path $uiRoot 'app.js')

foreach ($id in @(
    'palette','workflowId','workflowVersion','workflowName','ownerRole',
    'entryNode','classification','nodes','transitions','validation',
    'jsonOutput','apiBase','loadApi','saveApi','validateApi','apiStatus'
)) {
    if ($html -notmatch ('id="' + [regex]::Escape($id) + '"')) {
        throw "Workflow Studio HTML is missing required control '$id'."
    }
}

if ($html -match '(?i)<script[^>]+src="https?://' -or
    $html -match '(?i)<link[^>]+href="https?://') {
    throw 'Workflow Studio must not depend on remote scripts or styles.'
}
if ($html -notmatch 'src="app.js"' -or $html -notmatch 'href="styles.css"') {
    throw 'Workflow Studio must use repository-local JavaScript and CSS.'
}

foreach ($token in @(
    '../../config/workflow-editor-catalog.example.json',
    'meta.availability !== "supported"',
    'humanReviewRequired',
    'ordinary-human-path',
    'Cycles are not supported',
    'If-Match',
    'method: "PUT"',
    'method: "PUT"',
    '/api/v1/workflows/',
    'state.workflow.status = "draft"',
    'validationUrl()',
    'method: "POST"',
    'Server validation:',
    'result.definitionHash'
)) {
    if ($js -notmatch [regex]::Escape($token)) {
        throw "Workflow Studio JavaScript is missing safety/integration token '$token'."
    }
}
if ($js -match '/publication-requests' -or $js -match 'requestedAction') {
    throw 'Reference Workflow Studio must not publish or retire workflow versions.'
}

$samplePath = Join-Path $uiRoot 'sample.workflow.json'
$schemaPath = Join-Path $root 'contracts/workflow-definition.schema.json'
$sample = Get-Content -Raw -LiteralPath $samplePath
if (-not (Test-Json -Json $sample -SchemaFile $schemaPath -ErrorAction Stop)) {
    throw 'Workflow Studio sample does not validate against workflow-definition.schema.json.'
}

$sampleObject = $sample | ConvertFrom-Json
if ($sampleObject.status -ne 'draft') {
    throw 'Workflow Studio sample must remain a draft.'
}

$catalog = Get-Content -Raw -LiteralPath (Join-Path $root 'config/workflow-editor-catalog.example.json') |
    ConvertFrom-Json
$supported = @($catalog.nodeTypes | Where-Object { $_.availability -eq 'supported' } | ForEach-Object { $_.type })
foreach ($node in @($sampleObject.nodes)) {
    if ($supported -notcontains $node.type) {
        throw "Workflow Studio sample uses unsupported node type '$($node.type)'."
    }
}

Write-Output 'Workflow Studio UI source validation passed.'

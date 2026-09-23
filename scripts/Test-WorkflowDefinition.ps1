[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Read-Json([string]$path) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing workflow artifact: $path"
    }
    try {
        return (Get-Content -Raw -LiteralPath $path | ConvertFrom-Json)
    }
    catch {
        throw "Invalid JSON in $path`: $($_.Exception.Message)"
    }
}

$schema = Read-Json (Join-Path $root 'contracts/workflow-definition.schema.json')
$fixture = Read-Json (Join-Path $root 'contracts/fixtures/workflow-definition.valid.json')
$registry = Read-Json (Join-Path $root 'config/agent-registry.example.json')

if ($schema.'$schema' -ne 'https://json-schema.org/draft/2020-12/schema') {
    throw 'Workflow definition must use JSON Schema draft 2020-12.'
}
if ($schema.additionalProperties -ne $false) {
    throw 'Workflow definition top level must reject undeclared fields.'
}
if (-not $schema.required -or $schema.required.Count -lt 6) {
    throw 'Workflow definition schema must declare its required envelope.'
}

$nodeIds = @($fixture.nodes | ForEach-Object { [string]$_.id })
$uniqueNodeIds = @($nodeIds | Sort-Object -Unique)
if ($nodeIds.Count -ne $uniqueNodeIds.Count) {
    throw 'Workflow fixture contains duplicate node IDs.'
}
if ($nodeIds -notcontains [string]$fixture.entryNodeId) {
    throw 'Workflow entryNodeId must reference an existing node.'
}

foreach ($transition in @($fixture.transitions)) {
    if ($nodeIds -notcontains [string]$transition.from) {
        throw "Transition references missing source node '$($transition.from)'."
    }
    if ($nodeIds -notcontains [string]$transition.to) {
        throw "Transition references missing target node '$($transition.to)'."
    }
}

$endNodes = @($fixture.nodes | Where-Object { $_.type -eq 'end' })
if ($endNodes.Count -lt 1) {
    throw 'Workflow fixture requires at least one terminal end node.'
}

$agents = @($registry.agents)
if ($agents.Count -lt 1) {
    throw 'Agent registry must contain at least one example agent.'
}

$agentKeys = @{}
foreach ($agent in $agents) {
    if ($agent.humanReviewRequired -ne $true) {
        throw "Agent '$($agent.agentId)' must preserve human review."
    }
    foreach ($prohibited in @('approve','reject','assign-authority','determine-competence','restrict-scope','write-authoritative-register')) {
        if (@($agent.prohibitedCapabilities) -notcontains $prohibited) {
            throw "Agent '$($agent.agentId)' is missing prohibited capability '$prohibited'."
        }
    }
    $agentKeys["$($agent.agentId)@$($agent.version)"] = $true
}

foreach ($node in @($fixture.nodes | Where-Object { $_.type -eq 'agent' })) {
    $key = "$($node.config.agentId)@$($node.config.agentVersion)"
    if (-not $agentKeys.ContainsKey($key)) {
        throw "Workflow references unregistered agent '$key'."
    }
    if ($node.config.humanReviewRequired -ne $true) {
        throw "Workflow agent node '$($node.id)' must require human review."
    }
    if ($node.config.failureMode -ne 'ordinary-human-path') {
        throw "Workflow agent node '$($node.id)' must preserve the ordinary human path."
    }
}

Write-Output 'Workflow definition validation passed.'

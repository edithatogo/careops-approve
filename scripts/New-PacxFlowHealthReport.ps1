[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$InventoryPath,
    [string]$ConfigPath,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $ConfigPath) { $ConfigPath = Join-Path $root 'config\pacx-flow-health.example.json' }
$config = Get-Content -Raw -LiteralPath (Resolve-Path -LiteralPath $ConfigPath).Path | ConvertFrom-Json
$inventory = Get-Content -Raw -LiteralPath (Resolve-Path -LiteralPath $InventoryPath).Path | ConvertFrom-Json
if ($config.schemaVersion -ne 1 -or $inventory.schemaVersion -ne 1) { throw 'Unsupported PACX flow-health schema.' }
if ($config.reportMode -ne 'read-only') { throw 'Flow-health reports must be read-only.' }
if (-not $inventory.PSObject.Properties.Name.Contains('flows')) { throw 'Flow-health inventory must contain a flows collection.' }

$allowedProperties = @('name', 'state', 'definitionStatus', 'recentRunEvidence', 'connectionStatus', 'corruptionWarning')
$forbiddenPattern = '(?i)(token|secret|password|environmentid|connectionreference|payload|upn|email|url)'
$mappings = @{}
foreach ($mapping in @($config.sourceMappings)) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $mapping.sourceContract))) { throw "Source contract mapping is missing: $($mapping.sourceContract)" }
    $mappings[$mapping.flowName] = $mapping.sourceContract
}
$names = @($inventory.flows | ForEach-Object name)
$duplicateNames = @($names | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
$rows = @()

foreach ($flow in @($inventory.flows)) {
    $properties = @($flow.PSObject.Properties.Name)
    $unexpected = @($properties | Where-Object { $_ -notin $allowedProperties })
    if ($unexpected.Count -gt 0 -or ($properties | Where-Object { $_ -match $forbiddenPattern })) { throw "Inventory contains forbidden or unexpected fields for flow '$($flow.name)'." }
    if ($flow.state -notin $config.allowedStates -or $flow.definitionStatus -notin $config.allowedDefinitionStatuses -or $flow.recentRunEvidence -notin $config.allowedRunEvidence -or $flow.connectionStatus -notin $config.allowedConnectionStatuses) { throw "Inventory contains an unsupported status for flow '$($flow.name)'." }
    $health = if ($flow.name -in $duplicateNames) { 'duplicate' }
        elseif ($flow.corruptionWarning) { 'corruption-warning' }
        elseif (-not $mappings.ContainsKey($flow.name)) { 'unknown-flow' }
        elseif ($flow.definitionStatus -eq 'malformed') { 'malformed-definition' }
        elseif ($flow.definitionStatus -ne 'found') { 'definition-missing' }
        elseif ($flow.state -eq 'draft') { 'draft-review' }
        elseif ($flow.connectionStatus -eq 'unresolved') { 'connection-unresolved' }
        elseif ($flow.recentRunEvidence -ne 'observed') { 'run-evidence-missing' }
        else { 'healthy' }
    $rows += [pscustomobject]@{
        name = $flow.name
        sourceContract = if ($mappings.ContainsKey($flow.name)) { $mappings[$flow.name] } else { $null }
        state = $flow.state
        definitionStatus = $flow.definitionStatus
        recentRunEvidence = $flow.recentRunEvidence
        connectionStatus = $flow.connectionStatus
        duplicate = $flow.name -in $duplicateNames
        corruptionWarning = [bool]$flow.corruptionWarning
        health = $health
        mutationAllowed = $false
    }
}

$report = [pscustomobject]@{
    schemaVersion = 1
    reportMode = 'read-only'
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    counts = [pscustomobject]@{ total = $rows.Count; healthy = @($rows | Where-Object health -eq 'healthy').Count; reviewRequired = @($rows | Where-Object health -ne 'healthy').Count }
    flows = $rows
}
$json = $report | ConvertTo-Json -Depth 8
if ($OutputPath) { Set-Content -LiteralPath $OutputPath -Value $json -Encoding utf8 } else { Write-Output $json }

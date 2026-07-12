[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root 'config/integration-roadmap.example.json') | ConvertFrom-Json
$requiredRules = @('native-teams-approval-remains-authoritative', 'no-autonomous-ai-decision', 'no-outbound-email', 'no-silent-in-flight-reassignment', 'no-tenant-secrets-or-identifiers-in-source')
foreach ($rule in $requiredRules) { if ($config.safetyRules -notcontains $rule) { throw "Missing integration safety rule: $rule" } }
if ($config.decisionAuthority -ne 'native-teams-approval') { throw 'Integration roadmap must preserve native Teams approval authority.' }
$trackIds = @($config.capabilities | ForEach-Object trackId)
if ($trackIds.Count -ne (@($trackIds | Sort-Object -Unique).Count)) { throw 'Integration roadmap contains duplicate track IDs.' }
foreach ($capability in $config.capabilities) {
    if (-not $capability.trackId -or -not $capability.name -or -not $capability.test -or -not $capability.liveGate) { throw 'Every integration capability requires identity, test, and live gate.' }
    foreach ($artifact in $capability.sourceArtifacts) { if (-not (Test-Path -LiteralPath (Join-Path $root $artifact) -PathType Leaf)) { throw "Missing integration artifact: $artifact" } }
    if (-not (Test-Path -LiteralPath (Join-Path $root $capability.test) -PathType Leaf)) { throw "Missing integration test: $($capability.test)" }
}
$dataverse = Get-Content -Raw -LiteralPath (Join-Path $root 'config/dataverse-review-surface.example.json') | ConvertFrom-Json
if ($dataverse.notAuthoritativeFor -notcontains 'approval decision') { throw 'Dataverse must not be authoritative for approval decisions.' }
if ($dataverse.fieldBoundary.excluded -notcontains 'rawEmailBody') { throw 'Dataverse boundary must exclude raw email body.' }
Write-Output ("Integration roadmap validation passed: {0} capabilities; all have source, test, and tenant gate." -f $config.capabilities.Count)

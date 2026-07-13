$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contract = Get-Content (Join-Path $root 'config/dataverse-review-surface.example.json') -Raw | ConvertFrom-Json
$fixtures = Get-Content (Join-Path $root 'config/dataverse-review-surface-fixtures.example.json') -Raw | ConvertFrom-Json
if ($contract.notAuthoritativeFor -notcontains 'approval decision' -or $contract.fallback -notmatch 'SharePoint') { throw 'Dataverse authority boundary or fallback missing.' }
foreach ($field in @('rawEmailBody','credentials','connectionReferences','tenantIdentifiers')) { if ($contract.fieldBoundary.excluded -notcontains $field) { throw "Excluded field missing: $field" } }
foreach ($scenario in @($fixtures.scenarios)) {
  $actual = if ($scenario.operation -in @('change-approval-outcome','read-raw-email')) {'deny'} else {'allow'}
  if ($actual -ne $scenario.expected) { throw "Scenario $($scenario.name) mismatch." }
}
Write-Output "Dataverse review surface validation passed: $(@($fixtures.scenarios).Count) scenarios."

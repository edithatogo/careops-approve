$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contract = Get-Content (Join-Path $root 'config/submission-quality.example.json') -Raw | ConvertFrom-Json
$fixtures = Get-Content (Join-Path $root 'config/submission-quality-fixtures.example.json') -Raw | ConvertFrom-Json
if ($contract.evidenceLinks.copyContent -or $contract.aiFailureAction -ne 'continue-deterministic-human-review') { throw 'Unsafe evidence or AI failure policy.' }
function Get-Quality($record) {
  foreach ($field in @($contract.requiredFields)) { if ([string]::IsNullOrWhiteSpace([string]$record.$field)) { return 'block' } }
  if ([string]$record.requesterEmail -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { return 'block' }
  if ($record.classification -and @($contract.classification.blocked) -contains $record.classification) { return 'block' }
  if ($record.evidenceUrl -and $record.evidenceUrl -notmatch '^https://tenant-configured-(sharepoint|intranet)/') { return 'block' }
  if ([string]$record.description -eq 'Short') { return 'warn' }
  return 'pass'
}
foreach ($scenario in @($fixtures.scenarios)) { if ((Get-Quality $scenario.input) -ne $scenario.expected) { throw "Scenario $($scenario.name) mismatch." } }
Write-Output "Submission quality validation passed: $(@($fixtures.scenarios).Count) scenarios."

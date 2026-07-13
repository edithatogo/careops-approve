$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contract = Get-Content (Join-Path $root 'config/reconciliation.example.json') -Raw | ConvertFrom-Json
$fixtures = Get-Content (Join-Path $root 'config/reconciliation-fixtures.example.json') -Raw | ConvertFrom-Json
if ($contract.mode -ne 'read-only-by-default' -or -not $contract.repairPolicy.requiresIndividualOwnerApproval) { throw 'Reconciliation must be read-only by default and require individual owner approval.' }
if ($contract.forbiddenRepairs -notcontains 'overwrite-final-decision' -or $contract.forbiddenRepairs -notcontains 'auto-approve') { throw 'Forbidden final-decision repairs are incomplete.' }
function Get-State($scenario) {
  if ($scenario.replay) { return 'duplicate-replay' }
  if ($null -eq $scenario.request) { return 'missing-state' }
  if ($null -eq $scenario.approval) { return 'missing-approval' }
  if ($scenario.request.state -eq 'Pending' -and $scenario.approval.outcome -eq 'Pending') { return 'stale-pending' }
  if ($scenario.request.state -eq 'Approved' -and $scenario.approval.outcome -eq 'Reject') { return 'conflicting-final' }
  return 'consistent'
}
foreach ($scenario in @($fixtures.scenarios)) { if ((Get-State $scenario) -ne $scenario.expected) { throw "Scenario $($scenario.name) mismatch." } }
Write-Output "Reconciliation validation passed: $(@($fixtures.scenarios).Count) scenarios."

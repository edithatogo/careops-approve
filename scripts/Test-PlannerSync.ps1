[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root 'config/planner-sync.example.json') | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath (Join-Path $root 'flows/planner-task-sync.contract.json') | ConvertFrom-Json

if ($config.planType -ne 'basic' -or $contract.supportedPlanType -ne 'basic') { throw 'Planner integration must use a basic plan.' }
if ($contract.connectorTier -ne 'standard') { throw 'Planner integration must retain the standard-connector path.' }
if ($config.decisionAuthority -ne 'native-teams-approval') { throw 'Planner must not become the decision authority.' }
foreach ($rule in @('create-once-after-request-id-is-persisted', 'updates-must-be-idempotent', 'planner-completion-must-not-finalize-an-approval', 'no-email-actions')) {
    if ($config.rules -notcontains $rule) { throw "Planner configuration is missing rule: $rule" }
}
foreach ($invariant in @('native-teams-approval-remains-authoritative', 'one-planner-task-per-careops-request', 'planner-task-completion-does-not-approve-or-reject', 'no-sensitive-payload-in-planner', 'no-outbound-email')) {
    if ($contract.invariants -notcontains $invariant) { throw "Planner contract is missing invariant: $invariant" }
}
$stepIds = @($contract.steps | ForEach-Object id)
foreach ($step in @('validate-projection', 'find-existing-task', 'create-task-once', 'persist-task-id', 'update-task', 'route-failure')) {
    if ($stepIds -notcontains $step) { throw "Planner contract is missing step: $step" }
}
if ($config.enabled -ne $false -or $contract.deploymentStatus -ne 'tenant-activation-pending') { throw 'Planner integration must remain disabled until tenant evidence exists.' }

Write-Output 'Planner sync contract validation passed.'


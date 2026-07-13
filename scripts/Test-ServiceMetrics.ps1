[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contract = Get-Content -Raw -LiteralPath (Join-Path $root 'config/service-metrics.example.json') | ConvertFrom-Json
$fixtures = Get-Content -Raw -LiteralPath (Join-Path $root 'config/service-metrics-fixtures.example.json') | ConvertFrom-Json
if ($contract.schemaVersion -ne 1 -or $contract.status -ne 'tenant-neutral-blueprint') { throw 'Service metrics contract must be tenant-neutral.' }
if ($contract.eventContract.rawRequestContent -ne $false -or $contract.eventContract.individualRanking -ne $false) { throw 'Metrics must exclude raw content and individual ranking.' }
if ($contract.ownerWarnings.email -ne $false -or $contract.ownerWarnings.channel -ne 'owner-only-teams-summary') { throw 'Warnings must be owner-only and email-free.' }
function Get-Metrics($scenario) {
    $events = @($scenario.events | Group-Object eventId | ForEach-Object { $_.Group[0] })
    $submitted = @($events | Where-Object eventType -eq 'submitted'); $decisions = @($events | Where-Object eventType -eq 'decision'); $exceptions = @($events | Where-Object eventType -eq 'exception')
    $requestIds = @($submitted | ForEach-Object requestId | Sort-Object -Unique); $decisionIds = @($decisions | ForEach-Object requestId | Sort-Object -Unique); $exceptionIds = @($exceptions | ForEach-Object requestId | Sort-Object -Unique)
    $pending = @($requestIds | Where-Object { $decisionIds -notcontains $_ }); $overdue = 0; $leadTimes = @(); $queueAges = @()
    foreach ($requestId in $requestIds) { $submission = @($submitted | Where-Object requestId -eq $requestId | Select-Object -First 1)[0]; $decision = @($decisions | Where-Object requestId -eq $requestId | Select-Object -First 1)[0]; $reference = if ($decision) {[datetime]$decision.occurredAt} else {[datetime]$scenario.asOf}; if ($submission.dueAt -and [datetime]$submission.dueAt -lt $reference) {$overdue++}; if (-not $decision) {$queueAges += (([datetime]$scenario.asOf - [datetime]$submission.occurredAt).TotalHours)} }
    foreach ($decision in $decisions) { $submission = @($submitted | Where-Object requestId -eq $decision.requestId | Select-Object -First 1)[0]; if ($submission) {$leadTimes += (([datetime]$decision.occurredAt - [datetime]$submission.occurredAt).TotalHours)} }
    $demand = $requestIds.Count; $throughput = if($demand){[math]::Round($decisionIds.Count/$demand,3)}else{0}; $overdueRate = if($demand){[math]::Round($overdue/$demand,3)}else{0}; $exceptionRate = if($demand){[math]::Round($exceptionIds.Count/$demand,3)}else{0}; $warnings=@(); if($overdueRate -ge $contract.ownerWarnings.overdueRateAtLeast){$warnings+='overdueRate'}; if($exceptionRate -ge $contract.ownerWarnings.exceptionRateAtLeast){$warnings+='exceptionRate'}; if($queueAges -and (@($queueAges|Measure-Object -Maximum).Maximum -ge $contract.ownerWarnings.queueAgeHoursAtLeast)){$warnings+='queueAge'}
    [pscustomobject]@{demand=$demand;throughput=$throughput;overdueRate=$overdueRate;exceptionRate=$exceptionRate;queueAgeHours=if($queueAges){[int](@($queueAges|Measure-Object -Maximum).Maximum)}else{0};warnings=@($warnings|Sort-Object)}
}
foreach ($scenario in @($fixtures.scenarios)) { $actual=Get-Metrics $scenario; foreach($field in @('demand','throughput','overdueRate','exceptionRate','queueAgeHours')){if($actual.$field -ne $scenario.expected.$field){throw "Scenario $($scenario.name) $field mismatch."}}; if((@($actual.warnings)-join ',') -ne ((@($scenario.expected.warnings)|Sort-Object)-join ',')){throw "Scenario $($scenario.name) warnings mismatch."} }
Write-Output ("Service metrics validation passed: {0} synthetic scenarios." -f @($fixtures.scenarios).Count)

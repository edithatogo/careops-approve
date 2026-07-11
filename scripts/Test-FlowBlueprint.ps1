[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'flows/submit-and-route.contract.json'
$flow = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json

if ($flow.status -ne 'blueprint') { throw 'Flow contract must remain a blueprint until tenant export is approved.' }
if ($flow.deploymentStatus -ne 'executive-confirmed-live') { throw 'Flow deployment status must reflect executive confirmation.' }
foreach ($surface in @('Microsoft Forms', 'SharePoint', 'Power Automate', 'Teams Approvals')) {
    if ($flow.surfaces -notcontains $surface) { throw "Flow blueprint is missing surface: $surface" }
}
foreach ($step in @('validate-input', 'load-configuration', 'generate-request-id', 'create-submission', 'create-approval', 'acknowledge-requester', 'restrict-request-visibility', 'persist-immutable-assignment', 'persist-final-outcome', 'allow-requester-cancellation', 'create-edms-escalation', 'finalize')) {
    if (@($flow.steps | Where-Object id -eq $step).Count -ne 1) { throw "Flow blueprint is missing step: $step" }
}
foreach ($failure in @('invalid-input-does-not-create-approval', 'invalid-configuration-preserves-submission-and-alerts-owner', 'connector-failure-preserves-request-and-reports-actionable-error')) {
    if ($flow.failurePaths -notcontains $failure) { throw "Flow blueprint is missing failure path: $failure" }
}
if (-not ($flow.steps | Where-Object id -eq 'create-approval').rejectionRequiresComment) { throw 'Approval blueprint must require rejection comments.' }
if (($flow.steps | Where-Object id -eq 'create-approval').sendEmailNotification) { throw 'Approval blueprint must suppress email notifications.' }
foreach ($failure in @('rejection-without-comment-does-not-finalize', 'assigned-approver-and-approval-id-are-immutable')) {
    if ($flow.failurePaths -notcontains $failure) { throw "Flow blueprint is missing failure path: $failure" }
}
$approval = $flow.steps | Where-Object id -eq 'create-approval'
if ($approval.timeoutDays -ne 14 -or $approval.onTimeout -ne 'create-edms-escalation') { throw 'Approval blueprint must define a 14-day EDMS escalation.' }
if (($flow.steps | Where-Object id -eq 'create-edms-escalation').sendEmailNotification) { throw 'EDMS escalation must suppress email notifications.' }
if (($flow.steps | Where-Object id -eq 'restrict-request-visibility').audience.Count -ne 3) { throw 'Approval visibility must be limited to the three permitted audiences.' }
foreach ($failure in @('timeout-escalates-to-edms-without-email', 'requester-cancellation-is-audited-and-idempotent', 'visibility-is-limited-to-owner-requester-and-assigned-approver')) {
    if ($flow.failurePaths -notcontains $failure) { throw "Flow blueprint is missing failure path: $failure" }
}
if ($flow.tenantConfiguration -ne 'not stored in source control') { throw 'Flow blueprint contains a tenant configuration value.' }

Write-Output 'Flow blueprint validation passed.'

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'flows/submit-and-route.contract.json'
$flow = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json

if ($flow.status -ne 'blueprint') { throw 'Flow contract must remain a blueprint until tenant export is approved.' }
foreach ($surface in @('Microsoft Forms', 'SharePoint', 'Power Automate', 'Teams Approvals')) {
    if ($flow.surfaces -notcontains $surface) { throw "Flow blueprint is missing surface: $surface" }
}
foreach ($step in @('validate-input', 'load-configuration', 'generate-request-id', 'create-submission', 'create-approval', 'acknowledge-requester', 'persist-immutable-assignment', 'persist-final-outcome', 'finalize')) {
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
if ($flow.tenantConfiguration -ne 'not stored in source control') { throw 'Flow blueprint contains a tenant configuration value.' }

Write-Output 'Flow blueprint validation passed.'

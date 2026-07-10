[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contract = Get-Content -Raw -LiteralPath (Join-Path $root 'flows/tesl-email-to-approval.contract.json') | ConvertFrom-Json
$mapping = Get-Content -Raw -LiteralPath (Join-Path $root 'config/tesl-email-mapping.example.json') | ConvertFrom-Json
$templates = Get-Content -Raw -LiteralPath (Join-Path $root 'config/approval-templates.example.json') | ConvertFrom-Json
$roles = Get-Content -Raw -LiteralPath (Join-Path $root 'config/role-assignments.example.json') | ConvertFrom-Json
$bpmn = [System.Xml.Linq.XDocument]::Load((Join-Path $root 'workflows/tesl-email-to-approval.bpmn'))

if ($contract.status -ne 'blueprint') { throw 'TESL flow must remain a blueprint until tenant export is approved.' }
foreach ($surface in @('Office 365 Outlook', 'SharePoint', 'Power Automate', 'Teams Approvals')) {
    if ($contract.surfaces -notcontains $surface) { throw "TESL flow is missing surface: $surface" }
}
foreach ($step in @('match-tesl-email', 'parse-tesl-details', 'load-template', 'validate-tesl-details', 'load-configuration', 'create-submission', 'create-approval', 'wait-for-decision', 'check-still-pending', 'create-edms-escalation', 'wait-for-edms-decision', 'record-verbal-delegation', 'persist-outcome', 'notify-requester', 'finalize')) {
    if (@($contract.steps | Where-Object id -eq $step).Count -ne 1) { throw "TESL flow is missing step: $step" }
}
foreach ($field in @('teslId', 'teslTitle', 'teslStatus', 'teslSummary')) {
    if (-not $mapping.fields.$field) { throw "TESL mapping is missing required field: $field" }
}
if ($mapping.unknownFields -ne 'preserve-in-rawTeslDetails') { throw 'Unknown TESL fields must be preserved.' }
foreach ($templateId in @('tesl-review', 'edms-escalation')) {
    if (@($templates.templates | Where-Object templateId -eq $templateId).Count -ne 1) { throw "Missing approval template: $templateId" }
}
foreach ($role in @('executiveAssistant', 'medicalWorkforceManager', 'edmsEscalationApprover')) {
    if (-not $roles.roles.$role) { throw "Missing role assignment: $role" }
}
foreach ($permission in @('submitters', 'workflowEditors', 'normalApprovers', 'urgentDelegatedApprovers')) {
    if (-not $roles.permissions.$permission) { throw "Missing permission group: $permission" }
}
if ($roles.delegationPolicy.mode -ne 'recorded-verbal-delegation-only' -or -not $roles.delegationPolicy.requiresOwnerNotification) { throw 'Urgent delegation must be recorded and notify the workflow owner.' }

$ns = [System.Xml.Linq.XNamespace]::Get('http://www.omg.org/spec/BPMN/20100524/MODEL')
$process = $bpmn.Root.Element($ns + 'process')
if (-not $process -or $process.Attribute('id').Value -ne 'Process_TESL_Email_Approval') { throw 'BPMN process is missing or has the wrong ID.' }
foreach ($element in @('startEvent', 'serviceTask', 'exclusiveGateway', 'userTask', 'endEvent', 'sequenceFlow')) {
    if ($process.Elements($ns + $element).Count -eq 0) { throw "BPMN process is missing $element." }
}
if (@($process.Elements($ns + 'sequenceFlow')).Count -lt 18) { throw 'BPMN process does not cover the full approval and escalation path.' }
if (@($process.Elements($ns + 'boundaryEvent')).Count -ne 1) { throw 'BPMN process must contain one pending timeout boundary event.' }
if (@($process.Descendants($ns + 'timeDuration') | Where-Object { $_.Value.Trim() -eq 'P14D' }).Count -ne 1) { throw 'BPMN process must use a 14-day timeout.' }

Write-Output 'TESL approval artifact validation passed.'

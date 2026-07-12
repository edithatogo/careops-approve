[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$null = Add-Type -AssemblyName System.Xml.Linq
$root = Split-Path -Parent $PSScriptRoot
$contract = Get-Content -Raw -LiteralPath (Join-Path $root 'flows/tesl-email-to-approval.contract.json') | ConvertFrom-Json
$mapping = Get-Content -Raw -LiteralPath (Join-Path $root 'config/tesl-email-mapping.example.json') | ConvertFrom-Json
$templates = Get-Content -Raw -LiteralPath (Join-Path $root 'config/approval-templates.example.json') | ConvertFrom-Json
$roles = Get-Content -Raw -LiteralPath (Join-Path $root 'config/role-assignments.example.json') | ConvertFrom-Json
$desktop = Get-Content -Raw -LiteralPath (Join-Path $root 'config/desktop-intranet-execution.example.json') | ConvertFrom-Json
$reuse = Get-Content -Raw -LiteralPath (Join-Path $root 'config/power-automate-reuse.example.json') | ConvertFrom-Json
$intake = Get-Content -Raw -LiteralPath (Join-Path $root 'config/tesl-intake-controls.example.json') | ConvertFrom-Json
$bpmn = [System.Xml.Linq.XDocument]::Load((Join-Path $root 'workflows/tesl-email-to-approval.bpmn'))

if ($contract.status -ne 'blueprint') { throw 'TESL flow must remain a blueprint until tenant export is approved.' }
if ($contract.deploymentStatus -ne 'executive-confirmed-live') { throw 'TESL deployment status must reflect executive confirmation.' }
foreach ($surface in @('Office 365 Outlook', 'SharePoint', 'Power Automate', 'Teams Approvals')) {
    if ($contract.surfaces -notcontains $surface) { throw "TESL flow is missing surface: $surface" }
}
foreach ($step in @('match-tesl-email', 'deduplicate-source-message', 'parse-tesl-details', 'persist-intake-telemetry', 'load-template', 'validate-tesl-details', 'route-invalid-intake', 'manual-correction-review', 'load-configuration', 'resolve-roster-and-delegation', 'create-submission', 'run-ai-pre-review', 'persist-ai-assessment', 'create-approval', 'present-teams-card', 'wait-for-decision', 'check-still-pending', 'create-edms-escalation', 'wait-for-edms-decision', 'record-verbal-delegation', 'persist-outcome', 'notify-requester', 'run-desktop-intranet', 'build-weekly-owner-summary', 'finalize')) {
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
if ($contract.notificationPolicy.approvalEmail -ne $false -or $contract.notificationPolicy.outboundEmail -ne $false) { throw 'TESL flow must disable email notifications.' }
$ai = Get-Content -Raw -LiteralPath (Join-Path $root 'config/ai-review.example.json') | ConvertFrom-Json
if ($ai.mode -ne 'advisory' -or $ai.recommendation -ne 'no-autonomous-decision' -or $ai.humanDecisionRequired -ne $true) { throw 'AI review must remain advisory and human-authoritative.' }
if ($contract.steps | Where-Object { $_.type -eq 'outlook-send-email' }) { throw 'TESL flow must not contain an outbound Outlook email action.' }
if ($desktop.notifications.email -ne $false -or $desktop.action -ne 'Run a flow built with Power Automate for desktop') { throw 'Desktop execution must be approved-only and email-free.' }
foreach ($patternId in @('sharepoint-action-state', 'teams-adaptive-card-presentation', 'dynamic-roster-resolution', 'delegate-assignment-resolution', 'weekly-teams-summary')) {
    if (@($reuse.patterns | Where-Object patternId -eq $patternId).Count -ne 1) { throw "Missing reusable Power Automate pattern: $patternId" }
}
foreach ($patternId in @('idempotent-email-intake', 'failed-extraction-routing', 'sanitized-flow-telemetry', 'manual-correction-review')) {
    if (@($reuse.patterns | Where-Object patternId -eq $patternId).Count -ne 1) { throw "Missing reused TESL pattern: $patternId" }
}
if ($contract.intakeControls -ne 'config/tesl-intake-controls.example.json') { throw 'TESL intake controls are not linked.' }
if (-not $intake.idempotency.replayMustNotCreateApproval) { throw 'Duplicate TESL intake must not create an approval.' }
if ($intake.routing.outboundEmail -ne $false -or $intake.telemetry.rawEmailBody -ne $false -or $intake.telemetry.sensitivePayloads -ne $false) { throw 'TESL intake controls must remain email-free and sanitized.' }
if (-not $intake.manualCorrection.createsApprovalOnlyAfterCorrection -or -not $intake.manualCorrection.nativeApprovalRemainsAuthoritative) { throw 'Manual correction must remain human-gated and subordinate to native approval.' }
$card = @($contract.steps | Where-Object id -eq 'present-teams-card')[0]
if ($card.authoritativeDecisionSource -ne 'native-teams-approval' -or $card.email -ne $false) { throw 'Teams card must be email-free and subordinate to native Approvals.' }
$summary = @($contract.steps | Where-Object id -eq 'build-weekly-owner-summary')[0]
if ($summary.visibility -ne 'workflowOwner' -or $summary.email -ne $false) { throw 'Weekly summary must be owner-only and email-free.' }

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

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contract = Get-Content -Raw -LiteralPath (Join-Path $root 'flows/tesl-email-to-approval.contract.json') | ConvertFrom-Json
$mapping = Get-Content -Raw -LiteralPath (Join-Path $root 'config/tesl-email-mapping.example.json') | ConvertFrom-Json
$bpmn = [System.Xml.Linq.XDocument]::Load((Join-Path $root 'workflows/tesl-email-to-approval.bpmn'))

if ($contract.status -ne 'blueprint') { throw 'TESL flow must remain a blueprint until tenant export is approved.' }
foreach ($surface in @('Office 365 Outlook', 'SharePoint', 'Power Automate', 'Teams Approvals')) {
    if ($contract.surfaces -notcontains $surface) { throw "TESL flow is missing surface: $surface" }
}
foreach ($step in @('match-tesl-email', 'parse-tesl-details', 'validate-tesl-details', 'load-configuration', 'create-submission', 'create-approval', 'wait-for-decision', 'persist-outcome', 'notify-requester', 'finalize')) {
    if (@($contract.steps | Where-Object id -eq $step).Count -ne 1) { throw "TESL flow is missing step: $step" }
}
foreach ($field in @('teslId', 'teslTitle', 'teslStatus', 'teslSummary')) {
    if (-not $mapping.fields.$field) { throw "TESL mapping is missing required field: $field" }
}
if ($mapping.unknownFields -ne 'preserve-in-rawTeslDetails') { throw 'Unknown TESL fields must be preserved.' }

$ns = [System.Xml.Linq.XNamespace]::Get('http://www.omg.org/spec/BPMN/20100524/MODEL')
$process = $bpmn.Root.Element($ns + 'process')
if (-not $process -or $process.Attribute('id').Value -ne 'Process_TESL_Email_Approval') { throw 'BPMN process is missing or has the wrong ID.' }
foreach ($element in @('startEvent', 'serviceTask', 'exclusiveGateway', 'userTask', 'endEvent', 'sequenceFlow')) {
    if ($process.Elements($ns + $element).Count -eq 0) { throw "BPMN process is missing $element." }
}
if (@($process.Elements($ns + 'sequenceFlow')).Count -lt 14) { throw 'BPMN process does not cover the full approval path.' }

Write-Output 'TESL approval artifact validation passed.'

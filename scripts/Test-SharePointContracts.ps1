[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'config/sharepoint-lists.example.json'
$model = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json

if ($model.siteUrl -notmatch 'provided by approved tenant configuration') { throw 'Example contract must not contain a tenant site URL.' }
if ($model.lists.Count -ne 3) { throw 'The MVP requires exactly three SharePoint list contracts.' }

$expected = @('CareOps_Submissions', 'CareOps_Decisions', 'CareOps_ApproverConfiguration')
foreach ($name in $expected) {
    $list = @($model.lists | Where-Object name -eq $name)
    if ($list.Count -ne 1) { throw "Missing or duplicate list contract: $name" }
    if (-not $list[0].permissions.owners) { throw "List $name must define owner permissions." }
}

$submissions = $model.lists | Where-Object name -eq 'CareOps_Submissions'
foreach ($field in @('RequestId', 'Status', 'AssignedApproverEmail', 'ApproverConfigurationVersion')) {
    $entry = @($submissions.fields | Where-Object name -eq $field)
    if ($entry.Count -ne 1 -or -not $entry[0].required) { throw "Submission field $field must be required." }
}
foreach ($field in @('RequestId', 'AssignedApproverEmail', 'ApproverConfigurationVersion')) {
    $entry = $submissions.fields | Where-Object name -eq $field
    if (-not $entry.immutableAfterCreate) { throw "Submission field $field must be immutable after create." }
}

$decisions = $model.lists | Where-Object name -eq 'CareOps_Decisions'
if ($decisions.rules -notcontains 'one-final-record-per-request' -or $decisions.rules -notcontains 'rejected-requires-comment') { throw 'Decision invariants are incomplete.' }
$config = $model.lists | Where-Object name -eq 'CareOps_ApproverConfiguration'
if ($config.rules -notcontains 'changes-affect-new-submissions-only' -or $config.permissions.requesters -ne 'no-access') { throw 'Approver configuration safeguards are incomplete.' }

Write-Output 'SharePoint contract validation passed.'

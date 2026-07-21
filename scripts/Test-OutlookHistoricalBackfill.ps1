[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$flow = Get-Content -Raw -LiteralPath (Join-Path $root 'flows/outlook-historical-backfill.contract.json') | ConvertFrom-Json

if ($flow.status -ne 'blueprint' -or $flow.deploymentStatus -ne 'tenant-activation-pending') { throw 'Historical backfill must remain tenant-neutral and activation-gated.' }
if ($flow.connectionPolicy -ne 'reuse-existing-approved-workflow-owner-connection') { throw 'Backfill must reuse the approved workflow-owner connection.' }
if ($flow.trigger.action -ne 'Get emails (V3)' -or $null -ne $flow.trigger.dateFilter) { throw 'Backfill must use Get emails (V3) without a date filter.' }
if (-not $flow.folderInventory.freezeBeforeExtraction -or -not $flow.folderInventory.hashBeforeExtraction) { throw 'Folder inventory must be frozen and hashed before extraction.' }
if (-not $flow.pagination.followContinuationUntilExhausted -or -not $flow.pagination.exhaustionRequiredPerFolder) { throw 'Backfill must exhaust pagination per folder.' }
foreach ($step in @('create-run','freeze-folder-inventory','iterate-folders','get-emails-page','project-minimized-fact','deduplicate-message','write-dataverse-fact','write-folder-manifest','reconcile-run','close-run','route-failure')) {
    if (@($flow.steps | Where-Object id -eq $step).Count -ne 1) { throw "Backfill contract is missing step: $step" }
}
foreach ($field in @('body','bodyPreview','subject','from','sender','to','cc','bcc','attachments')) {
    if ($flow.forbiddenPersistentFields -notcontains $field) { throw "Backfill contract must forbid raw field: $field" }
}
foreach ($rule in @('folder-inventory-frozen-and-hashed','every-authorised-folder-exhausted','all-candidates-accounted-for','source-and-projection-counts-reconcile','unchanged-rerun-produces-zero-new-identities')) {
    if ($flow.completionRules -notcontains $rule) { throw "Backfill contract is missing completion rule: $rule" }
}
if (-not $flow.noDesktopCom) { throw 'Desktop/COM must not be the production backfill route.' }
if ($flow.tenantConfiguration -ne 'not stored in source control') { throw 'Backfill contract contains tenant configuration.' }

Write-Output 'Outlook historical backfill contract validation passed.'

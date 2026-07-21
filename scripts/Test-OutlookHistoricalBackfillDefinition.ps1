[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$definition = Get-Content -Raw -LiteralPath (Join-Path $root 'flows/outlook-historical-backfill.definition.json') | ConvertFrom-Json

if ($definition.status -ne 'blueprint' -or $definition.deploymentStatus -ne 'tenant-activation-pending') { throw 'Definition must remain tenant-neutral and activation-gated.' }
if ($definition.trigger.type -ne 'manual' -or $definition.trigger.operation -ne 'button') { throw 'Historical backfill must be manually controlled.' }
foreach ($action in @('CreateRun','EnumerateFolders','FreezeInventory','ForEachIncludedFolder','ReconcileRun','CloseRun','FailClosed')) {
    if (@($definition.actions | Where-Object id -eq $action).Count -ne 1) { throw "Definition is missing action: $action" }
}
$folders = $definition.actions | Where-Object id -eq 'EnumerateFolders'
if (-not $folders.includeNested) { throw 'Folder enumeration must include nested folders.' }
$loop = $definition.actions | Where-Object id -eq 'ForEachIncludedFolder'
$until = $loop.actions | Where-Object id -eq 'UntilPagesExhausted'
if (-not $until -or $until.type -ne 'DoUntil') { throw 'Definition must include a page-exhaustion loop.' }
$page = $until.actions | Where-Object id -eq 'GetEmailsPage'
if (-not $page -or $page.type -ne 'Office365Outlook.GetEmailsV3' -or $page.top -ne 1000) { throw 'Definition must use Get emails V3 with the bounded page size.' }
$project = ($until.actions | Where-Object id -eq 'ForEachMessage').actions | Where-Object id -eq 'ProjectFact'
foreach ($field in @('body','bodyPreview','subject','from','sender','to','cc','bcc','attachments')) {
    if ($project.forbiddenInputs -notcontains $field) { throw "Definition must reject raw field: $field" }
}
$close = $definition.actions | Where-Object id -eq 'CloseRun'
if ($close.when -notmatch 'ReconcileRun') { throw 'Run closure must depend on reconciliation.' }
if ($definition.tenantConfiguration -ne 'not stored in source control') { throw 'Definition contains tenant configuration.' }

Write-Output 'Outlook historical backfill definition validation passed.'

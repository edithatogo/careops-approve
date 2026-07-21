[CmdletBinding()]
param([string]$Path = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config/outlook-historical-backfill-evidence.example.json'))
$ErrorActionPreference = 'Stop'
$e = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
$required = 'status','runIdHash','scopeClass','folderCount','pageCount','candidateCount','acquiredCount','duplicateCount','rejectedCount','deadLetterCount','earliestTimestamp','latestTimestamp','paginationExhausted','reconciled','idempotencyReplayVerified','noRawContentStored','externalEvidenceReference','operatorRole','approvalRole'
foreach ($name in $required) { if ($null -eq $e.$name) { throw "Missing evidence field: $name" } }
if ($e.status -ne 'pending-live-evidence') { throw 'Example evidence must remain pending-live-evidence.' }
if ($e.noRawContentStored -ne $true) { throw 'Evidence must assert no raw content is stored.' }
if ($e.scopeClass -ne 'authorised-mailbox-complete-history') { throw 'Unexpected scope class.' }
$rawNames = 'subject','body','attachment','recipient','upn','messageId','folderName','tenantId','token','cookie'
$json = Get-Content -Raw -LiteralPath $Path
foreach ($name in $rawNames) {
    $fieldPattern = '"' + $name + '"'
    if ($json -match $fieldPattern) { throw "Forbidden raw/private field: $name" }
}
Write-Output 'Outlook historical backfill evidence contract passed.'

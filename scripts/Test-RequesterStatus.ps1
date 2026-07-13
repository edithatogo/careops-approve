[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$schema = Get-Content -Raw -LiteralPath (Join-Path $root 'contracts/requester-status.schema.json') | ConvertFrom-Json
$config = Get-Content -Raw -LiteralPath (Join-Path $root 'config/requester-status-scenarios.example.json') | ConvertFrom-Json
if ($schema.additionalProperties -ne $false -or $config.visibility.futureSubjectEnabled -ne $false) { throw 'Requester status must be closed and future-subject visibility disabled.' }
foreach ($field in @('internalComments','approverPrivateNotes','rawEmailBody')) { if ($config.visibility.excludedFields -notcontains $field) { throw "Visibility boundary omits $field." } }
$seen = @{}
foreach ($scenario in @($config.scenarios)) {
    if ($scenario.role) { $expected = if ($config.visibility.allowedRoles -contains $scenario.role) {'allow'} elseif ($config.visibility.deniedRoles -contains $scenario.role) {'deny'} else {throw "Unknown role in scenario $($scenario.name)."}; if ($expected -ne $scenario.expected) { throw "Visibility scenario $($scenario.name) mismatch." } }
    if ($scenario.operation) { $key = "$($scenario.operation):$($scenario.eventId)"; if ($seen.ContainsKey($key) -and $scenario.replay -and $scenario.expected -ne 'ignore-replay') { throw "Replay scenario $($scenario.name) is not idempotent." }; $seen[$key] = $true }
}
Write-Output ("Requester status validation passed: {0} scenarios; future-subject visibility disabled." -f @($config.scenarios).Count)

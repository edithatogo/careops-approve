[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -Raw -LiteralPath (Join-Path $root 'config/track-execution-manifest.example.json') | ConvertFrom-Json
$registry = Get-Content -Raw -LiteralPath (Join-Path $root 'conductor/tracks.md')

$activeTrackIds = [regex]::Matches($registry, '(?ms)^- \[(?: |~)\].*?\./tracks/([a-z0-9_]+?)/') | ForEach-Object { $_.Groups[1].Value }
$manifestIds = @($manifest.tracks | ForEach-Object trackId)

foreach ($trackId in $activeTrackIds) {
    if ($manifestIds -notcontains $trackId) { throw "Execution manifest is missing active track: $trackId" }
}
foreach ($track in $manifest.tracks) {
    if ($activeTrackIds -notcontains $track.trackId) { throw "Execution manifest contains a non-active track: $($track.trackId)" }
    foreach ($field in @('firstPendingTask', 'startFiles', 'writeScope', 'validationCommands', 'prerequisites', 'stopConditions')) {
        if (-not $track.$field -or @($track.$field).Count -eq 0) { throw "Track $($track.trackId) is missing $field" }
    }
    foreach ($path in @($track.startFiles)) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $path) -PathType Leaf)) { throw "Track $($track.trackId) start file does not exist: $path" }
    }
    if ($track.issues.ghe -notmatch '^https://nswhealth\.ghe\.com/' -or $track.issues.github -notmatch '^https://github\.com/') {
        throw "Track $($track.trackId) must link both issue hosts."
    }
}
if (-not $manifest.globalRules.oneActiveTaskPerTrack -or -not $manifest.globalRules.tenantEvidenceMustBeSanitized) {
    throw 'Execution manifest global safeguards are incomplete.'
}

Write-Output "Track execution manifest validation passed: $($manifest.tracks.Count) active tracks."


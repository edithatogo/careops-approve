[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$primaryManifestPath = Join-Path $root 'config/track-execution-manifest.example.json'
$manifest = Get-Content -Raw -LiteralPath $primaryManifestPath | ConvertFrom-Json
$registry = Get-Content -Raw -LiteralPath (Join-Path $root 'conductor/tracks.md')

$manifestTracks = [System.Collections.Generic.List[object]]::new()
foreach ($track in @($manifest.tracks)) {
    $manifestTracks.Add($track)
}

$fragmentRoot = Join-Path $root 'config/track-execution-manifest.d'
if (Test-Path -LiteralPath $fragmentRoot -PathType Container) {
    foreach ($fragmentFile in @(Get-ChildItem -LiteralPath $fragmentRoot -Filter '*.json' -File | Sort-Object Name)) {
        $fragment = Get-Content -Raw -LiteralPath $fragmentFile.FullName | ConvertFrom-Json
        if ($fragment.PSObject.Properties.Name -contains 'tracks') {
            foreach ($track in @($fragment.tracks)) {
                $manifestTracks.Add($track)
            }
        }
        elseif ($fragment.PSObject.Properties.Name -contains 'trackId') {
            $manifestTracks.Add($fragment)
        }
        else {
            throw "Execution manifest fragment must contain tracks[] or one trackId object: $($fragmentFile.FullName)"
        }
    }
}

$activeTrackIds = [regex]::Matches($registry, '(?ms)^- \[(?: |~)\].*?\./tracks/([a-z0-9_-]+?)/') | ForEach-Object { $_.Groups[1].Value }
$manifestIds = @($manifestTracks | ForEach-Object trackId)

foreach ($trackId in $activeTrackIds) {
    if ($manifestIds -notcontains $trackId) { throw "Execution manifest is missing active track: $trackId" }
}
foreach ($track in $manifestTracks) {
    if ($activeTrackIds -notcontains $track.trackId) { throw "Execution manifest contains a non-active track: $($track.trackId)" }
    if (@($manifestIds | Where-Object { $_ -eq $track.trackId }).Count -ne 1) { throw "Execution manifest contains duplicate trackId: $($track.trackId)" }
    foreach ($field in @('firstPendingTask', 'startFiles', 'writeScope', 'validationCommands', 'prerequisites', 'stopConditions')) {
        if (-not $track.$field -or @($track.$field).Count -eq 0) { throw "Track $($track.trackId) is missing $field" }
    }
    foreach ($path in @($track.startFiles)) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $path) -PathType Leaf)) { throw "Track $($track.trackId) start file does not exist: $path" }
    }

    $githubIssue = [string]$track.issues.github
    if ($githubIssue -notmatch '^https://github\.com/[^/]+/[^/]+/(issues|pull)/\d+$') {
        throw "Track $($track.trackId) must link a GitHub issue or pull request."
    }

    foreach ($optionalIssueHost in @('enterprise', 'ghe')) {
        if ($track.issues.PSObject.Properties.Name -contains $optionalIssueHost) {
            $issueUrl = [string]$track.issues.$optionalIssueHost
            if (-not [string]::IsNullOrWhiteSpace($issueUrl) -and $issueUrl -notmatch '^https://[^/]+/.+/(issues|pull)/\d+$') {
                throw "Track $($track.trackId) has an invalid $optionalIssueHost issue reference."
            }
        }
    }
}
if (-not $manifest.globalRules.oneActiveTaskPerTrack -or -not $manifest.globalRules.tenantEvidenceMustBeSanitized) {
    throw 'Execution manifest global safeguards are incomplete.'
}

Write-Output "Track execution manifest validation passed: $($manifestTracks.Count) active tracks."

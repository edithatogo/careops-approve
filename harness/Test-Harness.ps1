[CmdletBinding()]
param([string]$PolicyPath)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $PolicyPath) { $PolicyPath = Join-Path $PSScriptRoot 'policy.json' }
$policyPathResolved = (Resolve-Path -LiteralPath $PolicyPath).Path
$policy = Get-Content -Raw -LiteralPath $policyPathResolved | ConvertFrom-Json

foreach ($path in $policy.required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $path) -PathType Leaf)) {
        throw "Harness required file is missing: $path"
    }
}

$files = @(git -C $root ls-files --cached --others --exclude-standard)
if ($LASTEXITCODE -ne 0) { throw 'Unable to enumerate publication-boundary files.' }
$normalized = $files | ForEach-Object { $_ -replace '\\', '/' }
foreach ($prefix in $policy.forbiddenTrackedPrefixes) {
    if ($normalized | Where-Object { $_ -like "$prefix*" }) {
        throw "Forbidden publication path detected: $prefix"
    }
}

$secretPatterns = @(
    'gh[pousr]_[A-Za-z0-9]{20,}',
    '(?i)(client[_ -]?secret|access[_ -]?token|refresh[_ -]?token)\s*[:=]\s*[^<$\{\s][^\r\n]*',
    '(?i)password\s*[:=]\s*[^<$\{\s][^\r\n]*'
)
foreach ($file in $files) {
    $full = Join-Path $root $file
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
    $content = Get-Content -Raw -LiteralPath $full -ErrorAction SilentlyContinue
    foreach ($pattern in $secretPatterns) {
        if ($content -match $pattern) { throw "Potential secret detected in publication-boundary file: $file" }
    }
}

foreach ($workflow in $policy.workflowFiles) {
    $path = Join-Path $root $workflow
    $content = Get-Content -Raw -LiteralPath $path
    if ($content -notmatch '(?m)^permissions:') { throw "Workflow lacks explicit permissions: $workflow" }
    if (-not $policy.allowContentsWrite -and $content -match 'contents:\s*write') {
        throw "Workflow requests contents: write under fail-closed harness policy: $workflow"
    }
}

& (Join-Path $root 'scripts/Test-Repository.ps1') -SkipRemoteTopology
Write-Output "Harness passed: $($policy.name)"

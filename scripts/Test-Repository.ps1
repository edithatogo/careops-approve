[CmdletBinding()]
param(
    [switch]$SkipRemoteTopology
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$required = @(
    'README.md',
    'conductor/index.md',
    'conductor/product.md',
    'conductor/product-guidelines.md',
    'conductor/tech-stack.md',
    'conductor/workflow.md',
    'conductor/tracks.md',
    'conductor/tracks/basic_submit_approve_20260710/spec.md',
    'conductor/tracks/basic_submit_approve_20260710/plan.md',
    'conductor/tracks/basic_submit_approve_20260710/metadata.json',
    'docs/alm.md',
    'docs/technology-radar.md',
    'docs/repository-topology.md',
    'docs/tenant-fit-checklist.md',
    'docs/low-privilege-architecture.md',
    '.github/workflows/validate.yml',
    '.github/workflows/deploy-pilot.yml',
    'config/pilot.deploymentSettings.example.json'
)

$missing = $required | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $root $_))
}

if (-not $SkipRemoteTopology) {
    $expectedRemotes = @{
        origin = 'https://nswhealth.ghe.com/60217257/careops-approve.git'
        github = 'https://github.com/edithatogo/careops-approve.git'
    }
    foreach ($remote in $expectedRemotes.GetEnumerator()) {
        $actual = git -C $root remote get-url $remote.Key 2>$null
        if ($LASTEXITCODE -ne 0 -or $actual -ne $remote.Value) {
            throw "Remote '$($remote.Key)' must be '$($remote.Value)'."
        }
    }

    $upstream = git -C $root rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>$null
    if ($LASTEXITCODE -ne 0 -or $upstream -ne 'origin/main') {
        throw "The current branch must track origin/main; found '$upstream'."
    }
}
if ($missing) {
    throw "Missing required files: $($missing -join ', ')"
}

$metadataPath = Join-Path $root 'conductor/tracks/basic_submit_approve_20260710/metadata.json'
$metadata = Get-Content -Raw -LiteralPath $metadataPath | ConvertFrom-Json
if ($metadata.track_id -ne 'basic_submit_approve_20260710') {
    throw 'Track metadata contains an unexpected track_id.'
}

$trackedFiles = git -C $root ls-files --cached --others --exclude-standard
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to enumerate tracked files.'
}

$forbiddenPathPatterns = @('.env', '.pac/')
foreach ($pattern in $forbiddenPathPatterns) {
    if ($trackedFiles | Select-String -SimpleMatch $pattern) {
        throw "Tracked path contains forbidden local configuration: $pattern"
    }
}

$secretPatterns = @(
    'client_secret\s*[:=]\s*[^<$\{]',
    'password\s*[:=]\s*[^<$\{]',
    'gh[pousr]_[A-Za-z0-9]{20,}'
)
foreach ($file in $trackedFiles) {
    $path = Join-Path $root $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        continue
    }
    $content = Get-Content -Raw -LiteralPath $path -ErrorAction SilentlyContinue
    foreach ($pattern in $secretPatterns) {
        if ($content -match $pattern) {
            throw "Potential secret pattern found in tracked file: $file"
        }
    }
}

Write-Output 'Repository validation passed.'

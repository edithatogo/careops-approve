[CmdletBinding()]
param(
    [string]$ManifestPath,
    [string]$SourceRoot,
    [string]$BuildRoot,
    [switch]$Diagnostics,
    [switch]$Version,
    [switch]$SkipBuild,
    [string[]]$CommandArgs
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $ManifestPath) { $ManifestPath = Join-Path $root 'tooling\powerplatform-tools.json' }
$manifest = Get-Content -Raw -LiteralPath (Resolve-Path -LiteralPath $ManifestPath).Path | ConvertFrom-Json
$fork = $manifest.tools.pacxFork
if (-not $fork.sourceCommit -or $fork.sourceCommit -notmatch '^[0-9a-f]{40}$') { throw 'PACX fork sourceCommit must be a full commit SHA.' }

$defaultRoot = [Environment]::ExpandEnvironmentVariables($fork.installRoot)
if (-not $SourceRoot) { $SourceRoot = Join-Path $defaultRoot 'source' }
if (-not $BuildRoot) { $BuildRoot = Join-Path $defaultRoot 'build' }
$sourceRootResolved = [IO.Path]::GetFullPath($SourceRoot)
$buildRootResolved = [IO.Path]::GetFullPath($BuildRoot)

function Resolve-Dotnet {
    $configured = [Environment]::ExpandEnvironmentVariables($manifest.tools.dotnetSdk.installRoot)
    $configuredExe = Join-Path $configured 'dotnet.exe'
    if (Test-Path -LiteralPath $configuredExe) { return $configuredExe }
    $command = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    throw "A user-local dotnet executable was not found. Install SDK $($manifest.tools.dotnetSdk.version) or set PATH to dotnet."
}

function Get-SdkLines([string]$DotnetPath) {
    $lines = @(& $DotnetPath --list-sdks 2>$null)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect installed .NET SDKs.' }
    return $lines
}

function Select-Target([string[]]$SdkLines) {
    if ($SdkLines -match ('^' + [regex]::Escape($fork.preferredTargetFramework.Replace('net', '')) + '\.')) { return $fork.preferredTargetFramework }
    if ($SdkLines -match ('^' + [regex]::Escape($fork.fallbackTargetFramework.Replace('net', '')) + '\.')) { return $fork.fallbackTargetFramework }
    throw "Neither preferred SDK $($fork.preferredTargetFramework) nor fallback SDK $($fork.fallbackTargetFramework) is installed."
}

function Invoke-Git([string[]]$Arguments) {
    & git @Arguments
    if ($LASTEXITCODE -ne 0) { throw "git command failed: git $($Arguments -join ' ')" }
}

$dotnet = Resolve-Dotnet
$sdkLines = Get-SdkLines $dotnet
$target = Select-Target $sdkLines

if ($Diagnostics) {
    [pscustomobject]@{
        repository = $fork.repository
        branch = $fork.branch
        sourceCommit = $fork.sourceCommit
        preferredTargetFramework = $fork.preferredTargetFramework
        fallbackTargetFramework = $fork.fallbackTargetFramework
        selectedTargetFramework = $target
        dotnet = $dotnet
        sourceRoot = $sourceRootResolved
        buildRoot = $buildRootResolved
        credentialFilesCreated = $false
        liveMutation = $false
    } | ConvertTo-Json -Depth 3
    return
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is required to clone the PACX source.' }
New-Item -ItemType Directory -Force -Path $sourceRootResolved, $buildRootResolved | Out-Null
$sourceDir = Join-Path $sourceRootResolved "pacx-$($fork.sourceCommit.Substring(0, 12))"
if (-not (Test-Path -LiteralPath (Join-Path $sourceDir '.git'))) {
    if (Test-Path -LiteralPath $sourceDir) { throw "Source path exists but is not a git clone: $sourceDir" }
    Invoke-Git @('clone', '--depth', '1', '--branch', $fork.branch, $fork.repository, $sourceDir)
}
$actualCommit = (& git -C $sourceDir rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect the PACX source revision.' }
if ($actualCommit -ne $fork.sourceCommit) {
    Invoke-Git @('-C', $sourceDir, 'fetch', '--depth', '1', 'origin', $fork.sourceCommit)
    Invoke-Git @('-C', $sourceDir, 'checkout', '--detach', $fork.sourceCommit)
}

$stageDir = Join-Path $buildRootResolved "pacx-$($fork.sourceCommit.Substring(0, 12))-$target"
if (-not $SkipBuild) {
    if (Test-Path -LiteralPath $stageDir) { Remove-Item -LiteralPath $stageDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
    Get-ChildItem -LiteralPath $sourceDir -Force | Where-Object Name -ne '.git' | Copy-Item -Destination $stageDir -Recurse -Force
    $project = Join-Path $stageDir $fork.buildProject
    if (-not (Test-Path -LiteralPath $project)) { throw "PACX project was not found: $($fork.buildProject)" }
    $globalJson = Join-Path $stageDir 'global.json'
    $disabledGlobalJson = Join-Path $stageDir 'global.json.codex-disabled'
    $movedGlobalJson = $false
    try {
        if ($target -eq $fork.fallbackTargetFramework -and (Test-Path -LiteralPath $globalJson)) {
            Move-Item -LiteralPath $globalJson -Destination $disabledGlobalJson
            $movedGlobalJson = $true
        }
        & $dotnet restore $project -p:TargetFramework=$target --ignore-failed-sources
        if ($LASTEXITCODE -ne 0) { throw 'PACX restore failed.' }
        & $dotnet build $project -f $target --no-restore
        if ($LASTEXITCODE -ne 0) { throw 'PACX build failed.' }
    }
    finally {
        if ($movedGlobalJson -and (Test-Path -LiteralPath $disabledGlobalJson)) {
            Move-Item -LiteralPath $disabledGlobalJson -Destination $globalJson
        }
    }
}

$dll = Get-ChildItem -LiteralPath $stageDir -Filter 'pacx.dll' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $dll) { throw "Built pacx.dll was not found under $stageDir. Run without -SkipBuild." }
Write-Output "PACX fork ready: $($dll.FullName)"
if ($Version) {
    & $dotnet $dll.FullName --version
    exit $LASTEXITCODE
}
if ($CommandArgs) {
    & $dotnet $dll.FullName @CommandArgs
    exit $LASTEXITCODE
}

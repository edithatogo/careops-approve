[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$validate = Get-Content -Raw -LiteralPath (Join-Path $root '.github/workflows/validate.yml')
$deploy = Get-Content -Raw -LiteralPath (Join-Path $root '.github/workflows/deploy-pilot.yml')
$dependabot = Get-Content -Raw -LiteralPath (Join-Path $root '.github/dependabot.yml')

foreach ($required in @('microsoft/powerplatform-actions/actions-install', 'microsoft/powerplatform-actions/pack-solution', 'actions/upload-artifact')) {
    if ($validate -notmatch ([regex]::Escape($required) + '@[a-f0-9]{40}(?=\s|$)')) { throw "Validation workflow must pin $required to an immutable commit." }
}
foreach ($required in @('microsoft/powerplatform-actions/check-solution', 'microsoft/powerplatform-actions/import-solution')) {
    if ($deploy -notmatch ([regex]::Escape($required) + '@[a-f0-9]{40}(?=\s|$)')) { throw "Deploy workflow must pin $required to an immutable commit." }
}
if ($deploy -notmatch 'environment: pilot') { throw 'Deploy workflow is missing the pilot environment boundary.' }
if ($dependabot -notmatch 'package-ecosystem: github-actions' -or $dependabot -notmatch 'interval: weekly') { throw 'Dependabot must monitor GitHub Actions weekly.' }
if ($dependabot -notmatch 'update-types: \["version-update:semver-minor", "version-update:semver-patch"\]') { throw 'Dependabot must group only non-major action updates.' }
if ($validate -match 'git push --mirror' -or $deploy -match 'git push --mirror') { throw 'Workflows must not use destructive mirror pushes.' }

Write-Output 'Workflow contract validation passed.'

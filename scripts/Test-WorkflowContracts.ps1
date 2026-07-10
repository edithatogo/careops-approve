[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$validate = Get-Content -Raw -LiteralPath (Join-Path $root '.github/workflows/validate.yml')
$deploy = Get-Content -Raw -LiteralPath (Join-Path $root '.github/workflows/deploy-pilot.yml')
$dependabot = Get-Content -Raw -LiteralPath (Join-Path $root '.github/dependabot.yml')

foreach ($required in @('microsoft/powerplatform-actions/actions-install@v1', 'microsoft/powerplatform-actions/pack-solution@v1', 'actions/upload-artifact@v7')) {
    if ($validate -notmatch [regex]::Escape($required)) { throw "Validation workflow is missing $required." }
}
foreach ($required in @('microsoft/powerplatform-actions/check-solution@v1', 'microsoft/powerplatform-actions/import-solution@v1', 'environment: pilot')) {
    if ($deploy -notmatch [regex]::Escape($required)) { throw "Deploy workflow is missing $required." }
}
if ($dependabot -notmatch 'package-ecosystem: github-actions' -or $dependabot -notmatch 'interval: weekly') { throw 'Dependabot must monitor GitHub Actions weekly.' }
if ($dependabot -notmatch 'update-types: \["version-update:semver-minor", "version-update:semver-patch"\]') { throw 'Dependabot must group only non-major action updates.' }
if ($validate -match 'git push --mirror' -or $deploy -match 'git push --mirror') { throw 'Workflows must not use destructive mirror pushes.' }

Write-Output 'Workflow contract validation passed.'

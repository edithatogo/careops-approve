[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$validate = Get-Content -Raw -LiteralPath (Join-Path $root '.github/workflows/validate.yml')
$deploy = Get-Content -Raw -LiteralPath (Join-Path $root '.github/workflows/deploy-pilot.yml')
$dependabot = Get-Content -Raw -LiteralPath (Join-Path $root '.github/dependabot.yml')

foreach ($required in @('microsoft/powerplatform-actions/actions-install', 'microsoft/powerplatform-actions/pack-solution', 'actions/upload-artifact')) {
    if ($validate -notmatch ([regex]::Escape($required) + '@[0-9a-f]{40}(?:\s|$)')) { throw "Validation workflow is missing $required." }
}
foreach ($required in @('microsoft/powerplatform-actions/check-solution', 'microsoft/powerplatform-actions/import-solution')) {
    if ($deploy -notmatch ([regex]::Escape($required) + '@[0-9a-f]{40}(?:\s|$)')) { throw "Deploy workflow is missing $required." }
}
if ($deploy -notmatch 'environment: pilot') { throw 'Deploy workflow must retain the pilot environment gate.' }
if ($dependabot -notmatch 'package-ecosystem: github-actions' -or $dependabot -notmatch 'interval: weekly') { throw 'Dependabot must monitor GitHub Actions weekly.' }
if ($dependabot -notmatch 'update-types: \["minor", "patch"\]') { throw 'Dependabot must group only non-major action updates.' }
if ($validate -match 'git push --mirror' -or $deploy -match 'git push --mirror') { throw 'Workflows must not use destructive mirror pushes.' }

Write-Output 'Workflow contract validation passed.'

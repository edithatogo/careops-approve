[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$solution = Join-Path $root 'src/solutions/CareOpsApprove/Other/Solution.xml'
$customizations = Join-Path $root 'src/solutions/CareOpsApprove/Other/Customizations.xml'
$contractPath = Join-Path $root 'config/solution-contract.example.json'

foreach ($path in @($solution, $customizations, $contractPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing solution source file: $path" }
}

try { [xml]$solutionXml = Get-Content -Raw -LiteralPath $solution }
catch { throw "Solution.xml is not well-formed XML: $($_.Exception.Message)" }
try { [xml]$customizationsXml = Get-Content -Raw -LiteralPath $customizations }
catch { throw "Customizations.xml is not well-formed XML: $($_.Exception.Message)" }
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json

if ($solutionXml.ImportExportXml.SolutionManifest.UniqueName -ne 'CareOpsApprove') { throw 'Solution unique name is unexpected.' }
if ($solutionXml.ImportExportXml.SolutionManifest.Publisher.UniqueName -ne 'careops') { throw 'Solution publisher is unexpected.' }
if ($contract.solutionUniqueName -ne 'CareOpsApprove' -or $contract.publisherUniqueName -ne 'careops') { throw 'Solution contract does not match solution metadata.' }
if ($contract.connectionReferences.Count -ne 0 -or $contract.environmentVariables.Count -ne 0) { throw 'Example solution contract must not contain tenant configuration.' }

$tracked = git -C $root ls-files --cached --others --exclude-standard 'src/solutions' 'config/solution-contract.example.json'
foreach ($file in $tracked) {
    $content = Get-Content -Raw -LiteralPath (Join-Path $root $file)
    if ($content -match '(?i)(crm[0-9]*\.dynamics\.com|client[_-]?secret|tenant[_-]?id\s*[:=]\s*[0-9a-f-]{20,})') { throw "Tenant-specific value found in solution source: $file" }
}

Write-Output 'Solution source validation passed.'

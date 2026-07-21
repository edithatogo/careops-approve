[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$fixturePath = Join-Path $root 'config\pacx-flow-health-fixtures.example.json'
$reportScript = Join-Path $root 'scripts\New-PacxFlowHealthReport.ps1'
$fixtures = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
if ($fixtures.schemaVersion -ne 1) { throw 'Unsupported flow-health fixture schema.' }
$tempRoot = Join-Path $env:TEMP 'careops-pacx-flow-health-tests'
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
$index = 0
foreach ($case in @($fixtures.cases)) {
    $index++
    $inventoryPath = Join-Path $tempRoot "inventory-$index.json"
    $outputPath = Join-Path $tempRoot "report-$index.json"
    [pscustomobject]@{ schemaVersion = 1; flows = @($case.inventory) } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $inventoryPath -Encoding utf8
    $commandFailed = $false
    try {
        & $reportScript -InventoryPath $inventoryPath -OutputPath $outputPath
        if ($case.expectError) { throw [InvalidOperationException]::new("Fixture '$($case.name)' should have failed.") }
        $report = Get-Content -Raw -LiteralPath $outputPath | ConvertFrom-Json
        $actual = @($report.flows | ForEach-Object health)
        if ((ConvertTo-Json $actual -Compress) -ne (ConvertTo-Json @($case.expectedHealth) -Compress)) { throw "Fixture '$($case.name)' returned unexpected health states." }
        if (@($report.flows | Where-Object mutationAllowed -ne $false).Count -ne 0) { throw "Fixture '$($case.name)' enabled mutation." }
    }
    catch {
        if (-not $case.expectError) { throw }
        if ($_.Exception.Message -like "Fixture '$($case.name)' should have failed.*") { throw }
        $commandFailed = $true
    }
    if ($case.expectError -and -not $commandFailed) { throw "Fixture '$($case.name)' did not fail closed." }
}
Write-Output "PACX flow-health validation passed: $(@($fixtures.cases).Count) fixtures."

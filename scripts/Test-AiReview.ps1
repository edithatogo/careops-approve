[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read-Json([string]$path) { Get-Content -Raw -LiteralPath (Join-Path $root $path) | ConvertFrom-Json }

$config = Read-Json 'config/ai-review.example.json'
$schema = Read-Json 'contracts/ai-assessment.schema.json'
$fixture = Read-Json 'contracts/fixtures/ai-assessment.valid.json'
$scenarios = Read-Json 'config/ai-review-scenarios.example.json'

if ($config.enabled -ne $false -or $config.mode -ne 'advisory') { throw 'AI review must be opt-in advisory mode by default.' }
if ($config.recommendation -ne 'no-autonomous-decision' -or $config.humanDecisionRequired -ne $true) { throw 'AI review must never replace human decision authority.' }
if ($config.failMode -ne 'continue-to-human-review') { throw 'AI failure must preserve the human review path.' }
foreach ($field in @('summary', 'missingInformation', 'flags', 'confidence', 'recommendation', 'promptVersion', 'evaluatedAt', 'humanDecisionRequired')) {
    if ($schema.required -notcontains $field) { throw "AI assessment schema is missing $field." }
}
if ($fixture.recommendation -ne 'no-autonomous-decision' -or $fixture.humanDecisionRequired -ne $true) { throw 'AI assessment fixture violates human-in-the-loop guardrails.' }
if (@($scenarios.scenarios).Count -lt 4) { throw 'AI review scenarios must cover success, missing information, policy blocking, and connector failure.' }

Write-Output 'AI review contract validation passed.'

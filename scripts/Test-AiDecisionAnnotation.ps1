[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contract = Get-Content -Raw -LiteralPath (Join-Path $root 'config/ai-decision-annotation.example.json') | ConvertFrom-Json
$scenarios = Get-Content -Raw -LiteralPath (Join-Path $root 'config/ai-decision-annotation-scenarios.example.json') | ConvertFrom-Json
if ($contract.decisionAuthority -ne 'native-teams-approval' -or $contract.approvalPresentation.humanDecisionRequired -ne $true) { throw 'Human native Teams approval must remain authoritative.' }
if ($contract.postDecisionAnnotation.nativeApprovalMutation -ne $false -or $contract.postDecisionAnnotation.email -ne $false) { throw 'Post-decision annotation must not mutate native approval or send email.' }
foreach ($field in @('assessmentSummary','assessmentFlags','humanOutcome','humanComment')) { if ($contract.postDecisionAnnotation.requiredFields -notcontains $field) { throw "Annotation is missing $field." } }
foreach ($scenario in @($scenarios.scenarios)) { $expected = if ($scenario.replay) {'retain-first-annotation'} elseif ($scenario.assessmentStatus -in @('unavailable','needs-information','blocked-by-policy')) {'annotate-with-fallback'} else {'annotate'}; if ($expected -ne $scenario.expected) { throw "Scenario $($scenario.name) mismatch." } }
Write-Output ("AI decision annotation validation passed: {0} scenarios." -f @($scenarios.scenarios).Count)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contract = Get-Content (Join-Path $root 'config/privacy-retention-accessibility.example.json') -Raw | ConvertFrom-Json
$fixtures = Get-Content (Join-Path $root 'config/privacy-retention-accessibility-fixtures.example.json') -Raw | ConvertFrom-Json
if (-not $contract.visibility.denyUnlistedUsers -or -not $contract.privacy.internalCommentsExcludedFromRequesterSurface) { throw 'Visibility or comment-separation guardrail missing.' }
if (-not $contract.accessibility.requiredLabels -or -not $contract.accessibility.keyboardOperable -or -not $contract.accessibility.mobileLayout) { throw 'Accessibility guardrails incomplete.' }
foreach ($scenario in @($fixtures.scenarios)) {
  $actual = if ($null -ne $scenario.role) { if (@($contract.visibility.allowedRoles) -contains $scenario.role -and $scenario.role -ne 'futureSubject') {'allow'} else {'deny'} } else { if (($scenario.labels -eq $true -and $scenario.keyboard -eq $true) -or ($scenario.mobile -eq $true -and $scenario.logicalOrder -eq $true)) {'pass'} else {'fail'} }
  if ($actual -ne $scenario.expected) { throw "Scenario $($scenario.name) mismatch." }
}
Write-Output "Privacy, retention and accessibility validation passed: $(@($fixtures.scenarios).Count) scenarios."

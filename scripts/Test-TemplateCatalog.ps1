[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$catalog = Get-Content -Raw -LiteralPath (Join-Path $root 'config/approval-templates.example.json') | ConvertFrom-Json
$scenarios = Get-Content -Raw -LiteralPath (Join-Path $root 'config/template-routing-scenarios.example.json') | ConvertFrom-Json

if ($catalog.schemaVersion -ne 1 -or $catalog.status -ne 'blueprint') { throw 'Template catalogue must be a versioned blueprint.' }
if ($catalog.decisionAuthority -ne 'native-teams-approval') { throw 'Template catalogue must preserve native Teams approval authority.' }
$allowedLifecycle = @($catalog.lifecycleStates)
$templates = @($catalog.templates)
$ids = @($templates | ForEach-Object templateId)
if ($ids.Count -ne (@($ids | Sort-Object -Unique).Count)) { throw 'Template IDs must be unique.' }

foreach ($template in $templates) {
    foreach ($field in @('templateId','version','displayName','approvalClass','source','approverRole','visibility','amendmentPolicy')) {
        if ([string]::IsNullOrWhiteSpace([string]$template.$field)) { throw "Template is missing $field." }
    }
    if ($template.version -notmatch '^\d+\.\d+\.\d+$') { throw "Template $($template.templateId) has an invalid version." }
    if ($allowedLifecycle -notcontains $template.status) { throw "Template $($template.templateId) has an invalid lifecycle state." }
    if ($template.approvalClass -ne 'administrative') { throw "Template $($template.templateId) is outside the low-risk administrative catalogue." }
    if (@($template.requiredFields).Count -eq 0 -or @($template.eligibleSubmitterRoles).Count -eq 0) { throw "Template $($template.templateId) needs fields and eligible submitter roles." }
    if ([int]$template.slaDays -lt 1 -or [int]$template.slaDays -gt 30) { throw "Template $($template.templateId) has an invalid SLA." }
    if ($template.amendmentPolicy -ne 'draft-only-before-submission') { throw "Template $($template.templateId) has an unsafe amendment policy." }
    if (@($template.stages | Where-Object { -not $_.id -or -not $_.assignedToRole }).Count -gt 0) { throw "Template $($template.templateId) contains an incomplete stage." }
}

$retiredFixture = [pscustomobject]@{ templateId = 'retired-fixture'; status = 'retired' }
$routeTable = @($templates) + $retiredFixture
foreach ($scenario in @($scenarios.scenarios)) {
    $matches = @($routeTable | Where-Object templateId -eq $scenario.templateId)
    $actual = if ([string]::IsNullOrWhiteSpace([string]$scenario.templateId)) { 'reject-missing' }
              elseif ($matches.Count -eq 0) { 'reject-unknown' }
              elseif ($matches.Count -ne 1) { 'reject-ambiguous' }
              elseif ($matches[0].status -ne 'active') { 'reject-inactive' }
              else { 'route' }
    if ($actual -ne $scenario.expected) { throw "Scenario $($scenario.name) expected $($scenario.expected), got $actual." }
}

Write-Output ("Template catalogue validation passed: {0} templates and {1} deterministic routing scenarios." -f $templates.Count, @($scenarios.scenarios).Count)

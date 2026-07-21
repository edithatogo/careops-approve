[CmdletBinding()]
param(
    [switch]$SkipRemoteTopology
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$required = @(
    'README.md',
    'conductor/index.md',
    'conductor/product.md',
    'conductor/product-guidelines.md',
    'conductor/tech-stack.md',
    'conductor/workflow.md',
    'conductor/tracks.md',
    'conductor/tracks/basic_submit_approve_20260710/spec.md',
    'conductor/tracks/basic_submit_approve_20260710/plan.md',
    'conductor/tracks/basic_submit_approve_20260710/metadata.json',
    'docs/alm.md',
    'docs/technology-radar.md',
    'docs/repository-topology.md',
    'docs/tenant-fit-checklist.md',
    'docs/deployment-attestation.md',
    'docs/ai-assisted-review.md',
    'docs/low-privilege-architecture.md',
    'docs/frontier-capability-assessment.md',
    'docs/capability-matrix.md',
    'docs/planner-integration.md',
    'docs/model-execution-playbook.md',
    'contracts/request.schema.json',
    'contracts/decision.schema.json',
    'contracts/approver-configuration.schema.json',
    'contracts/ai-assessment.schema.json',
    'contracts/README.md',
    'contracts/fixtures/request.valid.json',
    'contracts/fixtures/decision.valid.json',
    'contracts/fixtures/approver-configuration.valid.json',
    'contracts/fixtures/ai-assessment.valid.json',
    'scripts/Test-Contracts.ps1',
    'config/ai-review.example.json',
    'config/ai-review-scenarios.example.json',
    'scripts/Test-AiReview.ps1',
    'src/solutions/CareOpsApprove/Other/Solution.xml',
    'src/solutions/CareOpsApprove/Other/Customizations.xml',
    'config/solution-contract.example.json',
    'docs/solution-source.md',
    'docs/pipelines.md',
    'scripts/Test-SolutionSource.ps1',
    'scripts/Test-WorkflowContracts.ps1',
    'config/sharepoint-lists.example.json',
    'docs/sharepoint-data-contracts.md',
    'scripts/Test-SharePointContracts.ps1',
    'config/workflow-scenarios.example.json',
    'scripts/Test-WorkflowScenarios.ps1',
    'docs/workflow-implementation.md',
    'flows/submit-and-route.contract.json',
    'scripts/Test-FlowBlueprint.ps1',
    'flows/tesl-email-to-approval.contract.json',
    'flows/planner-task-sync.contract.json',
    'flows/outlook-historical-backfill.contract.json',
    'scripts/Test-OutlookHistoricalBackfill.ps1',
    'flows/outlook-historical-backfill.definition.json',
    'scripts/Test-OutlookHistoricalBackfillDefinition.ps1',
    'config/tesl-email-mapping.example.json',
    'config/approval-templates.example.json',
    'config/template-routing-scenarios.example.json',
    'config/role-assignments.example.json',
    'config/desktop-intranet-execution.example.json',
    'config/power-automate-reuse.example.json',
    'config/integration-roadmap.example.json',
    'config/dataverse-review-surface.example.json',
    'config/tenant-pilot-evidence.example.json',
    'config/planner-sync.example.json',
    'config/track-execution-manifest.example.json',
    'config/service-metrics.example.json',
    'config/service-metrics-fixtures.example.json',
    'contracts/requester-status.schema.json',
    'config/requester-status-scenarios.example.json',
    'config/reconciliation.example.json',
    'config/reconciliation-fixtures.example.json',
    'scripts/Test-Reconciliation.ps1',
    'config/submission-quality.example.json',
    'config/submission-quality-fixtures.example.json',
    'scripts/Test-SubmissionQuality.ps1',
    'config/business-calendar-routing.example.json',
    'config/business-calendar-routing-fixtures.example.json',
    'scripts/Test-BusinessCalendarRouting.ps1',
    'config/privacy-retention-accessibility.example.json',
    'config/privacy-retention-accessibility-fixtures.example.json',
    'scripts/Test-PrivacyRetentionAccessibility.ps1',
    'config/dataverse-review-surface-fixtures.example.json',
    'scripts/Test-DataverseReviewSurface.ps1',
    'config/ai-decision-annotation.example.json',
    'config/ai-decision-annotation-scenarios.example.json',
    'scripts/Test-AiDecisionAnnotation.ps1',
    'docs/dataverse-review-surface.md',
    'docs/power-automate-reuse-assessment.md',
    'workflows/tesl-email-to-approval.bpmn',
    'workflows/submit-and-route.bpmn',
    'workflows/submit-and-route.mmd',
    'workflows/submit-and-route.svg',
    'workflows/tesl-email-to-approval.mmd',
    'workflows/tesl-email-to-approval.svg',
    'workflows/INDEX.md',
    'scripts/Test-BpmnArtifacts.ps1',
    'scripts/Test-TeslApprovalArtifacts.ps1',
    'scripts/Test-TemplateCatalog.ps1',
    'scripts/Test-IntegrationRoadmap.ps1',
    'scripts/Test-TenantReadiness.ps1',
    'docs/tesl-email-approval.md',
    'config/decision-scenarios.example.json',
    'scripts/Test-DecisionScenarios.ps1',
    'config/administration-scenarios.example.json',
    'scripts/Test-AdministrationScenarios.ps1',
    'config/approver-resolution.example.json',
    'docs/tenant-handoff-runbook.md',
    'docs/desktop-host-setup-checklist.md',
    'docs/maximum-delegated-capability.md',
    'docs/pilot-test-matrix.md',
    'scripts/Test-HandoffPackage.ps1',
    'docs/approver-administration.md',
    'tooling/powerplatform-tools.json',
    'docs/tooling.md',
    'scripts/Install-PowerPlatformTooling.ps1',
    'scripts/Install-PacxFork.ps1',
    'scripts/Test-PacxForkToolchain.ps1',
    'docs/pacx-toolchain-evidence-20260714.md',
    'config/pacx-flow-health.example.json',
    'config/pacx-flow-health-fixtures.example.json',
    'scripts/New-PacxFlowHealthReport.ps1',
    'scripts/Test-PacxFlowHealth.ps1',
    'scripts/Test-ToolingManifest.ps1',
    'harness/coverage-matrix.json',
    'scripts/Test-Coverage.ps1',
    'scripts/Test-CapabilityMatrix.ps1',
    'scripts/Test-PlannerSync.ps1',
    'scripts/Test-TrackExecutionManifest.ps1',
    'scripts/Test-ServiceMetrics.ps1',
    'scripts/Test-RequesterStatus.ps1',
    '.github/workflows/validate.yml',
    '.github/workflows/deploy-pilot.yml',
    'config/pilot.deploymentSettings.example.json'
)

$missing = $required | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $root $_))
}

if (-not $SkipRemoteTopology) {
    $expectedRemotes = @{
        origin = 'https://nswhealth.ghe.com/60217257/careops-approve.git'
        github = 'https://github.com/edithatogo/careops-approve.git'
    }
    foreach ($remote in $expectedRemotes.GetEnumerator()) {
        $actual = git -C $root remote get-url $remote.Key 2>$null
        if ($LASTEXITCODE -ne 0 -or $actual -ne $remote.Value) {
            throw "Remote '$($remote.Key)' must be '$($remote.Value)'."
        }
    }

    $upstream = git -C $root rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>$null
    if ($LASTEXITCODE -ne 0 -or $upstream -ne 'origin/main') {
        throw "The current branch must track origin/main; found '$upstream'."
    }
}
if ($missing) {
    throw "Missing required files: $($missing -join ', ')"
}

$metadataPath = Join-Path $root 'conductor/tracks/basic_submit_approve_20260710/metadata.json'
$metadata = Get-Content -Raw -LiteralPath $metadataPath | ConvertFrom-Json
if ($metadata.track_id -ne 'basic_submit_approve_20260710') {
    throw 'Track metadata contains an unexpected track_id.'
}

$trackedFiles = git -C $root ls-files --cached --others --exclude-standard
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to enumerate tracked files.'
}

$forbiddenPathPatterns = @('.env', '.pac/')
foreach ($pattern in $forbiddenPathPatterns) {
    if ($trackedFiles | Select-String -SimpleMatch $pattern) {
        throw "Tracked path contains forbidden local configuration: $pattern"
    }
}

$secretPatterns = @(
    'client_secret\s*[:=]\s*[^<$\{]',
    'password\s*[:=]\s*[^<$\{]',
    'gh[pousr]_[A-Za-z0-9]{20,}'
)
foreach ($file in $trackedFiles) {
    $path = Join-Path $root $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        continue
    }
    $content = Get-Content -Raw -LiteralPath $path -ErrorAction SilentlyContinue
    foreach ($pattern in $secretPatterns) {
        if ($content -match $pattern) {
            throw "Potential secret pattern found in tracked file: $file"
        }
    }
}

& (Join-Path $root 'scripts/Test-Contracts.ps1')
& (Join-Path $root 'scripts/Test-AiReview.ps1')
& (Join-Path $root 'scripts/Test-SolutionSource.ps1')
& (Join-Path $root 'scripts/Test-WorkflowContracts.ps1')
& (Join-Path $root 'scripts/Test-SharePointContracts.ps1')
& (Join-Path $root 'scripts/Test-WorkflowScenarios.ps1')
& (Join-Path $root 'scripts/Test-FlowBlueprint.ps1')
& (Join-Path $root 'scripts/Test-OutlookHistoricalBackfill.ps1')
& (Join-Path $root 'scripts/Test-OutlookHistoricalBackfillDefinition.ps1')
& (Join-Path $root 'scripts/Test-TeslApprovalArtifacts.ps1')
& (Join-Path $root 'scripts/Test-TemplateCatalog.ps1')
& (Join-Path $root 'scripts/Test-IntegrationRoadmap.ps1')
& (Join-Path $root 'scripts/Test-TenantReadiness.ps1')
& (Join-Path $root 'scripts/Test-BpmnArtifacts.ps1')
& (Join-Path $root 'scripts/Test-DecisionScenarios.ps1')
& (Join-Path $root 'scripts/Test-AdministrationScenarios.ps1')
& (Join-Path $root 'scripts/Test-HandoffPackage.ps1')
& (Join-Path $root 'scripts/Test-ToolingManifest.ps1')
& (Join-Path $root 'scripts/Test-PacxForkToolchain.ps1')
& (Join-Path $root 'scripts/Test-PacxFlowHealth.ps1')
& (Join-Path $root 'scripts/Test-Coverage.ps1')
& (Join-Path $root 'scripts/Test-CapabilityMatrix.ps1')
& (Join-Path $root 'scripts/Test-PlannerSync.ps1')
& (Join-Path $root 'scripts/Test-TrackExecutionManifest.ps1')
& (Join-Path $root 'scripts/Test-ServiceMetrics.ps1')
& (Join-Path $root 'scripts/Test-RequesterStatus.ps1')
& (Join-Path $root 'scripts/Test-AiDecisionAnnotation.ps1')
& (Join-Path $root 'scripts/Test-Reconciliation.ps1')
& (Join-Path $root 'scripts/Test-SubmissionQuality.ps1')
& (Join-Path $root 'scripts/Test-BusinessCalendarRouting.ps1')
& (Join-Path $root 'scripts/Test-PrivacyRetentionAccessibility.ps1')
& (Join-Path $root 'scripts/Test-DataverseReviewSurface.ps1')

Write-Output 'Repository validation passed.'

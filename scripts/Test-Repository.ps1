[CmdletBinding()]
param(
    [switch]$SkipRemoteTopology
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$coreRequired = @(
    'README.md',
    'LICENSE',
    'conductor/index.md',
    'conductor/product.md',
    'conductor/product-guidelines.md',
    'conductor/tech-stack.md',
    'conductor/workflow.md',
    'conductor/tracks.md',
    'docs/alm.md',
    'docs/repository-topology.md',
    'docs/workflow-platform-architecture.md',
    'pilot/workflow-studio/index.html',
    'pilot/workflow-studio/styles.css',
    'pilot/workflow-studio/app.js',
    'pilot/workflow-studio/README.md',
    'pilot/workflow-studio/sample.workflow.json',
    'contracts/request.schema.json',
    'contracts/decision.schema.json',
    'contracts/approver-configuration.schema.json',
    'contracts/ai-assessment.schema.json',
    'contracts/credentialing-governance-packet.schema.json',
    'contracts/credentialing-result.schema.json',
    'contracts/existing-system-source-record.schema.json',
    'contracts/workflow-definition.schema.json',
    'contracts/workflow-editor-catalog.schema.json',
    'contracts/workflow-publication.schema.json',
    'contracts/workflow-version-record.schema.json',
    'contracts/case.schema.json',
    'contracts/task.schema.json',
    'contracts/workflow-event.schema.json',
    'contracts/careops-api.v1.openapi.json',
    'reference/workflow_compiler.py',
    'reference/workflow_runtime.py',
    'tests/reference/test_workflow_compiler.py',
    'tests/reference/test_workflow_runtime.py',
    'reference/workflow_registry.py',
    'tests/reference/test_workflow_registry.py',
    'contracts/fixtures/credentialing-governance-packet.valid.json',
    'contracts/fixtures/credentialing-result.valid.json',
    'contracts/fixtures/credentialing-negative-paths.json',
    'contracts/fixtures/workflow-definition.valid.json',
    'contracts/fixtures/workflow-publication.valid.json',
    'contracts/fixtures/workflow-version-record.valid.json',
    'contracts/fixtures/case.valid.json',
    'contracts/fixtures/task.valid.json',
    'contracts/fixtures/workflow-event.valid.json',
    'flows/submit-and-route.contract.json',
    'flows/tesl-email-to-approval.contract.json',
    'flows/credentialing-intake-and-handoff.contract.json',
    'flows/imported-source-record-review.contract.json',
    'config/capability-packs.example.json',
    'config/agent-registry.example.json',
    'config/workflow-editor-catalog.example.json',
    'config/credentialing-approval-templates.example.json',
    'config/role-assignments.example.json',
    'config/track-execution-manifest.example.json',
    'src/solutions/CareOpsApprove/Other/Solution.xml',
    'src/solutions/CareOpsApprove/Other/Customizations.xml',
    '.github/workflows/validate.yml',
    '.github/workflows/credentialing-contracts.yml'
)

$validationScripts = @(
    'scripts/Test-Contracts.ps1',
    'scripts/Test-AiReview.ps1',
    'scripts/Test-SolutionSource.ps1',
    'scripts/Test-WorkflowContracts.ps1',
    'scripts/Test-SharePointContracts.ps1',
    'scripts/Test-WorkflowScenarios.ps1',
    'scripts/Test-FlowBlueprint.ps1',
    'scripts/Test-OutlookHistoricalBackfill.ps1',
    'scripts/Test-OutlookHistoricalBackfillDefinition.ps1',
    'scripts/Test-OutlookHistoricalBackfillEvidence.ps1',
    'scripts/Test-TeslApprovalArtifacts.ps1',
    'scripts/Test-TemplateCatalog.ps1',
    'scripts/Test-IntegrationRoadmap.ps1',
    'scripts/Test-TenantReadiness.ps1',
    'scripts/Test-BpmnArtifacts.ps1',
    'scripts/Test-DecisionScenarios.ps1',
    'scripts/Test-AdministrationScenarios.ps1',
    'scripts/Test-HandoffPackage.ps1',
    'scripts/Test-ToolingManifest.ps1',
    'scripts/Test-PacxForkToolchain.ps1',
    'scripts/Test-PacxFlowHealth.ps1',
    'scripts/Test-Coverage.ps1',
    'scripts/Test-CapabilityMatrix.ps1',
    'scripts/Test-PlannerSync.ps1',
    'scripts/Test-TrackExecutionManifest.ps1',
    'scripts/Test-ServiceMetrics.ps1',
    'scripts/Test-RequesterStatus.ps1',
    'scripts/Test-AiDecisionAnnotation.ps1',
    'scripts/Test-Reconciliation.ps1',
    'scripts/Test-SubmissionQuality.ps1',
    'scripts/Test-BusinessCalendarRouting.ps1',
    'scripts/Test-PrivacyRetentionAccessibility.ps1',
    'scripts/Test-DataverseReviewSurface.ps1',
    'scripts/Test-CredentialingContracts.ps1',
    'scripts/Test-WorkflowDefinition.ps1',
    'scripts/Test-WorkflowApiContracts.ps1',
    'scripts/Test-WorkflowStudioContracts.ps1',
    'scripts/Test-WorkflowStudioUi.ps1'
)

$missing = @($coreRequired + $validationScripts) | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf)
}
if ($missing.Count -gt 0) {
    throw "Missing required files: $($missing -join ', ')"
}

if (-not $SkipRemoteTopology) {
    $remoteNames = @(git -C $root remote)
    if ($LASTEXITCODE -ne 0 -or $remoteNames.Count -lt 1) {
        throw 'The repository must have at least one configured remote.'
    }
    if ($remoteNames -contains 'origin') {
        $origin = [string](git -C $root remote get-url origin 2>$null)
        if ($LASTEXITCODE -ne 0 -or $origin -notmatch '(?i)(github\.com[:/])edithatogo/careops-approve(?:\.git)?$') {
            throw "The origin remote must reference the canonical CareOps Approve repository; found '$origin'."
        }
    }

    $upstream = [string](git -C $root rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>$null)
    if ($LASTEXITCODE -eq 0 -and $upstream -notmatch '^[^/]+/.+$') {
        throw "The current branch has an invalid upstream reference: '$upstream'."
    }
}

$metadataPath = Join-Path $root 'conductor/tracks/basic_submit_approve_20260710/metadata.json'
$metadata = Get-Content -Raw -LiteralPath $metadataPath | ConvertFrom-Json
if ($metadata.track_id -ne 'basic_submit_approve_20260710') {
    throw 'Track metadata contains an unexpected track_id.'
}

$trackedFiles = @(git -C $root ls-files --cached --others --exclude-standard)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to enumerate tracked files.'
}

foreach ($pattern in @('.env', '.pac/')) {
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

foreach ($relativeScript in $validationScripts) {
    Write-Host "==> $relativeScript"
    & (Join-Path $root $relativeScript)
}

Write-Output 'Repository validation passed.'

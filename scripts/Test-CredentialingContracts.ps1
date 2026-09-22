[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Check {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [bool]$Passed,
        [Parameter(Mandatory = $true)]
        [string]$Detail
    )

    $prefix = if ($Passed) { '[PASS]' } else { '[FAIL]' }
    Write-Host "$prefix $Name - $Detail"
    if (-not $Passed) {
        $script:failures.Add("$Name - $Detail")
    }
}

function Read-JsonObject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing credentialing contract file: $RelativePath"
    }
    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -Depth 100
}

function Get-Step {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Contract,
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    return @($Contract.steps | Where-Object { $_.id -eq $Id }) | Select-Object -First 1
}

function Test-RequiredProperties {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Value,
        [Parameter(Mandatory = $true)]
        [string[]]$Required,
        [Parameter(Mandatory = $true)]
        [string]$Context
    )

    $properties = @($Value.PSObject.Properties.Name)
    foreach ($name in $Required) {
        Add-Check -Name "$Context property $name" -Passed ($properties -contains $name) -Detail 'required property present'
    }
}

function Get-NegativePathOutcome {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Case
    )

    if ($Case.duplicateDetected -eq $true) {
        return 'linked-to-existing-request'
    }
    if ($Case.importedSourceReconciliationStatus -eq 'pending-human-review' -and $Case.governanceHandoffAttempted -eq $true) {
        return 'blocked-source-reconciliation-required'
    }
    if ($Case.pathwayCode -in @('interim', 'emergency', 'disaster') -and [string]::IsNullOrWhiteSpace([string]$Case.temporaryApprovalExpiry)) {
        return 'blocked-hard-expiry-required'
    }
    if ($Case.aiFinalOutcomeAttempted -eq $true) {
        return 'blocked-ai-cannot-finalise'
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$Case.outboundContractVersion) -and $Case.outboundContractVersion -ne '0.1.0') {
        return 'blocked-contract-version-mismatch'
    }
    if ($Case.credentialingOfficerReviewed -ne $true -and $Case.governanceHandoffAttempted -eq $true) {
        return 'blocked-human-review-required'
    }
    return 'unexpected-pass'
}

$intakeContract = Read-JsonObject 'flows/credentialing-intake-and-handoff.contract.json'
$importContract = Read-JsonObject 'flows/imported-source-record-review.contract.json'
$packetSchema = Read-JsonObject 'contracts/credentialing-governance-packet.schema.json'
$resultSchema = Read-JsonObject 'contracts/credentialing-result.schema.json'
$sourceSchema = Read-JsonObject 'contracts/existing-system-source-record.schema.json'
$validPacket = Read-JsonObject 'contracts/fixtures/credentialing-governance-packet.valid.json'
$validResult = Read-JsonObject 'contracts/fixtures/credentialing-result.valid.json'
$negativeFixture = Read-JsonObject 'contracts/fixtures/credentialing-negative-paths.json'

Add-Check -Name 'credentialing intake remains disabled' -Passed ($intakeContract.status -eq 'blueprint-disabled-by-default') -Detail ([string]$intakeContract.status)
Add-Check -Name 'credentialing intake version' -Passed ($intakeContract.contractVersion -eq '0.1.0') -Detail ([string]$intakeContract.contractVersion)

$compatibility = $intakeContract.contractCompatibility
Add-Check -Name 'outbound governance contract name' -Passed ($compatibility.outboundGovernancePacket -eq 'careops-approve-credentialing-governance-packet-0.1.0') -Detail ([string]$compatibility.outboundGovernancePacket)
Add-Check -Name 'inbound result contract name' -Passed ($compatibility.inboundGovernanceResult -eq 'careops-decisions-credentialing-result-0.1.0') -Detail ([string]$compatibility.inboundGovernanceResult)
Add-Check -Name 'outbound process event contract name' -Passed ($compatibility.outboundProcessEvents -eq 'careops-process-credentialing-events-0.1.0') -Detail ([string]$compatibility.outboundProcessEvents)
Add-Check -Name 'legacy source contract name' -Passed ($compatibility.legacySourceObservation -eq 'careops-existing-system-source-record-0.1.0') -Detail ([string]$compatibility.legacySourceObservation)

$buildPacket = Get-Step -Contract $intakeContract -Id 'build-governance-packet'
$receiveResult = Get-Step -Contract $intakeContract -Id 'receive-governance-result-reference'
$releaseGate = Get-Step -Contract $intakeContract -Id 'release-and-register-gate'
$aiStep = Get-Step -Contract $intakeContract -Id 'run-optional-document-triage'
$humanReview = Get-Step -Contract $intakeContract -Id 'credentialing-officer-review'
$processEvents = Get-Step -Contract $intakeContract -Id 'emit-process-events'

Add-Check -Name 'packet target matches versioned contract' -Passed ($buildPacket.targetContract -eq $compatibility.outboundGovernancePacket) -Detail ([string]$buildPacket.targetContract)
Add-Check -Name 'result source matches versioned contract' -Passed ($receiveResult.sourceContract -eq $compatibility.inboundGovernanceResult) -Detail ([string]$receiveResult.sourceContract)
Add-Check -Name 'process event target matches versioned contract' -Passed ($processEvents.targetContract -eq $compatibility.outboundProcessEvents) -Detail ([string]$processEvents.targetContract)
Add-Check -Name 'credentialing officer review mandatory' -Passed ($humanReview.type -eq 'mandatory-human-review') -Detail ([string]$humanReview.type)
Add-Check -Name 'AI triage remains advisory' -Passed ($aiStep.authoritative -eq $false -and $aiStep.onFailure -eq 'continue-to-ordinary-human-review') -Detail 'AI cannot become the controlling path'
Add-Check -Name 'release integration disabled for MVP' -Passed ($releaseGate.disabledForInitialMvp -eq $true) -Detail 'authoritative write remains separate'
Add-Check -Name 'result reference does not replace decision record' -Passed ($receiveResult.doesNotReplaceAuthoritativeDecisionRecord -eq $true) -Detail 'decision record boundary preserved'

$requiredFailurePaths = @(
    'missing-profile-preserves-request',
    'invalid-data-does-not-create-governance-handoff',
    'duplicate-does-not-create-second-case',
    'ai-failure-preserves-human-path',
    'ai-output-never-finalizes-decision',
    'missing-human-review-blocks-handoff',
    'failed-integration-does-not-change-authoritative-record',
    'temporary-pathway-without-hard-expiry-is-rejected',
    'contract-version-mismatch-blocks-handoff'
)
foreach ($failurePath in $requiredFailurePaths) {
    Add-Check -Name "failure path $failurePath" -Passed (@($intakeContract.failurePaths) -contains $failurePath) -Detail 'required failure path present'
}

Add-Check -Name 'packet schema version' -Passed ($packetSchema.properties.contractVersion.const -eq '0.1.0') -Detail 'packet schema pinned'
Add-Check -Name 'packet schema fail closed' -Passed ($packetSchema.additionalProperties -eq $false) -Detail 'unexpected properties prohibited'
Add-Check -Name 'temporary expiry rule present' -Passed (@($packetSchema.allOf).Count -ge 1) -Detail 'temporary pathways require expiry'
Add-Check -Name 'result schema requires human decision' -Passed ($resultSchema.properties.humanDecisionConfirmed.const -eq $true) -Detail 'human decision required'
Add-Check -Name 'result schema prohibits authoritative write' -Passed ($resultSchema.properties.authoritativeRegisterUpdated.const -eq $false) -Detail 'MVP non-authoritative'
Add-Check -Name 'result schema prohibits release confirmation' -Passed ($resultSchema.properties.releaseToPractiseConfirmed.const -eq $false) -Detail 'release control remains downstream'
Add-Check -Name 'legacy source schema remains pending review' -Passed ($sourceSchema.properties.reconciliationStatus.const -eq 'pending-human-review') -Detail 'source observations require reconciliation'
Add-Check -Name 'legacy source schema stores no raw payload' -Passed ($sourceSchema.properties.rawPayloadStored.const -eq $false) -Detail 'raw payload excluded'

$packetRequired = @($packetSchema.required | ForEach-Object { [string]$_ })
Test-RequiredProperties -Value $validPacket -Required $packetRequired -Context 'valid packet'
$resultRequired = @($resultSchema.required | ForEach-Object { [string]$_ })
Test-RequiredProperties -Value $validResult -Required $resultRequired -Context 'valid result'

$packetFields = @($buildPacket.contains | ForEach-Object { [string]$_ })
foreach ($requiredName in $packetRequired) {
    Add-Check -Name "packet contract contains $requiredName" -Passed ($packetFields -contains $requiredName) -Detail 'flow and schema aligned'
}
$resultFields = @($receiveResult.requires | ForEach-Object { [string]$_ })
foreach ($requiredName in $resultRequired) {
    Add-Check -Name "result contract requires $requiredName" -Passed ($resultFields -contains $requiredName) -Detail 'flow and schema aligned'
}

Add-Check -Name 'valid result is human confirmed' -Passed ($validResult.humanDecisionConfirmed -eq $true) -Detail 'human decision recorded'
Add-Check -Name 'valid result remains non-authoritative' -Passed ($validResult.authoritativeRegisterUpdated -eq $false -and $validResult.releaseToPractiseConfirmed -eq $false) -Detail 'no production effect'

foreach ($case in @($negativeFixture.cases)) {
    $actual = Get-NegativePathOutcome -Case $case
    Add-Check -Name "negative path $($case.id)" -Passed ($actual -eq $case.expected) -Detail "expected=$($case.expected); actual=$actual"
}

Add-Check -Name 'imported record flow disabled' -Passed ($importContract.enabled -eq $false) -Detail 'source import disabled by default'
Add-Check -Name 'imported record authority read only' -Passed ($importContract.authority -eq 'read-only-observation') -Detail ([string]$importContract.authority)
Add-Check -Name 'imported record requires human confirmation' -Passed (@($importContract.steps | Where-Object { $_.id -eq 'confirm-observation' }).Count -eq 1) -Detail 'human confirmation step present'
Add-Check -Name 'imported record cannot write production' -Passed ($importContract.productionWrites -eq $false) -Detail 'production writes disabled'

if ($failures.Count -gt 0) {
    throw "$($failures.Count) credentialing contract check(s) failed."
}

Write-Host 'Credentialing intake and handoff contract validation passed.'

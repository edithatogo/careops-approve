[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$null = Add-Type -AssemblyName System.Xml.Linq
$root = Split-Path -Parent $PSScriptRoot
$ns = [System.Xml.Linq.XNamespace]::Get('http://www.omg.org/spec/BPMN/20100524/MODEL')
$models = @(
    @{ Name = 'submit-and-route'; ProcessId = 'Process_Submit_Route' },
    @{ Name = 'tesl-email-to-approval'; ProcessId = 'Process_TESL_Email_Approval' }
)

foreach ($model in $models) {
    $bpmnPath = Join-Path $root "workflows/$($model.Name).bpmn"
    $mmdPath = Join-Path $root "workflows/$($model.Name).mmd"
    $svgPath = Join-Path $root "workflows/$($model.Name).svg"
    foreach ($path in @($bpmnPath, $mmdPath, $svgPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing process artefact: $path" }
    }
    $document = [System.Xml.Linq.XDocument]::Load($bpmnPath)
    if (-not $document.Root -or $document.Root.Name.LocalName -ne 'definitions') { throw "Invalid BPMN definitions: $bpmnPath" }
    $process = $document.Root.Element($ns + 'process')
    if (-not $process -or $process.Attribute('id').Value -ne $model.ProcessId) { throw "Unexpected BPMN process ID: $bpmnPath" }
    if ($process.Elements($ns + 'startEvent').Count -lt 1 -or $process.Elements($ns + 'endEvent').Count -lt 1) { throw "BPMN process lacks start/end events: $bpmnPath" }
    if ((Get-Content -Raw $svgPath) -notmatch '<svg\b') { throw "Visual is not SVG: $svgPath" }
}

Write-Output 'BPMN and visual artefact validation passed.'

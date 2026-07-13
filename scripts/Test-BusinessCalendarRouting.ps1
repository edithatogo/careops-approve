$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$contract = Get-Content (Join-Path $root 'config/business-calendar-routing.example.json') -Raw | ConvertFrom-Json
$fixtures = Get-Content (Join-Path $root 'config/business-calendar-routing-fixtures.example.json') -Raw | ConvertFrom-Json
if ($contract.routingMode -ne 'prospective-only' -or $contract.absenceResolution.inFlightAction -ne 'do-not-reassign') { throw 'Calendar routing must be prospective and preserve in-flight assignments.' }
if ($contract.degradedMode.calendarUnavailable -ne 'elapsed-day-sla') { throw 'Calendar-unavailable fallback is unsafe.' }
function Add-BusinessDays($start, $count, $holidays) { $date=[datetime]::Parse($start); $added=0; while($added -lt $count){$date=$date.AddDays(1); if($date.DayOfWeek -notin @('Saturday','Sunday') -and @($holidays) -notcontains $date.ToString('yyyy-MM-dd')){$added++}}; return $date.ToString('yyyy-MM-dd') }
foreach ($scenario in @($fixtures.scenarios)) {
  if ($scenario.businessDaysToAdd) { if ((Add-BusinessDays $scenario.start $scenario.businessDaysToAdd $scenario.holidays) -ne $scenario.expectedDue) { throw "Scenario $($scenario.name) due date mismatch." } }
  elseif ($scenario.inFlight) { if ($scenario.expected -ne 'retain-primary-and-record-exception') { throw "Scenario $($scenario.name) mismatch." } }
  elseif ($scenario.calendarAvailable -eq $false) { if ($scenario.expected -ne 'elapsed-day-sla') { throw "Scenario $($scenario.name) mismatch." } }
  elseif ($scenario.absence) { if ($scenario.expected -ne 'route-to-ea') { throw "Scenario $($scenario.name) mismatch." } }
}
Write-Output "Business calendar routing validation passed: $(@($fixtures.scenarios).Count) scenarios."

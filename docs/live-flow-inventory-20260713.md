# Sanitized live Power Automate inventory

Inventory date: 2026-07-13  
Source: authenticated PAC read-only commands and the Power Automate maker surface.  
Repository boundary: this file intentionally excludes tenant IDs, environment URLs,
flow GUIDs, connection IDs, UPNs, payloads, run links, tokens, and screenshots.

## Authentication and scope

- PAC profile `careops-owner` authenticated successfully with the current NSW Health
  account using device-code sign-in.
- PAC can enumerate the available environments and Dataverse solutions.
- The developer environment contains the managed solution
  `MSCG_OperationalInbox` (version `1.0.11`).
- PAC does not provide a cloud-flow subcommand. A managed solution cannot be
  exported as an unmanaged source package, so structural flow export remains a
  maker-surface or solution-source task.

## Maker-surface inventory

The authenticated maker surface reported 34 cloud flows. One flow was flagged as
corrupted and could not be displayed. The following relevant flow families were
visible:

| Family | Visible flow names | Observed state | Source mapping |
| --- | --- | --- | --- |
| Basic approval and escalation | `Approval Escalation Engine`; `MSCG - M+M - Action Overdue Escalation` | Enabled; corrupted/unavailable respectively | `submit-and-route.contract.json`; escalation controls |
| TESL intake | `TESL Email Capture`; `TESL Historical Import Stager`; `TESL Historical Import Processor`; `TESL Historical Import Job Recovery` | Enabled | `tesl-email-to-approval.contract.json` |
| Form2 intake | `Form2InputNormalizer`; `Form2ConfidenceRouter`; `Form2ExtractionService`; `Form2CanonicalApprovalEntry` | Disabled | `dataverse-review-surface.example.json`; TESL intake safeguards |
| Existing operational patterns | `Leader Rounding - Teams Escalation Approvals v2`; `Leader Rounding - Dynamic Roster Reallocation v2`; `Leader Rounding - Weekly Collation`; `Leader Rounding - Dual Calendar Sync and Delegate Invite` | Disabled | Reuse evidence only; not CareOps runtime components |
| Shift-report intake | `Shift Reports Intake`; `ShiftReportsIntake`; `ShiftReportAttachmentExtractor` | Mixed enabled/disabled | Reuse evidence only; not CareOps runtime components |

Other visible flows were not mapped into CareOps because their names indicate
separate operational domains. They remain outside this repository's source and
deployment boundary.

## TESL flow evidence

The details surface for `TESL Email Capture` showed:

- current authenticated account as the sole owner;
- Dataverse and Office 365 Outlook connection references;
- reference from the managed `MSCG_OperationalInbox` solution;
- four successful runs visible in the recent run history, including activity on
  2026-07-13; and
- no error runs in the displayed seven-day error trend.

This confirms that a live TESL email-capture flow exists and is operationally
reachable. It does not prove that it implements the full CareOps contract,
Teams approval creation, AI annotation, Planner projection, or 14-day EDMS
escalation. Those remain pilot assertions requiring flow-definition inspection
and a controlled test submission.

## Reconciliation outcome

The live inventory is now captured at a sanitized, family-level resolution. The
remaining work is to obtain a source-readable definition for the relevant flows,
compare actions and connection references against the tenant-neutral contracts,
and repair only an explicitly authorised duplicate or broken component. No live
flow was changed during this inventory.

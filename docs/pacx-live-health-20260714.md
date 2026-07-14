# PACX live flow health check

Check date: 2026-07-14  
Tool source: `edithatogo/pacx`, branch `master`, built locally for `net10.0`.  
Repository boundary: no environment IDs, URLs, flow IDs, UPNs, tokens, payloads,
or connection secrets are stored here.

## Tooling result

- Microsoft PAC authentication remains valid for the current NSW Health account.
- The PACX fork authenticated successfully to the developer environment and
  completed a Dataverse connection check.
- PACX `workflow list --solution MSCG_OperationalInbox --category ModernFlow`
  returned 17 modern-flow records.
- PACX cloud-flow commands (`flow list`, `flow get`, and `flow export`) reached
  the Power Automate management API but the current delegated token was rejected
  by that API because it was issued with an unsupported proof-of-possession
  authentication scheme. No flow was changed.

## Solution state

| State | Count | Meaning |
| --- | ---: | --- |
| Activated | 7 | Dataverse records report activated state; runtime success still requires recent run evidence. |
| Draft | 10 | Not production-ready and must not be activated without definition and connection review. |
| Total | 17 | Modern-flow records in the named solution. |

The activated records include the four TESL flows, `Shift Reports Intake`,
`Locum Queued Import Processor`, and `Email Mining Engine FINAL`. The draft
records include the Form2/intake family and other operational prototypes.

## CareOps reconciliation finding

The live solution inventory contains no exact flow names matching the source
contracts' intended `CareOps Submit and Route` or `CareOps TESL Email to Approval`
deployments. The repository's earlier executive-confirmed attestation is retained
as historical evidence, but the latest authenticated inventory cannot confirm
those two names as currently deployed. This is a reconciliation blocker, not a
basis for activating an unrelated draft flow.

## Required next action

Obtain a source-readable definition or approved export for the intended CareOps
flows, map it to the tenant-neutral contracts, and run a controlled test in a
non-production or explicitly approved pilot path. Only then should a specific
flow be activated, repaired, or replaced.

# Process model index

Each implemented CareOps Approve process has three synchronized artefacts:

| Process | Contract | BPMN 2.0 source | Mermaid source | Visual representation |
|---|---|---|---|---|
| Submit and route | `../flows/submit-and-route.contract.json` | `submit-and-route.bpmn` | `submit-and-route.mmd` | `submit-and-route.svg` |
| TESL email to approval | `../flows/tesl-email-to-approval.contract.json` | `tesl-email-to-approval.bpmn` | `tesl-email-to-approval.mmd` | `tesl-email-to-approval.svg` |

The BPMN files are tenant-neutral and non-executable. Mermaid files are the
editable visual source; SVG files are reviewable renderings. Live exports must
not be committed without sanitization and approval.

The TESL model also includes idempotent email intake, duplicate suppression,
sanitized telemetry, failed-extraction routing, and an owner-only manual
correction queue. These controls were adapted from existing TESL capture work
and remain tenant-neutral here.

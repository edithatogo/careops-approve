# CareOps Approve capability matrix

Status values distinguish source-controlled capability from live tenant evidence.
"Conditional" means the feature is technically available but cannot be activated
with the current no-admin, no-Entra-app authority.

| Capability | Position | Current evidence | No-admin path | Blocking dependency | Conductor track |
|---|---|---|---|---|---|
| Basic Teams submit and approve | Included; live verification pending | Native Approvals smoke test and tenant-neutral contracts | Yes | Pilot execution and evidence | `basic_submit_approve_20260710` |
| TESL email intake | Included; pilot pending | Outlook mapping, BPMN, idempotency and correction contracts | Yes | Live mailbox/connection verification | `tesl_email_intake_20260712` |
| Duplicate suppression | Included; pilot pending | Deterministic source-message key and replay tests | Yes | Controlled duplicate-email pilot | `idempotency_duplicate_safety_20260712` |
| Failed extraction correction queue | Included; pilot pending | Owner correction and replay contracts | Yes | Live malformed/corrected submission pilot | `failure_correction_queue_20260712` |
| Teams status and owner reporting | Included; pilot pending | Sanitized telemetry and owner-only summary contract | Yes | Live Teams/SharePoint bindings | `telemetry_owner_reporting_20260712` |
| Dynamic roster, EA delegation and 14-day escalation | Included; pilot pending | Prospective roster, immutable assignment and EDMS contracts | Yes | Authorised tenant roster and live pilot | `teams_roster_delegation_20260712` |
| Advisory AI review | Source implemented; live invocation pending | AI schema, redaction and no-autonomous-decision tests | Conditional | AI Builder capacity, licensing, region and governance | `advisory_ai_review_20260711` |
| Dataverse review surface | Assessed; not activated | Read-only surface and fallback contract | Conditional | Dataverse, licensing and environment permissions | `dataverse_review_surface_20260712` |
| Approved desktop/intranet execution | Blueprint only | Approved-only execution, retry and rollback contract | Conditional | Registered machine/group and approved intranet access | `desktop_intranet_boundary_20260712` |
| Live flow export, deduplication and source reconciliation | Proposed | PAC/PACX toolchain and deployment contracts | Yes after delegated sign-in | Working PAC profile and maker access | `live_flow_reconciliation_20260713` |
| Reusable template catalogue and request-type routing | Proposed | Existing TESL and EDMS template examples | Yes | Template-owner approval and pilot data | `template_catalog_routing_20260713` |
| Business calendar and absence-aware routing | Proposed | Timeout and fallback contracts | Partly | Calendar source; full OOF automation may require kit/Graph permissions | `business_calendar_absence_routing_20260713` |
| Submission quality and evidence checks | Proposed | Deterministic validation and advisory AI boundary | Yes | Approved field rules and safe link policy | `submission_quality_evidence_20260713` |
| Operational reconciliation and orphan repair | Proposed | Immutable outcome and failure-state contracts | Yes | Live approval and state-store access | `operational_reconciliation_20260713` |
| Privacy, retention and accessible/mobile operation | Proposed | Restricted visibility and publication boundary | Partly | Tenant retention labels and policy confirmation | `privacy_retention_accessibility_20260713` |
| Business Approvals Kit | Conditional; evaluate only | Microsoft kit supports versioned stages, conditions and OOF handling | No | Non-default Dataverse environment, licenses, managed solution installation and elevated environment roles | No implementation track until prerequisites are approved |
| Microsoft Graph Approvals API | Blocked | API could create, update, list and subscribe to approvals | No | Entra application registration, OAuth permissions and consent | No implementation track under current authority |
| Custom Teams app, bot or Microsoft 365 agent | Blocked | Local Agents Toolkit is diagnostic only | No | Custom-app upload policy, Entra identity and tenant approval | No implementation track under current authority |
| Managed Power Platform Pipelines host | Blocked | Repo contains packaging and deployment workflow contracts | No | Dataverse host, Managed Environments and administrator/system-administrator setup | Retain GitHub Actions packaging as the available fallback |
| Tenant DLP, retention, environment or app-policy changes | Blocked | Requirements are documented as release gates | No | Power Platform/Teams/Compliance administrator | Escalate as a tenant-owner decision |

## Recommended delivery order

1. Authenticate PAC and reconcile the live flows with source.
2. Pilot the existing submit, TESL, duplicate, correction, roster and escalation paths.
3. Add the template catalogue and deterministic submission-quality checks.
4. Add owner reporting, operational reconciliation and privacy/accessibility controls.
5. Trial advisory AI only after its tenant gates pass.
6. Reconsider Dataverse, the Business Approvals Kit, Graph and managed pipelines only
   if administrative authority and licensing become available.

## Issue traceability

GHE is the current work authority; GitHub.com is the private continuity mirror.

| Track | GHE | GitHub.com |
|---|---|---|
| `basic_submit_approve_20260710` | [#1](https://nswhealth.ghe.com/60217257/careops-approve/issues/1) | [#3](https://github.com/edithatogo/careops-approve/issues/3) |
| `approvals_app_integration_roadmap_20260712` | [#4](https://nswhealth.ghe.com/60217257/careops-approve/issues/4) | [#6](https://github.com/edithatogo/careops-approve/issues/6) |
| `tesl_email_intake_20260712` | [#5](https://nswhealth.ghe.com/60217257/careops-approve/issues/5) | [#7](https://github.com/edithatogo/careops-approve/issues/7) |
| `idempotency_duplicate_safety_20260712` | [#6](https://nswhealth.ghe.com/60217257/careops-approve/issues/6) | [#8](https://github.com/edithatogo/careops-approve/issues/8) |
| `failure_correction_queue_20260712` | [#7](https://nswhealth.ghe.com/60217257/careops-approve/issues/7) | [#9](https://github.com/edithatogo/careops-approve/issues/9) |
| `telemetry_owner_reporting_20260712` | [#8](https://nswhealth.ghe.com/60217257/careops-approve/issues/8) | [#10](https://github.com/edithatogo/careops-approve/issues/10) |
| `teams_roster_delegation_20260712` | [#9](https://nswhealth.ghe.com/60217257/careops-approve/issues/9) | [#11](https://github.com/edithatogo/careops-approve/issues/11) |
| `dataverse_review_surface_20260712` | [#10](https://nswhealth.ghe.com/60217257/careops-approve/issues/10) | [#12](https://github.com/edithatogo/careops-approve/issues/12) |
| `desktop_intranet_boundary_20260712` | [#11](https://nswhealth.ghe.com/60217257/careops-approve/issues/11) | [#13](https://github.com/edithatogo/careops-approve/issues/13) |
| `advisory_ai_review_20260711` | [#12](https://nswhealth.ghe.com/60217257/careops-approve/issues/12) | [#14](https://github.com/edithatogo/careops-approve/issues/14) |
| `live_flow_reconciliation_20260713` | [#13](https://nswhealth.ghe.com/60217257/careops-approve/issues/13) | [#15](https://github.com/edithatogo/careops-approve/issues/15) |
| `template_catalog_routing_20260713` | [#14](https://nswhealth.ghe.com/60217257/careops-approve/issues/14) | [#16](https://github.com/edithatogo/careops-approve/issues/16) |
| `business_calendar_absence_routing_20260713` | [#15](https://nswhealth.ghe.com/60217257/careops-approve/issues/15) | [#17](https://github.com/edithatogo/careops-approve/issues/17) |
| `submission_quality_evidence_20260713` | [#16](https://nswhealth.ghe.com/60217257/careops-approve/issues/16) | [#18](https://github.com/edithatogo/careops-approve/issues/18) |
| `operational_reconciliation_20260713` | [#17](https://nswhealth.ghe.com/60217257/careops-approve/issues/17) | [#19](https://github.com/edithatogo/careops-approve/issues/19) |
| `privacy_retention_accessibility_20260713` | [#18](https://nswhealth.ghe.com/60217257/careops-approve/issues/18) | [#20](https://github.com/edithatogo/careops-approve/issues/20) |

## Microsoft capability references

- [Approvals app APIs](https://learn.microsoft.com/en-us/graph/approvals-app-api)
- [Business Approvals Kit content](https://learn.microsoft.com/en-us/power-automate/guidance/business-approvals-templates/content)
- [Configure preset approvals](https://learn.microsoft.com/en-us/power-automate/guidance/business-approvals-templates/configure-preset-approvals)
- [Business Approvals Kit setup](https://learn.microsoft.com/en-us/power-automate/guidance/business-approvals-templates/setup)
- [Custom pipelines host prerequisites](https://learn.microsoft.com/en-us/power-platform/alm/custom-host-pipelines)

# Native Microsoft 365 synthetic pilot

Status: source built and locally tested; Microsoft tenant execution unverified.
Predecessor: careops#164, merged at 893819426324e8a09ad7784c7a47929b61c23f26.
Delivery slice: N01-P02, native no-admin pilot assets. Full N01 remains open.

This pack lets an authorised user rehearse preparation and human-review states
using native Lists and an optional connector-free instant Power Automate flow.
It needs no custom Entra application, tenant administrator or other CareOps
module. It DOES need permitted work-account access, list/view management rights
and, for the optional flow, the existing maker entitlement and policy permission.
No Python, custom connector, Graph access or premium AI is needed by operators.
The production app remains full Dataverse and has separate deployment gates.

## Lists rehearsal

1. In an approved service-owned SharePoint site, use New list / From CSV and
   select `cases.csv`. Name it `CareOps SYNTHETIC pilot - NOT FOR PRACTICE`.
   Keep the first column as Title. Create CaseRevision and CheckedRevision as
   Number with zero decimal places; keep the other fields as single-line text.
   Keep these internal column names exactly as supplied, with no inserted spaces.
   If your interface does not offer CSV import, create those columns and paste
   the eight supplied rows using Edit in grid view. Do not use a real export.
2. Restrict site/list membership to the pilot group, disable attachments and
   retain all ten fields in the test view. DataClass and synthetic identifiers
   are labels, not security or a filter that detects real information.
3. On Assessment, choose Column settings / Format this column / Advanced mode.
   Paste `assessment.column.json`, preview and save. It uses permitted native
   formatting, not executable JavaScript. Colour is accompanied by text.
4. Check scenarios below. Change a synthetic evidence state or revision to
   rehearse an exception. The case owner reviews in the same row, not another
   approval queue. No action in this pack sends correspondence or grants scope.

Formatting does NOT change the stored Assessment cell. Its stored text remains
`SYNTHETIC - DISPLAY ONLY`; exports and filters are not computed decision records.
The visible preparation label is a view expression and not a persistent register.
Show every input column so multiple findings remain visible. Missing required
columns, bad types or a rendering error fail the pilot acceptance: stop and fix
configuration, never treat an absent indicator as green. This is not an
access-control mechanism, authenticated revision check or verification service.

## Optional connector-free Power Automate rehearsal

`preparation.definition.json` is a native Workflow Definition Language source,
NOT a tenant-exported import ZIP or managed solution. Build it once in the
permitted designer; do not upload the JSON to the Import package screen.

Create an Instant cloud flow with Manually trigger a flow and one required Text
input titled Synthetic fixture. Use only the eight SYNTHETIC identifiers below.
The provided definition uses its first text input's internal key `text`; confirm
that key in your designer, rather than substituting a practitioner identifier.
Add these named native actions in order:

| Action | Designer configuration |
| --- | --- |
| Cases | Data Operations / Compose; paste the fixed object at `actions.Cases.inputs` from the definition. |
| Fixture | Compose; expression `outputs('Cases')?[triggerBody()?['text']]`. |
| Check_fixture | Condition; `empty(outputs('Fixture'))` equals true. True branch: Terminate Failed, code UnsupportedSyntheticFixture. |
| Preparation | False branch Compose; paste the expression at `actions.Check_fixture.else.actions.Preparation.inputs`, removing the leading `@` when using the Expression editor. |
| Receipt | False branch Compose after Preparation; select its output plus fixed labels decisionAuthority=none, agentExecution=simulated-or-disabled, externalActions=none, dataClass=SYNTHETIC, as in the definition. |

Save and run all fixtures. Inspect Receipt in run history, then run an unknown
identifier and confirm the controlled failure. There are no connectors, secrets,
HTTP calls, writes, notification actions or real agent calls in this source.
Power Automate authentication/maker rights and the tenant's existing policies
still apply. If flow creation is unavailable, the Lists rehearsal remains usable.
A future List-connected worker requires the permitted standard SharePoint
connector and independent run evidence. It is NOT included or silently enabled.

## Acceptance scenarios

| Fixture | Expected display/receipt | Purpose |
| --- | --- | --- |
| 001 | Green - prepared, NOT approved | AI off, evidence complete and human reviewed. |
| 002 | Red - draft information request | Missing administrative evidence; no message sent. |
| 003 | Amber - human review required | Simulated agent concern; no adverse outcome. |
| 004 / 005 | Unavailable | Evidence or agent service unavailable; not a practitioner refusal. |
| 006 | Amber - human review required | Existing human review still outstanding. |
| 007 | Unavailable | Check refers to an earlier synthetic case revision. |
| 008 | Red - draft information request | Missing evidence AND a simulated concern; both inputs remain visible. |

Agent values are simulated or disabled. HumanReview is a rehearsal field, not a
verified signature. No real credentials, personal identifiers, patient data,
complaints, real decisions or operational register records belong in this pack.
Do not promote these rows into production or infer clinical rules from the tests.
Stop if the pilot duplicates staff work, triggers unintended communication or
makes the information appear valid for practice. Later real-data observation
requires explicit source/privacy/access approval and a separately scoped release.

## Developer verification and closure

`python scripts/build_m365_pilot.py` checks committed files for drift.
`python scripts/build_m365_pilot.py --build` regenerates only these fixed assets.
Local Python 3.13.5: ten methods, 58 generator statements and 16 branches, 100%.
Tests cover 60 evidence/agent/human combinations, eight supplied scenarios,
missing/stale values, no external actions and reproducibility. The AST evaluator
is test-only; it does not execute Microsoft's display or flow engine. Native
save/run, keyboard/screen-reader, permissions and representative-user acceptance
remain OPEN until an authorised pilot operator records the results. CI preserves
existing safety checks and adds strict static checks on 3.13/3.14.

A completed source slice may be recorded after reviewed CI/merge; never archive
N01 or claim full pilot deployment from these source tests. Remove only the
synthetic list and rehearsal flow on pilot exit after retaining approved test
receipts; do not modify CGov, real records or any production solution.

## Microsoft primary documentation checked 23 September 2026

- https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/column-formatting
- https://support.microsoft.com/en-us/sharepoint/lists/create-a-list-from-the-lists-app
- https://learn.microsoft.com/en-us/power-automate/export-import-flow-non-solution
- https://learn.microsoft.com/en-us/azure/logic-apps/expression-functions-reference

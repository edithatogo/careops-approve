# Modular suite delivery — 18 October 2026

Administrative intake, routing and human approval capture; Decisions retains formal governance.

Apply the [shared development and delivery policy](https://github.com/edithatogo/careops/blob/main/docs/development-and-delivery.md) and
[optional standalone-module contract](https://github.com/edithatogo/careops/blob/main/docs/standalone-module-contract.md). Existing native-object/file
owners, current task selection and operational records retain precedence for
execution. This source profile does not establish target access or deployment.
The existing enterprise authority/mirror mapping is unchanged.

## Next useful improvements

The ordered cross-repository queue is in [the module profile](../.careops/module.json).
Take its first eligible task after preserving the current in-flight operation.
A completed MVP is not reopened by this queue: optional improvements follow the
selected slice and remain optional. Keep detailed progress in the existing track.
Do not create another track, chat, acceptance pack or status ledger for alignment.

1. **package** — Inspect the actual solution source and finish the smallest packageable intake-to-correction slice; distinguish scaffold-only steps.
   Done when: The existing unmanaged source package is verified in PR76; compiled/native components and deployment remain separately unqualified. Missing source does not count as a successful build.
2. **delivery** — Reuse the existing managed-release/federation pattern from Costing where this deployment supports it.
   Done when: One immutable artifact, private environment mapping and tested recovery; no identity provisioning is assumed.
3. **documents** — Qualify a maintained SharePoint template for one structured submission summary after the working intake slice.
   Done when: Actual output and retry preserve source revision and human corrections; existing fallback remains.

## Dependency and delivery defaults

Prefer the newest useful development version, resolve an exact version/commit,
and qualify affected behaviour before promotion. Retain the working version and
recovery path. Inspect actual package engines/targets; use separate Node/Python/
.NET profiles where needed. A preview tag can be older than the current release.
The portfolio baseline is dated discovery, not this repo's installed/runtime state.
Use existing CI; exact action pins and managed downstream artifacts improve
reproducibility without provisioning new identities or tenant services.

SharePoint structured document generation is the first route to evaluate for
structured outputs. Preserve source truth, human edits and issued history;
qualify actual output and recovery before replacing a working route. Generation
is not content review, approval, circulation or a change of status.

Keep one writer per object and one owner per shared authentication repair. Tools
are preferences, not exclusive leases. Send a completed deliverable or changed
blocker once; no acknowledgement polling. Reuse passed evidence and run only
checks affected by the change, with broad checks at an integration milestone.


### Qualified CI policy adoption — 19 October 2026

The source candidate aligns security, package policy, lock generation and canary
helper checkouts to immutable CareOps f0e8db252b181955d31185f1ccdd1e77dee1f5f9.
That revision passed all14PR checks and all6triggered main workflows. Refresh
only transitive certifi to2026.10.18 with official hashes, preserving direct pins,
module tests, native ownership and existing protections. This consumer still
requires all applicable current-head checks, including the actual Windows PAC
package, before normal merge. Previous workflow refs and lock provide rollback.


## Selective SharePoint library columns — 19 October 2026

User-selected implementation direction: reuse library columns for artifact identity, provenance, filtering and routing where the output already belongs in SharePoint. Reuse existing columns/content types and exact internal names before adding fields. This extends the structured-document preference; it is not proof of automatic Word-body generation.

Priority: when the next document/evidence output is implemented. Retain authoritative request/decision identity, reviewed document revision, template/source versions and output revision on supporting artifacts. Approval must remain bound to the exact reviewed revision in its authoritative record; updating a column never grants approval.

Acceptance: map each property to its existing authoritative source and verify its actual type/internal name; read back the affected saved values and file identity. Update only changed values, guard modification-trigger loops and retries, and retain a recoverable preimage. Preserve human edits, original/issued history and exact reviewed revisions. Add no duplicate register, notifications, approval workflow, permission change, licence or runtime. Avoid putting private/internal-only values into properties that may travel inside a downloaded Office file.

Metadata readback and visible body rendering are separate checks. The Clinical trial stored a changed property while Word for the web still displayed the old body value. Do not claim scalar body refresh, narrative/repeating sections or generated Word/PDF fidelity from metadata success. Qualify those behaviours only for the selected document shape; retain working/manual outputs on a specific gap. Record one result in existing evidence, not another readiness pack.

Reference: https://learn.microsoft.com/sharepoint/dev/business-apps/power-automate/sharepoint-connector-actions-triggers

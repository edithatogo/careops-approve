# Approve CI/CD adoption

- [x] Capture clean current default revision and failing immutable-reference guard.
- [x] Qualify exact actions, CI hash lock, PAC 2.13.1 and .NET 10.0.402 source packaging (PR #74; da07812).
- [x] Adopt shared security; retain all domain tests and 100% branch coverage.
- [~] Verify scheduled development tool/SDK canary and candidate receipts.
- [x] Close updater/protection gaps after actual successful hosted checks: ten app-bound required checks, strict/admin enforcement.
- [ ] Qualify real release packages with SBOM/attestations and actual optional-interface cases.
- [ ] Merge each increment only with every current-head check green; verify main and report parent evidence.

Working native profiles/flows are untouched. Manifest versions express selected
source intent; CI must verify actual installs. Existing interactive authentication
remains manual; no tenant qualification follows from offline package success.

## Actual package provenance qualification

- [x] Prepare SPDX inventory of the existing actual unmanaged solution ZIP, including binary contents, using immutable CareOps helper1373e971.
- [x] Build once; download and independently compare all file/archive digests before main-only OIDC provenance/SPDX signing.
- [ ] Qualify all PR checks and inspect actual ZIP/SBOM contents.
- [ ] Merge with every current-head check green; verify main signatures and exact source/workflow identity from downloaded artifacts.
- [ ] Complete actual optional-interface compatibility; package provenance does not establish deployment or native acceptance.

## User-selected Python migration track — 23 October 2026

Detailed Python runtime inventory, migration and handover progress is maintained
only in [the dedicated qualification plan](../python315_qualification_20261023/plan.md).
Existing completed qualification above remains historical evidence; shared CI and
release tasks stay here. Do not duplicate its open Python checklist.

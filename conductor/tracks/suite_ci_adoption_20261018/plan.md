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

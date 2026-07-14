# PACX management-plane bearer authentication

This track addresses the observed PACX failure where Dataverse authentication succeeds but the Power Automate management API rejects the acquired proof-of-possession token. It is intentionally limited to delegated, read-only inventory and must not introduce secrets into the repository.

- Conductor track: `pacx_management_bearer_auth_20260714`
- GitHub issue: [#27](https://github.com/edithatogo/careops-approve/issues/27)
- GHE issue: [#23](https://nswhealth.ghe.com/60217257/careops-approve/issues/23)
- Evidence: `docs/pacx-live-health-20260714.md`

Start with `spec.md`, then execute `plan.md` in order. A smaller implementation agent should stop at the first external authentication or permission boundary and record the exact sanitized error.

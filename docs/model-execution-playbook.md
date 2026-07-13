# Small-model execution playbook

This playbook is the deterministic entry point for implementing any active CareOps
Approve track with a smaller coding model.

## Required sequence

1. Open `config/track-execution-manifest.example.json` and select exactly one track.
2. Read the track `index.md`, `spec.md` and `plan.md` completely.
3. Check every prerequisite and stop condition before editing.
4. Mark only the first pending task `[~]`; do not start later phases.
5. Add or update the named validation first and demonstrate the missing behaviour.
6. Edit only paths listed in `writeScope`. Stop if another path is required.
7. Run the track validation, then `scripts/Test-Repository.ps1`.
8. Review the diff for UPNs, tenant IDs, URLs, connection references, payloads and secrets.
9. Stop at a tenant gate unless sanitized live evidence is available.
10. Commit one coherent task, record its short SHA in `plan.md`, and update the issue.

## Never infer

- A blueprint, contract or passing static test is not proof of live deployment.
- A Planner task is not an approval decision.
- Technical access does not create organisational delegation.
- Missing tenant/admin authority is a stop condition, not a reason to invent data.
- In-flight approvals are immutable unless an explicit audited process says otherwise.

## Required issue update

Every implementation update must state:

- task attempted;
- files changed;
- validations run and result;
- tenant evidence obtained or still missing;
- blocker, if any;
- commit SHA when complete.

Do not paste tenant payloads, screenshots, UPNs or connection identifiers into issues.


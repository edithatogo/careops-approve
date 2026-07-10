# Repository Topology and Dual Authentication

Last verified: 2026-07-10

## Current authority

| Role | Host | Account | Repository | Local remote |
| --- | --- | --- | --- | --- |
| Current authority | `nswhealth.ghe.com` | `60217257` | `60217257/careops-approve` | `origin` |
| Private mirror | `github.com` | `edithatogo` | `edithatogo/careops-approve` | `github` |

The local `main` branch tracks `origin/main`. Pull requests, environment secrets,
enterprise controls, and deployment approvals should currently be managed on GHE.
GitHub.com receives branches and tags as a private continuity mirror.

## How GitHub CLI dual authentication works

GitHub CLI stores authentication independently for each hostname. Confirm both hosts
without displaying tokens:

```powershell
gh auth status --hostname nswhealth.ghe.com
gh auth status --hostname github.com
```

Repository-aware commands infer the host from the repository remote. Commands without
repository context default to GitHub.com, so target GHE explicitly:

```powershell
gh api --hostname nswhealth.ghe.com user
$env:GH_HOST = 'nswhealth.ghe.com'
gh repo view 60217257/careops-approve
Remove-Item Env:GH_HOST
```

For an explicit repository target, use `GH_REPO` in `HOST/OWNER/REPO` form:

```powershell
$env:GH_REPO = 'nswhealth.ghe.com/60217257/careops-approve'
gh pr list
Remove-Item Env:GH_REPO
```

Git credential routing is configured separately for each host with:

```powershell
gh auth setup-git --hostname nswhealth.ghe.com
gh auth setup-git --hostname github.com
```

Do not export `GH_TOKEN` globally in an interactive shell. Token environment variables
take precedence over stored credentials and can accidentally target a command with the
wrong identity. Automation must use host-scoped secrets and set `GH_HOST` explicitly.

## Publishing

Run validation before publication:

```powershell
./scripts/Test-Repository.ps1
./scripts/Publish-Remotes.ps1 -WhatIf
./scripts/Publish-Remotes.ps1
```

The script requires a clean worktree and publishes all local branches and tags to
`origin` first, then `github`. It does not use `git push --mirror`, force-push, or
remote ref deletion.

## Controls that do not mirror with Git

Maintain a separate checklist for each host covering:

- repository visibility and collaborators;
- branch and ruleset protection;
- Actions permissions and runner policy;
- environments, reviewers, variables, and secrets;
- issues, discussions, pull requests, releases, and audit history;
- service principals, app installations, webhooks, and deployment credentials.

Personal GitHub must not receive NSW Health secrets, sensitive data, tenant exports,
or content that policy prohibits from leaving the organisation. A private mirror does
not override information-governance obligations.

## Future authority transition

When organisational departure or an approved transition occurs:

1. Confirm that all content is permitted to remain in or move to the personal repository.
2. Freeze releases and reconcile branches and tags on both hosts.
3. Export or recreate only approved non-Git settings and evidence.
4. Rename remotes so GitHub.com becomes `origin` and GHE becomes `ghe-archive`.
5. Set local branches to track the new `origin/main`.
6. Update badges, links, submodule URLs, workflow environments, and documentation.
7. Run validation and create a signed transition tag on both hosts.
8. Preserve or retire the GHE repository according to NSW Health direction.

The transition is a governed operation, not an automatic date-based switch.

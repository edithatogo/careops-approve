# Repository topology and authentication

Last reviewed: 2026-08-29

## Canonical repository

The canonical repository is:

- host: `github.com`
- repository: `edithatogo/careops-approve`
- default branch: `main`

A deployment organisation may maintain an approved enterprise mirror. Mirrors
are environment and governance choices, not product requirements. The reusable
repository must not embed organisation-specific host names, managed-user IDs,
runner assumptions, tenant details, or deployment secrets.

## Local remote roles

Recommended local names are role based:

| Remote | Purpose |
| --- | --- |
| `origin` | Canonical repository for source, issues, pull requests, and releases |
| `enterprise` | Optional organisation-managed mirror or deployment authority |
| `archive` | Optional read-only continuity or historical remote |

Do not infer authority from a remote name alone. The deployment profile must
record which host owns source review, release approval, deployment evidence,
and operational support.

## Authentication

GitHub CLI stores authentication independently for each hostname. Confirm a
host without displaying tokens:

```powershell
gh auth status --hostname github.com
```

For an optional enterprise host, specify the approved hostname explicitly:

```powershell
gh auth status --hostname <enterprise-host>
```

Repository-aware commands infer the host from the selected remote. Host-
ambiguous automation must set `GH_HOST` or use a fully qualified repository.
Do not export a broad `GH_TOKEN` in an interactive shell. Automation must use
host-scoped, least-privilege credentials and protected environments.

## Validation and publication

Run repository validation before publication:

```powershell
./scripts/Test-Repository.ps1
```

Publishing scripts must:

- require a clean worktree;
- avoid force pushes and remote ref deletion;
- publish only intended branches and tags;
- verify the target host and repository;
- exclude secrets and environment values; and
- record the source commit and release artifact digest.

## Controls that do not move with Git

Maintain separate evidence for each host covering:

- visibility and collaborators;
- branch and ruleset protection;
- Actions permissions and runner policy;
- environments, reviewers, variables, and secrets;
- issues, discussions, pull requests, releases, and audit history;
- service principals, app installations, webhooks, and deployment credentials;
- code scanning, secret scanning, dependency review, and retention; and
- backup and recovery.

A private mirror does not override information-governance obligations. No host
may receive practitioner, patient, workforce, mailbox, credential, tenant, or
other sensitive material unless that host and transfer are explicitly approved.

## Authority transition

A change of canonical host or owner is a governed operation:

1. confirm ownership, licence, and information-governance authority;
2. freeze releases and reconcile branches and tags;
3. export or recreate only approved non-Git settings and evidence;
4. update remotes, branch tracking, badges, links, submodule URLs, environments,
   and documentation;
5. validate source and release parity;
6. create a signed transition record; and
7. preserve or retire the prior host according to the approved plan.

Repository history may retain historical organisation or author metadata. The
active product documentation and configuration must remain organisation-neutral.

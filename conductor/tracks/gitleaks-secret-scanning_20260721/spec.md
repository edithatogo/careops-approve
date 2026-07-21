# Specification: Gitleaks secret scanning

Configure repository-local and GitHub Actions Gitleaks scanning for all
committed history and pull-request changes, with minimal explicit exclusions
for generated local artefacts only.

## Acceptance criteria

- A pinned full-history GitHub Actions workflow runs on pull requests and pushes
  to `main`.
- `.gitleaks.toml` extends the default rules without suppressing source files.
- `SECURITY.md` documents the local command and incident response boundary.
- The current repository history passes the configured scan.

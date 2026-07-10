# General Engineering Style Guide

## Source Artifacts

- Keep exported Power Platform artifacts deterministic and reviewable.
- Use descriptive names prefixed with `CareOps Approve` for user-facing assets.
- Keep tenant-specific IDs, URLs, identities, and secrets out of source control.
- Prefer environment variables, connection references, and configuration records.

## Scripts

- Scripts must be non-interactive by default and return non-zero on failure.
- Validate all required inputs before changing an environment.
- Support a validation or dry-run mode for deployment-affecting operations.
- Document prerequisites and expected outputs near each entry point.

## Documentation

- State governance assumptions and operational ownership explicitly.
- Distinguish automated verification from manual tenant validation.
- Keep runbooks concise, sequential, and reversible where possible.

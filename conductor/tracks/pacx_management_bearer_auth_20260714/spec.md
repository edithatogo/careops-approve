# PACX management-plane bearer authentication

## Problem

The PACX fork can authenticate to Dataverse and enumerate solution workflows, but its cloud-flow command currently reaches the management API with an unsupported PoP authentication scheme. This prevents read-only flow health checks and reconciliation.

## Goal

Provide a documented, tested token path for `https://management.azure.com/.default` that sends a supported Bearer or MSAuth1.0 credential, while retaining secure delegated interactive authentication.

## Acceptance criteria

- Token acquisition explicitly distinguishes Dataverse and Power Automate management resources.
- Cloud-flow inventory reaches the management API with a supported authentication scheme; no PoP token is sent on this path.
- Silent, device-code/WAM, and system-browser fallbacks are deterministic and explain the next action without exposing tokens.
- Unit tests cover resource selection, fallback selection and failure diagnostics.
- An integration smoke test performs only a flow list/read operation against an approved non-production environment.
- No tenant-wide discovery, admin elevation, secret persistence, flow activation, deletion or mutation is added.

## Out of scope

- Creating an Entra application or requesting tenant/admin permissions.
- Changing live flows as part of tests.
- Committing profiles, refresh tokens, environment identifiers or raw API responses.

# CareOps Approve ALM strategy

## Baseline

CareOps Approve uses a solution-aware Power Platform delivery model. Source
control contains unpacked, reviewable artifacts; build jobs produce immutable
solution packages. Connection references, environment variables, identities,
secrets, and deployment settings remain environment-specific.

The stable delivery path is:

1. Maker changes occur in an approved development environment.
2. The solution is exported and unpacked into source control.
3. Pull requests run repository, contract, security, and packaging validation.
4. Authenticated CI runs Microsoft solution analysis where the tenant permits.
5. A protected deployment job imports the validated artifact into a pilot or
   test environment.
6. The same immutable artifact is promoted through approved environments.
7. Rollback redeploys the last validated managed solution; production is not
   repaired through ad hoc edits.

## Authentication and environment separation

- Use a Microsoft Entra workload identity, service principal, or another
  approved deployment identity.
- Prefer short-lived or workload-identity credentials where supported.
- Store secrets only in protected repository or deployment environments.
- Never use a maker password in CI.
- Keep development, test, pilot, and production connections separate.
- Require an explicit reviewer for production deployment.

Example environment values such as `POWERPLATFORM_URL`, application identity,
tenant ID, connection references, and deployment settings are supplied outside
source control. Checked-in examples must contain no live tenant identifiers.

## Capability packs and feature flags

The solution is modular. Optional capability packs are deployed with explicit
feature flags and environment variables. Each pack must include:

- business and technical owner;
- data classification and privacy review;
- source and authority mapping where rules are controlling;
- acceptance and negative-path tests;
- human decision and fallback path;
- support, continuity, reconciliation, and rollback;
- licensing and capacity impact; and
- measurable benefit and unintended-burden monitoring.

A pack is disabled by default until its deployment profile passes the relevant
gates. Disabling a pack must not corrupt the stable core or historical audit
records.

## Microsoft kits and platform features

The Microsoft Business Approvals Kit, Center of Excellence Starter Kit,
Copilot Studio, AI Builder, Process Mining, Dataverse MCP, and other platform
features are evaluation candidates, not automatic dependencies. A feature is
adopted only when it provides a clear benefit that exceeds its licensing,
capacity, privacy, deployment, support, and operational footprint.

For simple one-stage approvals, native Teams Approvals and standard connectors
may remain preferable. Multi-stage, reusable, delegated, or centrally managed
processes may justify a broader approvals framework after a bounded evaluation.

## Repository topology

The canonical source repository is `edithatogo/careops-approve`. Additional
enterprise mirrors may be configured by a deployment owner, but host names,
accounts, runner availability, and deployment credentials are not part of the
reusable product contract.

Repository settings, secrets, environments, issues, Actions history, rulesets,
and protection rules are not Git objects. They require host-specific evidence.
A passing check on one mirror does not prove equivalent controls on another.

## Release controls

- Pull-request validation is credential-free wherever possible.
- Secret scanning and publication-boundary checks fail closed.
- Solution analysis and deployment use protected environments.
- Production deployment requires explicit approval and immutable artifacts.
- Preview features are isolated from the stable release path.
- AI output never finalises a decision or publishes an authoritative record.
- Deployment evidence is distinct from operating-effectiveness evidence.
- Every release records version, source commit, package digest, configuration
  schema, target environment, reviewer, deployment result, and rollback target.

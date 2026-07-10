# CareOps Approve ALM Strategy

## Baseline

CareOps Approve uses a custom, solution-aware Power Platform solution. Source
control contains unpacked, reviewable artifacts; build jobs produce immutable
solution packages. Connection references, environment variables, identities, and
deployment settings remain environment-specific.

The stable delivery path is:

1. Maker changes occur in an approved development environment.
2. The solution is exported and unpacked into `src/solutions/CareOpsApprove`.
3. Pull requests run repository validation and pack the solution.
4. Authenticated CI runs Power Apps solution checker against the package.
5. A protected deployment job imports the validated package into the pilot environment.
6. Power Platform Pipelines promotes the same release artifact where the tenant
   provides an approved pipelines host and target environments.

## Authentication

- Use a Microsoft Entra service principal or an approved delegated pipeline identity.
- Store credentials only in protected GitHub or GitHub Enterprise environments.
- Prefer workload identity or short-lived credentials when supported by the selected
  Power Platform tooling; client secrets are a compatibility fallback.
- Never use a maker's password in CI.

The `pilot` GitHub environment must define `POWERPLATFORM_URL`,
`POWERPLATFORM_APP_ID`, `POWERPLATFORM_CLIENT_SECRET`, and
`POWERPLATFORM_TENANT_ID`. It should require reviewer approval. A real
The checked-in example deployment settings file contains no tenant identifiers and
is sufficient until the solution introduces environment variables or connection
references. When those exist, the deployment process must generate or retrieve a
real settings file securely rather than committing tenant-specific identifiers.

## Microsoft kits

The Microsoft Business Approvals Kit is an evaluation candidate, not an automatic
dependency. It becomes preferable when requirements expand to reusable multi-stage
processes, delegation, centralized process administration, or broader reporting.
For the initial one-stage workflow, the kit must demonstrate benefits that outweigh
its Dataverse, licensing, deployment, and support footprint.

Center of Excellence Starter Kit conventions may be reused for inventory, ownership,
and governance reporting. CareOps Approve does not require installation of the full
CoE Starter Kit merely to run the workflow.

## Repository topology

- `origin`: current authoritative NSW Health GHE repository owned by managed user
  `60217257` at `nswhealth.ghe.com`.
- `github`: private personal mirror owned by `edithatogo` at `github.com`.

The push procedure publishes branches and tags without `--mirror` deletion semantics.
Repository settings, secrets, environments, issues, Actions history, and protection
rules are not Git objects and must be configured and evidenced independently on each host.

GitHub CLI stores and selects authentication per host. Commands run in this checkout
normally infer GHE from `origin`; host-ambiguous commands must use `--hostname`, a
fully qualified repository, `GH_HOST`, or `GH_REPO`. See `repository-topology.md`.

NSW Health uses a `ghe.com` managed-user platform. Do not apply on-premises GitHub
Enterprise Server assumptions such as mandatory self-hosted runners unless live host
policy requires them.

Live policy currently disables hosted runners for this repository. Until an approved
GHE runner is assigned, the private GitHub.com mirror executes credential-free CI on
the same commit while GHE remains authoritative. This is an interim asymmetry and is
tracked explicitly; deployment must not piggyback on personal-host secrets.

## Release controls

- Pull-request validation is credential-free wherever possible.
- Solution checker and deployment jobs use protected environments.
- Production deployment requires explicit approval and immutable build artifacts.
- Preview features are isolated from the stable release path.
- Rollback means redeploying the last validated managed solution, not editing production.

Dependabot groups GitHub Actions patch and minor updates into reviewable pull
requests. Major action updates are intentionally not grouped and require an
explicit pull request review because action major versions can change runner,
permission, or input contracts. `scripts/Test-WorkflowContracts.ps1` verifies
that the repository retains the pack, checker, protected deployment, and
non-destructive publication boundaries.

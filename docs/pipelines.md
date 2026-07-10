# Power Platform promotion design

This is the promotion contract for CareOps Approve. It is ready for tenant-owner
review but does not provision environments, pipelines, service principals, or
secrets.

## Stages

| Stage | Purpose | Gate | Configuration |
| --- | --- | --- | --- |
| Development | Maker authoring and export | Solution source validation | Development connection references and environment variables |
| Pilot | Two-person workflow verification | Protected approval plus solution checker evidence | Pilot settings held in the protected `pilot` environment |
| Production | Wider adoption after governance decision | Separate protected approval and release evidence | Production settings never copied from source control |

The same validated solution artifact must be promoted between stages. A stage
must not rebuild from an unreviewed branch or use a personal mirror credential.

## Preferred path

Use Power Platform Pipelines when the tenant owner provides approved development,
pilot, and production environments and grants the required pipeline ownership.
Deployment identity should be a service principal or other approved delegated
identity, with environment-specific connection references and variables supplied
by protected configuration.

## Fallback path

When Pipelines cannot be provisioned, the protected GitHub Actions deployment
workflow may run the same pack, checker, and import sequence. The `pilot`
environment must require reviewer approval and contain the Power Platform
credentials as protected secrets. The private GitHub mirror is continuity CI,
not an authorised NSW Health deployment identity.

## Rollback and evidence

- Roll back by importing the last validated managed solution artifact.
- Retain the package, checker result, approval record, commit SHA, and target
  environment for each pilot release.
- Do not use `git push --mirror`, personal passwords, or source-controlled tenant
  identifiers as deployment mechanisms.

## Tenant-owner decisions required

- Which environments are approved for development, pilot, and production.
- Whether Power Platform Pipelines is enabled and who owns the pipeline.
- Whether service-principal or delegated deployment is permitted.
- Required DLP, retention, change-approval, and rollback evidence.

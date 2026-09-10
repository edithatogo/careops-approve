# CareOps Approve

CareOps Approve is an organisation-neutral, Teams-first workflow module for
structured intake, deterministic validation, routing, delegation, escalation,
human approval, and durable decision audit.

The core uses Microsoft 365 and Power Platform capabilities where appropriate:
Forms or another approved intake surface, SharePoint or Dataverse, Power
Automate, Teams Approvals, Planner, and controlled reporting. Tenant identities,
connection references, policy rules, and environment values are deployment
configuration and must not be committed.

## Decision boundary

CareOps Approve is an orchestration and evidence-control module. It is **not** a
clinical decision engine and does not replace a committee, relevant peer,
delegated decision maker, review body, or appeal body.

AI may classify, extract, reconcile, summarise, draft, or identify missing
information. It cannot approve, reject, assign authority, determine competence,
define scope of clinical practice, impose conditions, or produce an adverse
outcome. AI failure or low confidence preserves the ordinary human pathway.

## Core capabilities

- configurable request templates and pathways;
- deterministic completeness, evidence, date, and link checks;
- idempotent request IDs and duplicate prevention;
- immutable assignment and decision records;
- business-calendar due dates and absence-aware routing;
- prospective delegation with an auditable delegation record;
- correction queues and recoverable failure states;
- native Teams human approvals;
- required reasons for rejection or limitation where configured;
- escalation, cancellation, and reconciliation;
- restricted visibility and privacy-safe telemetry; and
- solution-aware Power Platform ALM.

## Modular delivery

Capabilities are delivered as feature-flagged packs. The stable core remains
small; a deployment enables only the packs it has approved and tested.

The first CHHHS pack is documented in
[`docs/credentialing-capability-pack.md`](docs/credentialing-capability-pack.md).
It supplies credentialing intake and routing contracts while leaving committee
governance and formal delegated decisions to `careops-decisions`.

The recommended sequence is:

1. synthetic validation;
2. one bounded MVP pathway;
3. retrospective and prospective silent-mode comparison;
4. limited integration after explicit governance approval; and
5. regular small releases with feature flags, acceptance evidence, and rollback.

## Existing example adapters

The repository retains legacy email-to-approval and general submit-and-route
contracts as examples. They are adapters, not the reusable domain authority.
New deployments should use generic role names and deployment profiles rather
than copying historical tenant identities or organisation-specific fields.

## Source control and deployment

The canonical repository is `edithatogo/careops-approve`. Source control stores
reviewable solution assets, contracts, schemas, tests, and non-sensitive
configuration examples. It must not store operational records, mailbox exports,
practitioner or patient information, credentials, tenant identifiers, or
production connection values.

The implementation baseline is solution-aware Power Platform ALM with validated
packages, protected deployment environments, connection references, environment
variables, and rollback to the last approved artifact. See
[`docs/alm.md`](docs/alm.md) and
[`docs/repository-topology.md`](docs/repository-topology.md).

## Validation

```powershell
./scripts/Test-Repository.ps1
```

Tenant deployment and operating effectiveness remain separate gates from
repository validation.

## Licence

Original material in this repository is licensed under the MIT License.
Third-party components retain their own terms.

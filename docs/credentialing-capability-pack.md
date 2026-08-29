# Credentialing capability pack

Status: blueprint; disabled by default

## Purpose

This capability pack adapts the generic CareOps Approve controls to a
credentialing and scope-of-clinical-practice workflow. It is designed to be used
with an organisation-specific authority profile and the committee and delegated
decision controls in `careops-decisions`.

The pack does not contain Queensland, CHHHS, NSW, or other jurisdictional policy
conclusions. A deployment must map every required field, pathway, duration,
role, and decision gate to current approved sources.

## MVP boundary

The recommended first MVP is one routine renewal and expiry-assurance pathway.
It should:

- use synthetic data first;
- apply deterministic completeness and evidence-manifest checks;
- identify missing, contradictory, or stale information;
- support credentialing-officer review and correction;
- create an immutable governance handoff packet;
- receive references to the human recommendation and delegated decision;
- emit privacy-minimised process events; and
- remain silent with respect to the current authoritative system.

It should not initially:

- write to an authoritative credentialing register;
- activate or remove a practitioner from a roster;
- determine competence or professional suitability;
- approve changed, interim, emergency, disaster, or mutual-recognition scope;
- decide conditions, supervision, review, or appeal; or
- ingest unrestricted patient, complaint, investigation, or incident content.

## Capability sequence

1. **Foundation:** templates, authority mapping, synthetic fixtures, feature
   flags, audit envelope, and privacy controls.
2. **Routine renewal MVP:** completeness, evidence requests, officer review,
   governance handoff, and metrics.
3. **Silent evaluation:** compare with the current process and measure errors,
   rework, delay, and staff effort.
4. **Committee integration:** use the versioned `careops-decisions` contract.
5. **Limited register integration:** only after explicit approval, reconciliation,
   continuity, and rollback evidence.
6. **Additional packs:** changed scope, mutual recognition, temporary pathways,
   conditions and supervision, review, appeal, and cross-service assurance.

## AI-assisted features

Optional AI assistance may include:

- document classification and layout-aware OCR;
- extraction of dates, qualifications, scope identifiers, and evidence types;
- reconciliation of extracted fields against the evidence manifest;
- missing-information and contradiction summaries;
- draft practitioner correspondence;
- structured summaries for human professional or committee review; and
- policy-change triage for a human rule maintainer.

Controls are mandatory:

- approved model and deployment environment;
- classification and redaction before invocation;
- source document and span references;
- provider/model and prompt or agent version;
- input/output hashes where appropriate;
- confidence and exception status;
- mandatory human review;
- no autonomous adverse outcome;
- ordinary human fallback; and
- no raw sensitive content in process telemetry or Git.

## Deterministic controls

The following remain independent of AI:

- identity and registration verification;
- mandatory evidence and date rules;
- duplicate and expiry checks;
- delegation and authority validation;
- pathway eligibility;
- hard expiry and time limits;
- human recommendation and decision requirements;
- release-to-practise preconditions; and
- audit, retention, and access rules.

## Interfaces

- `config/credentialing-approval-templates.example.json`
- `config/capability-packs.example.json`
- `flows/credentialing-intake-and-handoff.contract.json`
- `careops-decisions` credentialing governance contract
- `careops-process` credentialing event projection

Integration uses stable request, practitioner-reference, scope, evidence,
recommendation, decision, and event identifiers. Modules do not share a common
operational database by default.

## Success measures

- time and manual touches per request;
- complete-at-first-submission rate;
- number and type of evidence requests;
- duplicate and stale-data prevention;
- time waiting on practitioner, officer, peer, committee, and delegate;
- governance-packet rejection or deferral rate;
- decision-to-register latency when integration is later enabled;
- expiry and temporary-approval exceptions;
- false alerts and missed requirements;
- staff and practitioner experience;
- committee preparation time; and
- staff capacity redirected to complex review, support, and assurance.

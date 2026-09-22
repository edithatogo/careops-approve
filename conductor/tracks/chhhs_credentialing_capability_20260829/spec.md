# Specification

## Goal

Add a reusable, feature-flagged credentialing intake and routing capability to
CareOps Approve, suitable for a CHHHS silent-mode MVP and later reuse by other
deployment profiles.

## Functional requirements

- versioned credentialing pathway templates;
- deterministic completeness and evidence-manifest validation;
- duplicate prevention and stable request identifiers;
- recoverable correction and exception queues;
- mandatory credentialing-officer review;
- optional professional and service review;
- immutable handoff to `careops-decisions`;
- receipt of recommendation and delegated-decision references;
- optional privacy-minimised events for `careops-process`;
- privacy-safe service metrics; and
- feature-flagged deployment with no production writes by default.

## AI requirements

AI assistance is optional and advisory. It must preserve source references and
spans, confidence, model/provider, prompt or agent version, timestamps, hashes,
and human review. AI cannot verify identity or registration, certify evidence,
determine competence or scope, impose conditions, make recommendations or
decisions, or release a practitioner to practise.

## Acceptance criteria

- the generic core contains no organisation-specific identities or host names;
- credentialing packs are disabled by default;
- the MVP supports synthetic routine-renewal cases end to end through an
  immutable governance handoff;
- all material decisions require an identified human role;
- missing authority or configuration fails closed without losing the request;
- duplicate, failure, timeout, correction, cancellation, and reconciliation
  paths are testable;
- sensitive content is excluded from Git and telemetry; and
- repository, tenant-deployment, silent-pilot, and operating-effectiveness
  statuses are reported separately.

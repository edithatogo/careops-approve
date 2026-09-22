# Composable credentialing checks: executable reference

Status: synthetic reference implementation, not a deployed connector or clinical
credentialing engine. See portfolio issue `edithatogo/careops#160`.

`credentialing_checks.py` supplies pure check aggregation and revision-bound
idempotency keys. The existing Power Platform solution and version 0.1 contracts
are not changed by this additive implementation. An adapter must translate the
reference types to a versioned contract before runtime integration.

## Outcome and action boundaries

- Green: the specified checks passed; ready for the required human review only.
- Amber: clarification or human attention is needed.
- Red: a specified requirement failed or a concern needs human attention.
- Unavailable: missing worker, outage, invalid output or stale input; not a
  negative finding about a practitioner.
- Not applicable: requires the matching authority reference from trusted case
  configuration. An agent cannot invent an exemption.

Colour is accompanied by text, reason and source references. Do not average away
red or unavailable checks. A mandatory unresolved check prevents automated
readiness; optional failure remains visible without blocking unrelated work.
The approved ordinary human pathway remains available if AI is unavailable.

Only explicitly enabled, approved deterministic rules for missing evidence,
invalid formatting or expired documents may plan an automatic information
request. Such a request is not rejection, withdrawal or an adverse decision.
Agentic red/amber findings go to a qualified human. Unknown identity, ambiguous
qualifications, practice concerns and potential adverse outcomes are never
returned automatically as accusations. Green never writes a register or grants
scope. A consolidated request must preserve the submission date, other completed
checks, accessible assistance and a route to challenge or correct the finding.

## Independent workers and hosting adapter

Use independently invoked Power Automate child flows or equivalent workers,
each with a versioned input/output envelope, case revision, source references,
owner, timeout, retry policy and test suite. Persist each result separately.
A worker exception is isolated here. Actual hang/process isolation, durable
queues, bounded retry/backoff, circuit breaking, dead-letter ownership and
atomic outbox/delivery deduplication MUST be supplied and tested by the adapter;
this synchronous reference does not pretend to implement those facilities.
Do not catch KeyboardInterrupt/SystemExit and convert them to routine findings.

A trusted adapter provides each case's evidence manifest and exemption authority.
Raw JSON requires schema validation before constructing these internal types.
References must also be permission-checked against the case; a model's assertion
that a document is verified is not source verification. Models/prompts cannot
edit Check configuration, policy, identity, permissions or authority. Independent
work can complete during a failure, but a genuine required control cannot be
silently bypassed. Resume only affected checks after an input changes.

## Agent function contract

Initially permit document classification, source-linked candidate extraction,
contradiction detection and concise draft summaries. Return structured facts,
source spans, reason codes and uncertainty; no person-level score or competence
conclusion. Capture model, prompt, tool and rule versions in the private audit
record. Test hallucinated sources, document prompt injection, hidden identifiers,
false reassurance, missed concerns and differential burden across professions.
Never expose a tool for approval, refusal, scope restriction or register writes.
Human confirmation occurs in the existing review workbench, not a second queue.

## Quality and release

Run `python -m unittest discover -s tests/reference -v`. CI also applies strict
mypy, lint, and 100% statement/branch coverage to this small reference kernel.
Exhaustive tests cover every kind/colour/enablement/permission combination for
information requests. Coverage does not certify production safety. Tenant
security, privacy, model evaluation, failure recovery and accessibility require
separate integration and user acceptance testing. All fixtures are synthetic.

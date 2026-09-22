# Independently deployable checks

Status: tested lease/retry domain model, not a running scheduler or Power Platform
connector. Extends the preparation kernel without changing its decision boundary.
Related portfolio work: edithatogo/careops#160.

## Composition

Use separate event-triggered workers for intake completeness, primary-source
verification, source-linked document triage, human professional review, authority
validation, committee recommendation and delegated decision. A deployment profile
selects the warranted steps for each pathway; temporary pathways must not inherit
a routine application's order accidentally. AI cannot approve, refuse or assign
scope. No second human approval is required merely because an agent helped prepare
an existing review.

Each worker has its own queue, lease, retry budget and versioned input/output.
Publish its result when available; do not wait for a synchronous all-worker call.
Deterministic document availability checks can gate an expensive agent call while
unrelated registration, expiry or service-capability checks proceed separately.
A missing mandatory prerequisite blocks that dependent step, not unrelated work.
A failed optional agent never disables the ordinary authorised human pathway.

The new Job model starts one bounded attempt, accepts evidence/revision-bound
results, expires leases without waiting for workers and limits technical retries.
Tokens change on a new attempt, check version or application revision. Completed
findings are retained; red/amber findings are not retried as technical errors.
Exact completed-result replay is harmless. Late, altered or stale-attempt events
cannot overwrite completed work. Retry exhaustion means technical attention,
not failed credentialing. There is no global mutable job state or external action.

## Traffic-light meaning and routing

- Green: this preparation check found no issue in its stated evidence coverage.
  It is not credential approval, competence certification or release to practise.
- Amber/red: attention is needed, with a reason and source references. Only
  enabled deterministic missing-evidence/format/expiry rules may plan a routine
  information request. Consolidate such requests before approved delivery.
- Agentic amber/red: automatically route to the existing accountable human review
  queue, not directly back to the applicant as a negative judgement. The reviewer
  can confirm, correct or dismiss the finding in the normal review.
- Unavailable: technical or evidential uncertainty. Retry within budget, then send
  the system fault to support while preserving the human case pathway.
- Not applicable: requires a matching approved exemption, not an agent assertion.

Render text labels, reason, evidence, owner and next action alongside colour.
Avoid composite practitioner risk scores. Never convert a missing feed or failed
AI call into an adverse credentialing conclusion.

## Required hosting adapter

This is not hard process isolation or durable storage. Separate workers must be
hosted with real execution limits, restricted connections and no decision-write
tools. A timer/watchdog must call expire; a hung worker cannot prevent its timer.
Callbacks must be authenticated and bound to exact case/evidence versions. Tokens
are correlation identities, not secrets or evidence of authentication. Objects
must be constructed by the protected adapter, not arbitrary request JSON.

Persist each state change and outbox command atomically with optimistic version
checks. Only then dispatch. Deduplicate event delivery, restrict retries to the
failed worker and discard late responses from superseded leases. Reconcile cases
changed while work was running. Observe end-to-end time and staff touches, not
just agent latency. Enforce bounded concurrency/cost, operational ownership,
audit retention, recovery and an AI-off switch before production activation.

Copilot Studio is an optional worker implementation. The workflow coordinator
owns routing and permissions; an agent does not choose its own authority or
recipients. An event trigger's connection must be explicitly scoped. Approved
source-grounded agent outputs require separate factuality, bias, privacy and
prompt-injection evaluation in addition to the deterministic tests here.

No communication, live tenant change, credentialing-register write or contract
cancellation is performed by this reference implementation.

# Service metrics and queue capacity

## Objective

Measure demand, decision time, overdue work, escalation, correction and failure rates
without exposing request content or turning metrics into staff-performance scoring.

## Requirements

- Define sanitized event and metric contracts with explicit denominators.
- Report queue age, throughput, lead time, overdue rate and exception rate.
- Add threshold-based owner warnings in Teams without email.
- Keep individual performance ranking and sensitive drill-through out of scope.

## Acceptance criteria

- Synthetic fixtures produce deterministic metric results.
- Empty, partial, duplicate and late-event scenarios pass.
- The owner report contains no raw request content or broad-channel publication.

## Stop conditions

Do not activate broad reporting, staff ranking or tenant-wide analytics without an
approved privacy assessment and access model.


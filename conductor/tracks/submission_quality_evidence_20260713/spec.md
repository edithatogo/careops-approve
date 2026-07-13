# Submission quality and evidence checks

## Overview

Prevent incomplete or unsafe requests from reaching an approver by validating
required fields, evidence links, classifications and contradictory data before
the native approval is created.

## Requirements

- Run deterministic validation before optional advisory AI review.
- Permit only approved link locations and metadata; do not copy sensitive content.
- Route fixable failures to the existing correction queue.
- Record warnings separately from blocking errors.

## Acceptance criteria

- Missing, malformed, unsafe-link, contradictory and valid cases pass tests.
- AI failure never blocks ordinary deterministic processing unless policy says so.
- No raw email, attachment or sensitive payload enters source-controlled evidence.

## Out of scope

- Malware scanning, clinical validation or autonomous approval decisions.


# Business calendar and absence-aware routing

## Overview

Calculate reminders and escalation using an approved business calendar and resolve
known absences prospectively to an authorised fallback.

## Requirements

- Use a tenant-configured calendar source; do not hard-code dates or people.
- Resolve absence before request creation and record the routing reason.
- Never reassign an in-flight approval silently.
- Fall back to elapsed-day SLA when calendar data is unavailable.

## Acceptance criteria

- Weekend, public-holiday, absence, unavailable-source and in-flight cases pass.
- The no-admin implementation works with approved standard connectors.
- Graph/Business Approvals Kit enhancements remain conditional on permissions.

## Out of scope

- Reading organisation-wide calendars or Graph data without approved consent.


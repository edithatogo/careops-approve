# Approval template catalogue and routing

## Overview

Extend the TESL and EDMS examples into a versioned catalogue of low-risk approval
types that resolves fields, approver roles, SLA and escalation without editing flow
logic.

## Requirements

- Version templates and retain the version copied to each request.
- Define required fields, eligible submitters, approver role, SLA and escalation.
- Reject unknown, inactive or ambiguous template configuration.
- Preserve native Teams Approvals as the decision authority.

## Acceptance criteria

- Adding or retiring a template does not require changing core flow actions.
- Existing requests retain their original template and approver assignment.
- Route, validation and visibility scenarios are executable in the harness.

## Out of scope

- Financial, procurement, clinical or tenant-wide approval authority.


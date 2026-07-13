# Requester status and feedback

## Objective

Let requesters see the status of their own requests, respond to correction prompts
and optionally provide process feedback without exposing approver-only commentary.

## Requirements

- Restrict visibility to the requester and explicitly authorised roles.
- Show request ID, safe status, current stage, due/escalation state and next action.
- Separate requester-visible reasons from internal comments.
- Collect optional low-risk process feedback after finalization.

## Acceptance criteria

- Owner, requester, unrelated-user and future-subject visibility cases pass.
- Correction and feedback replay are idempotent.
- No broad list permissions or confidential comments are exposed.

## Stop conditions

Do not enable person-the-decision-is-about visibility until its policy, privacy and
record-access rules are explicitly approved.


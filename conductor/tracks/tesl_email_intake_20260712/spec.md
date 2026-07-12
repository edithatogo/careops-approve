# TESL Outlook intake

Implement a tenant-neutral Outlook-triggered intake that matches the approved
mailbox/folder/sender/subject boundary, parses configured TESL aliases, and
creates a submission only after deterministic validation. Preserve unknown
fields, suppress outbound email, and keep mailbox configuration outside Git.

Acceptance: valid, non-TESL, malformed, missing-field, and connector-failure
scenarios pass; the source contract, BPMN, and handoff runbook agree.

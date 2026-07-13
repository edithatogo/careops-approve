# TESL AI assessment and decision annotation

The TESL flow may use an approved AI Builder or Copilot-backed assessment to
summarize the application against a tenant-provided policy. The assessment is
advisory only. The approver makes the authoritative decision in native Teams
Approvals from any supported Teams surface. After that response, Power Automate
persists a sanitized annotation containing the assessment summary and human
outcome. AI must never approve, reject, reassign, or escalate a request.

## Guardrails

- Redact or exclude sensitive and clinical content before assessment.
- Show assessment status, summary, flags, confidence, prompt version and time
  in the approval details and audit record.
- Continue to ordinary human approval when AI is unavailable, low-confidence,
  or policy-blocked.
- Treat the human Teams response and comment as authoritative.
- Persist the post-decision annotation idempotently by request ID and approval ID.
- Do not mutate the native decision or send email notifications.

## Out of scope

Autonomous approval, hidden model reasoning, policy interpretation as formal
delegation, Graph application permissions, and production AI activation without
tenant capacity, classification, retention and owner approval.

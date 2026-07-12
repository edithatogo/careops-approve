# Telemetry and owner reporting

Record correlation, processing state, error code, duplicate outcome, decision
state, escalation state, and timestamps in an approved tenant store. Generate a
weekly owner-only Teams summary for pending, overdue, escalated, failed, and
urgent-delegation records. Do not store raw email or expose broad channels.

Acceptance: telemetry is sanitized, immutable where required, reconciles to
approval records, and produces no outbound email.

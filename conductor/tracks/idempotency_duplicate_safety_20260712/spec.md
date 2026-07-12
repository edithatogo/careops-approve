# Idempotency and duplicate safety

Use a stable source-message/TESL-reference key, retain the first submission and
approval, and record a sanitized duplicate outcome. Replays must be safe and
must not reassign or alter an in-flight approval.

Acceptance: repeated delivery, concurrent delivery, and post-decision replay
produce one authoritative request and an auditable duplicate state.

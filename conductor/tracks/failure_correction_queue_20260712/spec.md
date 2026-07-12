# Failed extraction and correction queue

Preserve malformed or incomplete source records, route them to a failed
extraction state, and expose only approved correction fields to the workflow
owner. Correction may resume validation but cannot create a decision or bypass
native Teams Approval.

Acceptance: malformed, parse-error, correction, rejected-correction, and
successful-reprocess scenarios are covered and email-free.

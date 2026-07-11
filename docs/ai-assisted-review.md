# Advisory AI review stage

CareOps can use an AI Builder prompt in Power Automate to review a submission
before the native Teams approval. The AI stage is deliberately advisory:

- it may summarise and extract structured fields;
- it may identify missing information, duplicates, contradictions, or policy flags;
- it may provide a confidence score and a clarification route;
- it must never approve, reject, assign, cancel, or escalate an approval;
- AI failure or low confidence falls through to ordinary human review;
- the native Teams Approval remains the decision system of record.

## Proposed flow position

`submit/email -> deterministic validation -> redact approved fields -> AI review -> persist assessment -> native Teams approval -> human decision`

The assessment records its status, summary, flags, confidence, prompt version,
timestamp, human-decision requirement, and input hash. Raw prompt input is not
retained by the contract.

## Safe TESL uses

- identify whether an email resembles a TESL request;
- extract configured TESL fields;
- summarise the request for the approver;
- identify missing or inconsistent fields;
- flag requests that need clarification.

AI must not make employment, clinical, workforce, financial, or governance
decisions. Do not send restricted or clinical content to the prompt unless the
tenant data-classification and AI Builder governance decision explicitly permits
it.

## Enablement gates

Before setting `config/ai-review.example.json` to enabled, confirm:

1. AI Builder prompt availability and capacity in the target region;
2. licensing and Dataverse/environment prerequisites;
3. approved data classification, retention, and prompt-input policy;
4. prompt version and owner;
5. human review and low-confidence handling;
6. pilot evidence for false positives, omissions, and connector failures.

The default is `enabled: false`, `mode: advisory`, and
`recommendation: no-autonomous-decision`.

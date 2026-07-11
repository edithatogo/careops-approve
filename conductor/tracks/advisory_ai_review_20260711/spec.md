# Specification

Add an opt-in AI Builder review stage before the human Teams approval while
preserving human decision authority, privacy boundaries, and fail-safe behavior.

## Acceptance criteria

- AI review is disabled by default and advisory when enabled.
- AI can summarize, extract, and flag; it cannot finalize, assign, cancel, or escalate an approval.
- AI failure and low confidence preserve ordinary human review.
- Assessment metadata is auditable without retaining raw prompt input.
- AI review requires explicit tenant licensing, region, data-classification, and retention confirmation.

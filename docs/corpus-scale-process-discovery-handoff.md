# Corpus-scale process-discovery handoff

This repository owns the Power Automate/M365 acquisition boundary. The
`careops-process` repository owns the governed OCEL/process-discovery and
Executive-reporting boundary. The two stages must be operated in order:

1. Configure and run the cloud-only historical Outlook backfill using
   `docs/outlook-historical-backfill-operator-runbook.md`.
2. Produce sanitized backfill evidence and obtain the corpus pilot-entry
   approvals: source owner, information governance, configuration freeze, and
   rollback/retention.
3. Transfer only minimized facts, closed-run evidence, and the sanitized pilot
   entry through the approved evidence location.
4. In `careops-process`, run `scripts/build-closed-run-report.py` with
   `--facts`, `--evidence`, and `--pilot-entry`. The command requires
   `CAREOPS_PSEUDONYM_SECRET` outside source control.
5. Keep the Executive validation record pending until operational owners and
   the IHG Executive team review the empirical process families.

Neither repository treats connector success, the four-record smoke test, or a
partial delegated source as corpus-scale evidence. Do not transfer or commit
raw email, mailbox identifiers, tenant identifiers, subjects, bodies,
attachments, recipients, UPNs, tokens, screenshots, or clinical content.

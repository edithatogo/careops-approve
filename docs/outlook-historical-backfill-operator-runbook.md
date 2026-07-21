# Cloud-only Outlook historical backfill operator runbook

This runbook is for an authorised tenant workflow owner. It describes the
remaining live activation step for the TESL intake and process-discovery tracks.
The repository does not contain mailbox content, tenant identifiers, tokens, or
connection details.

## Configure

1. Import the validated solution into the approved pilot environment.
2. Bind the existing Office 365 Outlook connection reference and Dataverse
   connection reference in Power Automate. Do not create a desktop/COM step.
3. Confirm the Dataverse tables and columns match the contract and that the
   service account has least-privilege read/create/update access.
4. Set the authorised mailbox scope and folder inventory policy in the flow.
   Do not add a date filter: the objective is the complete historical mailbox
   available to the connection.
5. Confirm retention, legal hold, clinical-data classification, DLP, and the
   approved evidence location before running.

## Run and reconcile

1. Start a manual run and record only the generated run identifier hash.
2. Allow folder inventory to freeze before item paging begins.
3. Let every folder run to an explicit pagination-exhausted state. A timeout,
   throttling error, inaccessible folder, or partial page is a failed run.
4. Verify the sanitized evidence record: folder count, page count, candidate,
   acquired, duplicate, rejected, and dead-letter counts; timestamp bounds;
   exhaustion; reconciliation; and idempotency replay.
5. Run the same scope again. The second run must create zero new records and
   report duplicates for previously acquired items.
6. Close the run only after all folders reconcile. If any gate fails, use the
   fail-closed path, preserve the run for correction, and do not promote it.

## Evidence and handback

Copy `config/outlook-historical-backfill-evidence.example.json`, replace
placeholders in the approved evidence location, and validate it locally with
`scripts/Test-OutlookHistoricalBackfillEvidence.ps1`. Commit only the schema or
sanitized aggregate results; never commit raw email, subjects, bodies,
attachments, recipients, UPNs, URLs, folder names, message IDs, tokens, or
screenshots. The workflow owner supplies the external evidence reference and
approval decision before the Conductor pilot checkbox is closed.

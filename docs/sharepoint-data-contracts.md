# SharePoint data contracts

`config/sharepoint-lists.example.json` defines the tenant-neutral list contract
for the MVP. The approved tenant owner supplies the site URL and provisions the
lists through an authorised deployment or maker procedure; no site URL or list
ID is stored in this repository.

The submission flow resolves the active approver configuration once and copies
the approver email and configuration version into the submission record. Those
fields are immutable after creation. Replacing an approver therefore affects
new submissions only.

The decisions list permits one final record per request. Rejections require a
comment. A failed routing configuration preserves the submission and alerts a
workflow owner instead of silently dropping the request.

Access is intentionally separated: requesters cannot edit configuration,
approvers cannot manage the roster, and owners are the only configuration
administrators. Actual SharePoint permissions remain subject to tenant policy,
DLP, retention, and records-management review.

Validate the source contract with:

```powershell
./scripts/Test-SharePointContracts.ps1
```

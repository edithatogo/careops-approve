# Approver administration procedure

Only authorised workflow owners may edit the approver configuration list.
Requesters and approvers have no roster-management permission.

For each change, the owner should:

1. Create a new configuration version rather than editing an in-flight record.
2. Set the effective time, primary approver, optional fallback, and active status.
3. Confirm there is at most one active configuration and a valid primary.
4. Verify that a test submission resolves the intended new approver.
5. Record the change reason and retain the prior configuration for audit.

Changes affect new submissions only. Existing submissions retain their copied
assigned approver and configuration version. Deactivating an approver requires a
valid successor or fallback; otherwise routing must fail visibly and alert an
owner.

The source scenarios are validated with:

```powershell
./scripts/Test-AdministrationScenarios.ps1
```

# Dataverse review surface

The existing TESL Power Platform work includes a Dataverse submission app and
telemetry table. CareOps may use those surfaces for owner correction,
sanitized operational reporting, and read-only reconciliation if the tenant
owner confirms licensing, DLP, and permissions.

Native Teams Approvals remains authoritative. The Dataverse surface must not
approve, reject, reassign, or delegate an in-flight request. If Dataverse is
not approved or does not provide sufficient value, the supported fallback is
the existing SharePoint contract plus Teams Approvals.

# CareOps approval contracts

These JSON Schema Draft 2020-12 files are the source-controlled contract for the
native Teams Approvals MVP. They map to the eventual SharePoint submission,
outcome, and approver-configuration lists; tenant URLs, connection IDs, and
identities remain deployment configuration.

The flow must resolve the active configuration once, copy the selected approver
and configuration version into the request, and never rewrite those fields when
the roster changes. A rejected decision requires a non-empty comment. Invalid or
empty configuration must preserve the request and alert an authorised owner.

The schemas describe the interface; `scripts/Test-Contracts.ps1` provides the
local dependency-free structural gate until a tenant-backed Power Platform
solution exists.

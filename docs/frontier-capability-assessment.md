# Frontier capability assessment

Reviewed: 2026-07-10

This assessment applies the MVP governance boundary: no custom Entra app, Graph
application permission, tenant-admin role, custom connector, or premium service.
The native Teams Approvals experience with standard Forms, SharePoint, and Power
Automate remains the stable fallback for every capability below.

## Decisions

| Capability | Decision | Evidence and boundary | Fallback | Review |
| --- | --- | --- | --- | --- |
| Business Approvals Kit | Reject for MVP; watch for a later Dataverse programme | Microsoft documents a non-default Dataverse environment, Power Apps licensing, solution import, custom connector configuration, and Entra app registration. That is disproportionate to a two-person one-stage workflow and exceeds current authority. | Native Teams Approvals plus standard connectors | 2026-10-10 |
| Microsoft Graph Approvals APIs | Reject for MVP; isolate only after permissions are approved | The APIs can create and manage Teams approval items, but require an app integration and governed Graph permissions. They would replace a native low-privilege path with a custom identity and lifecycle surface. | Power Automate approval actions and native Approvals app | 2026-10-10 |
| Power Apps Test Engine | Trial later in non-production; not a runtime dependency | Microsoft labels Test Engine preview and requires Power Platform CLI. It is useful for future canvas/model-driven/Dataverse test coverage, but the MVP has no custom Power App or Dataverse solution yet. | Contract tests plus tenant-owner manual verification | 2026-10-10 |

## Consequences

- The MVP does not require Business Approvals Kit installation, Dataverse
  provisioning, custom connector creation, or Entra app registration.
- Graph-based automation must not be introduced merely to obtain richer telemetry
  while native approval records and the source-controlled contracts are sufficient.
- Test Engine adoption can be revisited when a solution-aware Power App or
  Dataverse component exists and a non-production test environment is approved.
- A tenant owner must still confirm that native Approvals, Forms, SharePoint, and
  standard Power Automate connectors are available under local licensing and DLP.

## Sources

- [Business Approvals Kit setup](https://learn.microsoft.com/en-us/power-automate/guidance/business-approvals-templates/setup)
- [Approvals Kit content](https://learn.microsoft.com/en-us/power-automate/guidance/business-approvals-templates/content)
- [Approvals app APIs](https://learn.microsoft.com/en-us/graph/approvals-app-api)
- [Power Apps Test Engine preview](https://learn.microsoft.com/en-us/power-platform/test-engine/overview)

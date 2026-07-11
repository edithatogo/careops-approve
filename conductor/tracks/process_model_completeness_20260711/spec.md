# Specification

Ensure every implemented CareOps Approve process contract has a tenant-neutral
BPMN 2.0 model and a corresponding visual representation with versioned source.

## Acceptance criteria

- Submit-and-route and TESL email-to-approval each have BPMN, Mermaid, and SVG artefacts.
- The process index maps contracts to all model and visual artefacts.
- Repository validation fails when any required artefact is missing or malformed.
- No tenant identifiers, credentials, live payloads, or executable deployment exports are included.

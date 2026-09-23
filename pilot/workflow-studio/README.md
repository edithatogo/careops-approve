# Workflow Studio reference UI

Status: source-controlled reference pilot. It is not a production Power App and
does not publish workflow versions.

## Purpose

This no-build browser UI exercises the contracts already implemented in CareOps
Approve. It is intentionally bounded to draft editing.

The editor:

- loads the governed node catalogue from `config/workflow-editor-catalog.example.json`;
- shows both supported and reserved node types;
- allows only supported node types to be added;
- renders node configuration controls from catalogue metadata;
- edits workflow identity, entry node, nodes and transitions;
- performs client-side duplicate-ID, transition, reachability and cycle checks;
- preserves agent human-review/fallback requirements;
- imports and exports the canonical workflow-definition JSON shape;
- can GET a workflow-version record from a compatible CareOps API;
- can PUT a draft with the current ETag in `If-Match`; and
- deliberately does not expose publication or retirement controls.

## Run locally

Serve the repository root through any approved static HTTP server, then open
`/pilot/workflow-studio/`. The page uses only repository-local HTML, CSS,
JavaScript, catalogue and sample files. Opening the HTML directly with a
`file://` URL may prevent browser `fetch` from loading local JSON.

The API base URL is optional. Without one, the editor remains a local synthetic
draft editor.

## Security and governance boundary

This UI is not an authorization boundary. A production host must authenticate
the user and enforce catalogue permissions, role resolution, ETags, semantic
compilation, publication governance and storage controls server-side.

Client-side validation is usability assistance only. The API/compiler/registry
remain authoritative.

Reserved nodes are visible for design-roadmap purposes but cannot be added by
the reference UI.

## Next implementation step

The next deployment-specific adapter should bind these same editor semantics to
an approved Microsoft 365 surface (for example Power Apps/Dataverse or another
approved web host) and to a durable implementation of the registry API.

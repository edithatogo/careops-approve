# Workflow Studio: durable local draft pilot

Status: **synthetic data only, local development**. This is not an approved
CHHHS deployment, a production API, or a replacement for the authoritative
credentialing system. No real applicant, practitioner or patient data.

## Run

From the repository root, using Python 3.13 or 3.14:

```sh
python -m pip install -r pilot/requirements-studio.txt
python -m pilot.studio_server --database /absolute/path/outside-the-repository/synthetic-studio.sqlite3
```

Choose an existing directory for the database. On Windows, use a suitable local
Windows path. Open the printed `/pilot/workflow-studio/` address and set the
editor's **API base URL** to the printed loopback origin (normally
`http://127.0.0.1:8765`). Use 127.0.0.1, not localhost. The port can be changed
with `--port`, but the listening address cannot.

Save a draft, stop the server, restart it with the same database path, then load
the same workflow ID and version. The draft and ETag survive. Two editor windows
can load the same draft, but only the first save with that ETag succeeds. The
other editor receives a conflict and must reload, preserving the first edit.

## Implemented

| Function | Behaviour |
|---|---|
| Save/load drafts | Existing version-record contract; draft state only |
| Concurrent editing | ETag checked inside `BEGIN IMMEDIATE`; no last-write-wins |
| Revision history | Each save appends a row; previous edits are not overwritten |
| List versions | Latest draft for each version, sorted numerically |
| Validate saved draft | Full JSON Schema check plus the existing reference compiler |
| Unsupported semantics | Disabled nodes, expression transitions and automated workers are blocked |
| Restart | Reads persisted definitions; no in-memory-only dependency |

Drafts can be structurally invalid graphs while being schema-valid, so they can
be saved for correction. Validation and saving remain distinct. The current
sample includes a deterministic check: it can be saved, but the local pilot
reports its missing execution adapter rather than claiming it works. A simple
input -> human review -> end definition can pass the bounded reference check.
Neither result authorises deployment or an operational decision.

The validation response identifies the exact **stored** definition hash and
returns its ETag. API clients can supply `If-Match` to reject validation of a
changed draft. The existing browser editor does not yet send that header for
validation; it checks its own unsaved edits but cannot detect another user's
intervening edit. Do not treat its result as approval of local unsaved content.
There is no publication endpoint in this host.

## Safety boundary

The HTTP host binds only to 127.0.0.1, checks Host and Origin, does not enable
CORS, and serves a fixed asset allowlist rather than the repository directory.
Mutating requests require the same Origin. JSON size, graph size, duplicate
keys, UTF-8, schema and path/body identity are checked. Errors do not echo raw
payloads, database paths or exception details. Static assets cannot traverse
outside the approved root. A same-origin content security policy blocks remote
connections from this locally served page.

These controls are **not authentication**. Local programs and anyone able to
use the same machine can access the pilot. SQLite data is not encrypted by
this adapter. Keep the database outside source control, protect it with local
filesystem permissions, and use synthetic records only. Hash checks detect
inconsistent records but are not a tamper-proof audit against a database owner.
The append-only draft history is not a governance decision audit.

Publication, retirement, authoritative register updates, case creation, human
task completion, model calls and outbound integrations are intentionally absent.
The production lifecycle reference is unchanged. This adapter does not import
or migrate its in-memory records.

## Tests and change log

The dedicated GitHub Actions workflow runs strict Ruff and mypy, Python 3.13 and
3.14, and branch coverage for both pilot modules. Tests include restart recovery,
competing database connections, ETag conflicts, transaction rollback, schema
violations, corrupted records, oversized/ambiguous JSON, host/origin rejection,
static-path isolation and unavailable publication/case endpoints.

Plain-language change log: added a real disk-backed draft store and a local
HTTP host so the existing editor can save and reload drafts. Added full schema
validation at the storage boundary. No production system, clinical workflow,
authority mapping, or published workflow was changed.

Before organisational deployment: approved hosting and storage, authenticated
identity, server-side role/tenant authorisation, governed publication evidence,
case/task persistence, adapter registration, operational audit, backups and
restore drills, accessibility and browser acceptance testing remain required.

Implementation references: Python `sqlite3` and `http.server` documentation;
jsonschema 4.26.0 Draft 2020-12 validator documentation. The standard-library
HTTP server is used solely for this local development pilot.

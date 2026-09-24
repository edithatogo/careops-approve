"""Durable, draft-only Workflow Studio pilot storage. No publication or cases.

SQLite is a local synthetic-pilot adapter, not a production tenant database.
Every edit is appended; a transaction checks the ETag before allocating a
revision. The existing lifecycle registry remains separate and unchanged.
"""
from contextlib import closing
from hashlib import sha256
from json import dumps, loads
from pathlib import Path
from sqlite3 import Row, connect
from typing import cast

from jsonschema import Draft202012Validator

MAX_BYTES = 1_048_576


class Conflict(ValueError):
    """A stale/missing ETag must never overwrite another editor's draft."""


def canonical(value: object) -> str:
    """Same deterministic JSON encoding as the reference definition hash."""
    return dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False)


def digest(value: object) -> str:
    return "sha256:" + sha256(canonical(value).encode("utf-8")).hexdigest()


def _object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Duplicate JSON keys are not permitted")
        result[key] = value
    return result


def _nonfinite(value: str) -> object:
    raise ValueError("Non-finite numbers are not permitted")


def parse_document(raw: bytes) -> dict[str, object]:
    """Reject ambiguous JSON, non-objects, excessive size and invalid UTF-8."""
    if len(raw) > MAX_BYTES:
        raise ValueError("Workflow exceeds the pilot size limit")
    value: object = loads(raw.decode("utf-8"), object_pairs_hook=_object, parse_constant=_nonfinite)
    if not isinstance(value, dict):
        raise ValueError("Workflow must be a JSON object")
    return cast(dict[str, object], value)


class StudioStore:
    """On-disk draft revisions, with independent connections for each operation."""

    def __init__(self, database: Path, schema_path: Path) -> None:
        self.database = database.resolve()
        self.validator = Draft202012Validator(parse_document(schema_path.read_bytes()))
        self.validator.check_schema(self.validator.schema)
        # Explicit transaction control: do not rely on future sqlite3 defaults.
        with closing(connect(self.database, isolation_level=None)) as db, db:
            db.execute("BEGIN IMMEDIATE")
            version = db.execute("PRAGMA user_version").fetchone()[0]
            if version not in (0, 1):
                raise ValueError("Unsupported Studio database schema version")
            db.execute("""CREATE TABLE IF NOT EXISTS studio_drafts (
                workflow_id TEXT NOT NULL, version TEXT NOT NULL,
                revision INTEGER NOT NULL CHECK(revision > 0),
                definition TEXT NOT NULL, definition_hash TEXT NOT NULL,
                etag TEXT NOT NULL,
                PRIMARY KEY (workflow_id, version, revision))""")
            db.execute("PRAGMA user_version = 1")

    def _validate(self, definition: dict[str, object]) -> None:
        if not self.validator.is_valid(definition):
            # ValidationError.message may echo applicant data. Do not return it.
            raise ValueError("Workflow does not satisfy the workflow-definition schema")
        if definition["status"] != "draft":
            raise ValueError("This pilot stores drafts only; activation is not available")
        nodes = cast(list[dict[str, object]], definition["nodes"])
        edges = cast(list[dict[str, object]], definition["transitions"])
        if len(nodes) > 256 or len(edges) > 1024:
            raise ValueError("Workflow exceeds the pilot graph size limit")

    def _record(self, row: Row) -> dict[str, object]:
        definition = parse_document(cast(str, row["definition"]).encode("utf-8"))
        self._validate(definition)
        revision = cast(int, row["revision"])
        hash_value = digest(definition)
        etag = f'"{revision}-{hash_value[7:23]}"'
        if (
            definition["workflowId"] != row["workflow_id"]
            or definition["version"] != row["version"]
            or row["definition_hash"] != hash_value
            or row["etag"] != etag
        ):
            raise ValueError("Stored draft integrity check failed")
        return {
            "workflowId": definition["workflowId"], "version": definition["version"],
            "state": "draft", "definitionHash": hash_value, "etag": etag,
            "revision": revision, "definition": definition,
        }

    def save(
        self, definition: dict[str, object], *, expected_etag: str | None = None,
    ) -> dict[str, object]:
        # Snapshot before validation and hashing: later caller edits cannot leak in.
        raw = canonical(definition).encode("utf-8")
        snapshot = parse_document(raw)
        self._validate(snapshot)
        identity = (cast(str, snapshot["workflowId"]), cast(str, snapshot["version"]))
        with closing(connect(self.database, isolation_level=None)) as db, db:
            db.row_factory = Row
            db.execute("BEGIN IMMEDIATE")
            current = db.execute(
                "SELECT * FROM studio_drafts WHERE workflow_id=? AND version=? "
                "ORDER BY revision DESC LIMIT 1", identity,
            ).fetchone()
            if current is None:
                if expected_etag is not None:
                    raise Conflict("A new draft cannot use an existing ETag")
                revision = 1
            else:
                record = self._record(current)
                if expected_etag != record["etag"]:
                    raise Conflict("Draft changed; reload before saving")
                revision = cast(int, record["revision"]) + 1
            hash_value = digest(snapshot)
            etag = f'"{revision}-{hash_value[7:23]}"'
            db.execute(
                "INSERT INTO studio_drafts VALUES (?, ?, ?, ?, ?, ?)",
                (*identity, revision, raw.decode("utf-8"), hash_value, etag),
            )
            row = db.execute(
                "SELECT * FROM studio_drafts WHERE workflow_id=? AND version=? AND revision=?",
                (*identity, revision),
            ).fetchone()
            result = self._record(row)
        return result

    def get(self, workflow_id: str, version: str) -> dict[str, object]:
        with closing(connect(self.database)) as db:
            db.row_factory = Row
            row = db.execute(
                "SELECT * FROM studio_drafts WHERE workflow_id=? AND version=? "
                "ORDER BY revision DESC LIMIT 1", (workflow_id, version),
            ).fetchone()
            if row is None:
                raise KeyError("Workflow version not found")
            return self._record(row)

    def list_versions(self, workflow_id: str) -> list[dict[str, object]]:
        with closing(connect(self.database)) as db:
            db.row_factory = Row
            rows = db.execute(
                "SELECT d.* FROM studio_drafts d WHERE workflow_id=? AND revision=("
                "SELECT MAX(revision) FROM studio_drafts x "
                "WHERE x.workflow_id=d.workflow_id AND x.version=d.version)", (workflow_id,),
            ).fetchall()
            records = [self._record(row) for row in rows]
        return sorted(records, key=lambda r: tuple(int(p) for p in cast(str, r["version"]).split(".")))

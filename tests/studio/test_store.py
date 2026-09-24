"""Synthetic storage tests, including competing edits and restart recovery."""
import json
import sqlite3
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from contextlib import closing
from pathlib import Path
from threading import Barrier
from typing import cast
from unittest.mock import patch

from pilot.studio_store import MAX_BYTES, Conflict, StudioStore, canonical, digest, parse_document

ROOT = Path(__file__).resolve().parents[2]
SCHEMA = ROOT / "contracts/workflow-definition.schema.json"


def definition(version: str = "1.0.0") -> dict[str, object]:
    return {
        "workflowId": "synthetic.review", "version": version, "status": "draft",
        "displayName": "Synthetic review", "entryNodeId": "intake",
        "nodes": [
            {"id": "intake", "type": "input", "displayName": "Input", "config": {}},
            {"id": "review", "type": "human_review", "displayName": "Review",
             "config": {"assignedRole": "syntheticReviewer"}},
            {"id": "done", "type": "end", "displayName": "End", "config": {}},
        ],
        "transitions": [{"from": "intake", "to": "review"}, {"from": "review", "to": "done"}],
    }


class StoreTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.database = Path(self.temp.name) / "drafts.sqlite3"
        self.store = StudioStore(self.database, SCHEMA)

    def test_restart_and_history(self) -> None:
        first = self.store.save(definition())
        updated = definition()
        updated["displayName"] = "Second revision"
        second = self.store.save(updated, expected_etag=cast(str, first["etag"]))
        reopened = StudioStore(self.database, SCHEMA)
        self.assertEqual(reopened.get("synthetic.review", "1.0.0"), second)
        self.assertEqual(second["revision"], 2)
        with closing(sqlite3.connect(self.database)) as db, db:
            self.assertEqual(db.execute("SELECT COUNT(*) FROM studio_drafts").fetchone()[0], 2)
        cast(dict[str, object], second["definition"])["displayName"] = "External mutation"
        self.assertNotEqual(reopened.get("synthetic.review", "1.0.0"), second)

    def test_missing_records_and_numeric_version_order(self) -> None:
        with self.assertRaises(KeyError):
            self.store.get("missing", "1.0.0")
        for version in ("10.0.0", "2.0.0", "1.0.0"):
            self.store.save(definition(version))
        self.assertEqual([r["version"] for r in self.store.list_versions("synthetic.review")],
                         ["1.0.0", "2.0.0", "10.0.0"])
        self.assertEqual(self.store.list_versions("unknown"), [])

    def test_missing_and_stale_etags_do_not_overwrite(self) -> None:
        with self.assertRaises(Conflict):
            self.store.save(definition(), expected_etag='"old"')
        first = self.store.save(definition())
        for etag in (None, '"stale"'):
            with self.subTest(etag=etag), self.assertRaises(Conflict):
                self.store.save(definition(), expected_etag=etag)
        self.assertEqual(self.store.get("synthetic.review", "1.0.0"), first)

    def test_two_connections_cannot_both_win_same_revision(self) -> None:
        first = self.store.save(definition())
        barrier = Barrier(2)

        def edit(label: str) -> str:
            other = StudioStore(self.database, SCHEMA)
            candidate = definition()
            candidate["displayName"] = label
            barrier.wait(timeout=5)
            try:
                other.save(candidate, expected_etag=cast(str, first["etag"]))
                return "saved"
            except Conflict:
                return "conflict"

        with ThreadPoolExecutor(max_workers=2) as pool:
            self.assertCountEqual(pool.map(edit, ("A", "B")), ["saved", "conflict"])
        self.assertEqual(self.store.get("synthetic.review", "1.0.0")["revision"], 2)

    def test_rollback_after_insert(self) -> None:
        with patch.object(self.store, "_record", side_effect=RuntimeError("simulated interruption")):
            with self.assertRaises(RuntimeError):
                self.store.save(definition())
        self.assertEqual(self.store.list_versions("synthetic.review"), [])

    def test_schema_draft_only_and_graph_limits(self) -> None:
        for change in ({"status": "active"}, {"status": "retired"}, {"version": 5},
                       {"unknown": True}, {"workflowId": ""}):
            bad = definition() | change
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.store.save(bad)
        for key, count in (("nodes", 257), ("transitions", 1025)):
            bad = definition()
            bad[key] = cast(list[object], bad[key])[:1] * count
            with self.assertRaisesRegex(ValueError, "graph size"):
                self.store.save(bad)
        self.assertEqual(self.store.list_versions("synthetic.review"), [])

    def test_corruption_fails_closed(self) -> None:
        first = self.store.save(definition())
        with closing(sqlite3.connect(self.database)) as db, db:
            db.execute("UPDATE studio_drafts SET definition_hash='broken'")
        with self.assertRaisesRegex(ValueError, "integrity"):
            self.store.get("synthetic.review", "1.0.0")
        with self.assertRaisesRegex(ValueError, "integrity"):
            self.store.save(definition(), expected_etag=cast(str, first["etag"]))

    def test_future_database_version_not_modified(self) -> None:
        with closing(sqlite3.connect(self.database)) as db, db:
            db.execute("PRAGMA user_version=2")
        with self.assertRaisesRegex(ValueError, "schema version"):
            StudioStore(self.database, SCHEMA)

    def test_json_boundary(self) -> None:
        self.assertEqual(parse_document(b'{"a":1}'), {"a": 1})
        for raw in (b'[]', b'{"a":1,"a":2}', b'{"a":NaN}', b'{"a":Infinity}', b'\xff',
                    b'{' , b' ' * (MAX_BYTES + 1)):
            with self.subTest(raw=raw[:40]), self.assertRaises(ValueError):
                parse_document(raw)
        one = definition()
        self.assertEqual(digest(one), digest(dict(reversed(list(one.items())))))
        self.assertEqual(json.loads(canonical(one)), one)
        with self.assertRaises(ValueError):
            canonical({"bad": float("nan")})

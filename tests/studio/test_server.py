"""HTTP integration tests for the local draft API; all records are synthetic."""
import shutil
import socket
import tempfile
import unittest
from contextlib import closing
from http.client import HTTPConnection
from json import loads
from pathlib import Path
from threading import Thread
from typing import cast
from unittest.mock import patch

from pilot.studio_server import ASSETS, StudioServer, main
from pilot.studio_store import MAX_BYTES, canonical

ROOT = Path(__file__).resolve().parents[2]
PATH = "/api/v1/workflows/synthetic.review/versions/1.0.0"


def draft() -> dict[str, object]:
    return {
        "workflowId": "synthetic.review", "version": "1.0.0", "status": "draft",
        "displayName": "Synthetic review", "entryNodeId": "start",
        "nodes": [
            {"id": "start", "type": "input", "displayName": "Start", "config": {}},
            {"id": "review", "type": "human_review", "displayName": "Review",
             "config": {"assignedRole": "syntheticReviewer"}},
            {"id": "done", "type": "end", "displayName": "Done", "config": {}},
        ],
        "transitions": [{"from": "start", "to": "review"}, {"from": "review", "to": "done"}],
    }


class ServerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / "root"
        (self.root / "contracts").mkdir(parents=True)
        shutil.copyfile(ROOT / "contracts/workflow-definition.schema.json",
                        self.root / "contracts/workflow-definition.schema.json")
        for relative, _ in ASSETS.values():
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("synthetic fixture", encoding="utf-8")
        self.server = StudioServer(self.root, Path(self.temp.name) / "drafts.sqlite3", 0)
        self.thread = Thread(target=self.server.serve_forever, kwargs={"poll_interval": 0.01})
        self.thread.start()

    def tearDown(self) -> None:
        self.server.shutdown()
        self.thread.join(timeout=5)
        self.server.server_close()
        self.temp.cleanup()

    def request(
        self, method: str = "GET", path: str = PATH, value: object = None,
        *, headers: dict[str, str] | None = None, raw: bytes | None = None,
    ) -> tuple[int, dict[str, str], bytes]:
        body = raw if raw is not None else (canonical(value).encode() if value is not None else None)
        request_headers = {"Origin": self.server.origin, "Content-Type": "application/json"}
        request_headers.update(headers or {})
        with closing(HTTPConnection("127.0.0.1", self.server.server_port, timeout=5)) as connection:
            connection.request(method, path, body, request_headers)
            response = connection.getresponse()
            return response.status, dict(response.getheaders()), response.read()

    def test_save_load_update_validate_and_list(self) -> None:
        status, headers, body = self.request("PUT", value=draft())
        self.assertEqual(status, 201)
        first = loads(body)
        self.assertEqual(headers["ETag"], first["etag"])
        self.assertEqual(self.request()[0], 200)
        self.assertEqual(loads(self.request(path=PATH.rsplit("/", 1)[0])[2])[0], first)
        status, _, body = self.request("POST", PATH + "/validate")
        self.assertEqual(status, 200)
        self.assertTrue(loads(body)["deployable"])
        self.assertEqual(loads(body)["definitionHash"], first["definitionHash"])
        changed = draft() | {"displayName": "Changed"}
        self.assertEqual(self.request("PUT", value=changed)[0], 409)
        self.assertEqual(self.request("PUT", value=changed, headers={"If-Match": first["etag"]})[0], 200)
        self.assertEqual(self.request("POST", PATH + "/validate", headers={"If-Match": first["etag"]})[0], 409)
        self.assertEqual(loads(self.request()[2])["revision"], 2)

    def test_no_publication_or_case_execution_endpoints(self) -> None:
        for endpoint in (PATH + "/publication-requests", "/api/v1/cases", "/.git/config",
                         "/drafts.sqlite3", "/contracts/workflow-definition.schema.json",
                         "/pilot/workflow-studio/../../drafts.sqlite3"):
            self.assertEqual(self.request("POST", endpoint)[0], 404)
            self.assertEqual(self.request("GET", endpoint)[0], 404)
        for method, path in (("POST", PATH), ("GET", PATH + "/validate"), ("OPTIONS", PATH)):
            self.assertEqual(self.request(method, path)[0], 405)
        self.assertEqual(self.request()[0], 404)
        health = loads(self.request(path="/health")[2])
        self.assertFalse(health["publicationEnabled"])
        self.assertFalse(health["caseExecutionEnabled"])

    def test_loopback_host_and_origin_controls(self) -> None:
        for headers in ({"Host": "evil.test"}, {"Origin": "https://evil.test"}, {"Origin": "null"}):
            self.assertEqual(self.request("PUT", value=draft(), headers=headers)[0], 403)
            self.assertEqual(self.request(path="/health", headers=headers)[0], 403)
        with closing(HTTPConnection("127.0.0.1", self.server.server_port)) as connection:
            connection.request("GET", "/health")
            response = connection.getresponse()
            self.assertEqual(response.status, 200)
            response.read()
            connection.request("PUT", PATH, canonical(draft()), {"Content-Type": "application/json"})
            response = connection.getresponse()
            self.assertEqual(response.status, 403)
            response.read()

    def test_body_format_size_identity_and_activation_are_checked(self) -> None:
        for raw in (b"[]", b"{", b'{"a":1,"a":2}', b'\xff'):
            self.assertEqual(self.request("PUT", raw=raw)[0], 400)
        for value in (draft() | {"workflowId": "different.id"}, draft() | {"status": "active"}):
            self.assertEqual(self.request("PUT", value=value)[0], 400)
        self.assertEqual(self.request("PUT", value=draft(), headers={"Content-Type": "text/plain"})[0], 415)
        self.assertEqual(self.request("PUT", value=draft(), headers={"Transfer-Encoding": "chunked"})[0], 400)
        self.assertEqual(self.request("PUT", headers={"Content-Length": str(MAX_BYTES + 1)})[0], 413)
        self.assertEqual(self.request("PUT", headers={"Content-Length": "bad"})[0], 400)
        self.assertEqual(self.request("PUT")[0], 413)

    def test_incomplete_body_is_rejected(self) -> None:
        message = (f"PUT {PATH} HTTP/1.0\r\nHost: 127.0.0.1:{self.server.server_port}\r\n"
                   f"Origin: {self.server.origin}\r\nContent-Type: application/json\r\n"
                   "Content-Length: 10\r\n\r\n{").encode()
        with socket.create_connection(("127.0.0.1", self.server.server_port), timeout=5) as client:
            client.sendall(message)
            client.shutdown(socket.SHUT_WR)
            received = b""
            while part := client.recv(4096):
                received += part
        self.assertIn(b"400 Bad Request", received)

    def test_static_allowlist_and_security_headers(self) -> None:
        for asset in ASSETS:
            status, headers, body = self.request(path=asset)
            self.assertEqual(status, 200)
            self.assertEqual(body, b"synthetic fixture")
            self.assertEqual(headers["X-Content-Type-Options"], "nosniff")
            self.assertIn("connect-src 'self'", headers["Content-Security-Policy"])
            self.assertNotIn("Access-Control-Allow-Origin", headers)
        target = self.root / "pilot/workflow-studio/app.js"
        target.unlink()
        target.symlink_to(Path(self.temp.name) / "outside.js")
        self.assertEqual(self.request(path="/pilot/workflow-studio/app.js")[0], 403)

    def test_failures_are_sanitized(self) -> None:
        for error in (OSError("private path"), ValueError("private payload"), RecursionError("private")):
            with patch.object(self.server.store, "save", side_effect=error):
                status, _, body = self.request("PUT", value=draft())
            self.assertIn(status, (400, 503))
            self.assertNotIn(b"private", body)

    def test_validation_blocks_discarded_and_unimplemented_semantics(self) -> None:
        candidates = []
        cycle = draft()
        cast(list[object], cycle["transitions"]).append({"from": "review", "to": "start"})
        candidates.append(cycle)
        disabled = draft()
        cast(list[dict[str, object]], disabled["nodes"])[1]["enabled"] = False
        candidates.append(disabled)
        expression = draft()
        cast(list[dict[str, object]], expression["transitions"])[0]["condition"] = "unimplemented"
        candidates.append(expression)
        agent = draft()
        cast(list[dict[str, object]], agent["nodes"])[1] = {
            "id": "review", "type": "agent", "displayName": "Synthetic agent",
            "config": {"agentId": "example", "agentVersion": "1.0.0",
                       "humanReviewRequired": True, "failureMode": "ordinary-human-path"},
        }
        candidates.append(agent)
        etag: dict[str, str] = {}
        for candidate in candidates:
            status, headers, _ = self.request("PUT", value=candidate, headers=etag)
            self.assertIn(status, (200, 201))
            etag = {"If-Match": headers["ETag"]}
            result = loads(self.request("POST", PATH + "/validate", headers=etag)[2])
            self.assertFalse(result["deployable"])
            self.assertTrue(result["errors"])

    def test_cli_stops_cleanly(self) -> None:
        for effect in (None, KeyboardInterrupt()):
            with patch("sys.argv", ["studio", "--database", "synthetic.sqlite3"]), \
                 patch("pilot.studio_server.StudioServer") as server, patch("builtins.print"):
                server.return_value.__enter__.return_value.serve_forever.side_effect = effect
                main()
                server.return_value.__exit__.assert_called_once()

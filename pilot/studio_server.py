"""Loopback-only synthetic draft pilot. Never expose this host to a network.

Serves the existing editor and a deliberately small draft API. Publication,
retirement, case execution, agent calls and external integrations are absent.
"""
from argparse import ArgumentParser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from re import fullmatch
from sqlite3 import Error as DatabaseError
from typing import cast
from urllib.parse import urlsplit

from pilot.studio_store import MAX_BYTES, Conflict, StudioStore, canonical, parse_document
from reference.workflow_compiler import compile_workflow

ASSETS = {
    "/pilot/workflow-studio/": ("pilot/workflow-studio/index.html", "text/html; charset=utf-8"),
    "/pilot/workflow-studio/index.html": ("pilot/workflow-studio/index.html", "text/html; charset=utf-8"),
    "/pilot/workflow-studio/app.js": ("pilot/workflow-studio/app.js", "text/javascript; charset=utf-8"),
    "/pilot/workflow-studio/styles.css": ("pilot/workflow-studio/styles.css", "text/css; charset=utf-8"),
    "/pilot/workflow-studio/sample.workflow.json": ("pilot/workflow-studio/sample.workflow.json", "application/json"),
    "/config/workflow-editor-catalog.example.json": ("config/workflow-editor-catalog.example.json", "application/json"),
    "/api/v1/workflow-studio/node-types": ("config/workflow-editor-catalog.example.json", "application/json"),
}
VERSION_ROUTE = r"/api/v1/workflows/([a-z][a-z0-9.-]{2,127})/versions/([0-9]+\.[0-9]+\.[0-9]+)(/validate)?"
VERSIONS_ROUTE = r"/api/v1/workflows/([a-z][a-z0-9.-]{2,127})/versions"


class StudioServer(ThreadingHTTPServer):
    """Local development server. The listening address is not configurable."""

    def __init__(self, root: Path, database: Path, port: int = 8765) -> None:
        self.root = root.resolve()
        self.store = StudioStore(database, self.root / "contracts/workflow-definition.schema.json")
        super().__init__(("127.0.0.1", port), StudioHandler)

    @property
    def origin(self) -> str:
        return f"http://127.0.0.1:{self.server_port}"


class StudioHandler(BaseHTTPRequestHandler):
    """No directory browsing, CORS, credentials, or unrestricted static serving."""

    server_version = "CareOpsStudioPilot"
    sys_version = ""

    @property
    def app(self) -> StudioServer:
        return cast(StudioServer, self.server)

    def log_message(self, format: str, *args: object) -> None:
        # URLs and exception strings can contain sensitive values; do not log them.
        return

    def _send(
        self, status: int, body: bytes, content_type: str = "application/json", *, etag: str = "",
    ) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Content-Security-Policy", "default-src 'self'; connect-src 'self'; "
                         "object-src 'none'; base-uri 'none'; frame-ancestors 'none'")
        if etag:
            self.send_header("ETag", etag)
        self.end_headers()
        self.wfile.write(body)

    def _json(self, status: int, value: object, *, etag: str = "") -> None:
        self._send(status, canonical(value).encode("utf-8"), etag=etag)

    def _allowed(self) -> bool:
        if self.headers.get("Host") != self.app.origin.removeprefix("http://"):
            return False
        origin = self.headers.get("Origin")
        if self.command in {"PUT", "POST"}:
            return origin == self.app.origin
        return origin in (None, self.app.origin)

    def _dispatch(self) -> None:
        self.connection.settimeout(5)
        if not self._allowed():
            self._json(403, {"error": "Only this loopback origin is permitted"})
            return
        try:
            self._route(urlsplit(self.path).path)
        except Conflict:
            self._json(409, {"error": "Draft changed or ETag missing; reload before saving"})
        except KeyError:
            self._json(404, {"error": "Workflow version not found"})
        except (ValueError, RecursionError):
            self._json(400, {"error": "Invalid draft, request or stored data"})
        except (OSError, DatabaseError):
            self._json(503, {"error": "Local pilot storage or asset unavailable"})

    def _route(self, path: str) -> None:
        if self.command == "GET" and path in ASSETS:
            relative, content_type = ASSETS[path]
            target = (self.app.root / relative).resolve()
            if not target.is_relative_to(self.app.root):
                self._json(403, {"error": "Asset outside the pilot root"})
                return
            self._send(200, target.read_bytes(), content_type)
            return
        if self.command == "GET" and path == "/health":
            self._json(200, {"mode": "synthetic-draft-only", "publicationEnabled": False,
                             "caseExecutionEnabled": False})
            return
        versions = fullmatch(VERSIONS_ROUTE, path)
        if versions and self.command == "GET":
            self._json(200, self.app.store.list_versions(versions[1]))
            return
        match = fullmatch(VERSION_ROUTE, path)
        if match is None:
            self._json(404, {"error": "Endpoint unavailable in this draft-only pilot"})
            return
        workflow_id, version, validation = match.groups()
        if self.command == "PUT" and validation is None:
            if self.headers.get("Content-Type", "").split(";")[0].strip() != "application/json":
                self._json(415, {"error": "Use application/json"})
                return
            if self.headers.get("Transfer-Encoding") is not None:
                self._json(400, {"error": "Chunked request bodies are not supported"})
                return
            length = int(self.headers.get("Content-Length", "-1"))
            if not 0 < length <= MAX_BYTES:
                self._json(413, {"error": "Request is empty or exceeds the pilot size limit"})
                return
            raw = self.rfile.read(length)
            if len(raw) != length:
                raise ValueError("Incomplete body")
            definition = parse_document(raw)
            if (definition.get("workflowId"), definition.get("version")) != (workflow_id, version):
                raise ValueError("Path identity differs from definition")
            record = self.app.store.save(definition, expected_etag=self.headers.get("If-Match"))
            self._json(201 if record["revision"] == 1 else 200, record, etag=cast(str, record["etag"]))
        elif self.command == "GET" and validation is None:
            record = self.app.store.get(workflow_id, version)
            self._json(200, record, etag=cast(str, record["etag"]))
        elif self.command == "POST" and validation:
            record = self.app.store.get(workflow_id, version)
            if self.headers.get("If-Match", cast(str, record["etag"])) != record["etag"]:
                raise Conflict("Validation revision changed")
            definition = cast(dict[str, object], record["definition"])
            errors: list[str] = []
            try:
                compile_workflow(definition)
            except ValueError:
                errors.append("Stored draft fails reference graph or node validation")
            # The reference compiler currently drops these semantics; never silently accept them.
            nodes = cast(list[dict[str, object]], definition["nodes"])
            edges = cast(list[dict[str, object]], definition["transitions"])
            if any(n.get("enabled") is False for n in nodes) or any("condition" in e for e in edges):
                errors.append("Disabled nodes and expression transitions are not supported by this pilot")
            if any(n["type"] in {"agent", "deterministic_check"} for n in nodes):
                errors.append("Automated checks need registered execution adapters; this pilot has none")
            self._json(200, {"workflowId": workflow_id, "version": version,
                             "definitionHash": record["definitionHash"], "deployable": not errors,
                             "errors": errors}, etag=cast(str, record["etag"]))
        else:
            self._json(405, {"error": "Method unavailable in this draft-only pilot"})

    do_GET = _dispatch
    do_PUT = _dispatch
    do_POST = _dispatch
    do_OPTIONS = _dispatch


def main() -> None:
    parser = ArgumentParser(description="Local synthetic Workflow Studio draft pilot")
    parser.add_argument("--database", type=Path, required=True, help="Path for synthetic drafts only")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    with StudioServer(root, args.database, args.port) as server:
        print(f"Synthetic draft-only pilot: {server.origin}/pilot/workflow-studio/")
        print(f"Set the editor API base URL to {server.origin}. No publication or case execution.")
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()

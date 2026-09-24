"""Exercise the actual module entry point without opening a network listener."""
import runpy
import unittest
from io import StringIO
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]


class EntrypointTests(unittest.TestCase):
    def test_help_exits_cleanly_before_creating_storage_or_listener(self) -> None:
        with patch("sys.argv", ["studio_server", "--help"]), \
             patch("sys.stdout", new_callable=StringIO) as output:
            with self.assertRaises(SystemExit) as result:
                runpy.run_path(str(ROOT / "pilot/studio_server.py"), run_name="__main__")
        self.assertEqual(result.exception.code, 0)
        self.assertIn("--database", output.getvalue())
        self.assertIn("--port", output.getvalue())
        self.assertNotIn("--host", output.getvalue())

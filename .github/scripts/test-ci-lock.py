"""Stale declarations must fail required source jobs, not just an optional updater."""
import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('lock_check', Path(__file__).with_name('check-ci-lock.py'))
lock_check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lock_check)


class LockTests(unittest.TestCase):
    def test_exact_selected_versions_and_normalised_names(self):
        lock_check.check('pip_audit==2.10.1\n', 'pip-audit==2.10.1 \\\n    --hash=sha256:example\n')

    def test_stale_missing_and_inexact_declarations_fail(self):
        for declarations, lock in [('ruff==0.17.1', 'ruff==0.17.0'), ('zizmor==1.31.1', 'ruff==0.17.1'), ('ruff>=0.17', 'ruff==0.17.1')]:
            with self.subTest(declarations=declarations), self.assertRaises(ValueError):
                lock_check.check(declarations, lock)


if __name__ == '__main__':
    unittest.main()

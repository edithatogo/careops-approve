"""Stale declarations must fail required source jobs, not just an optional updater."""
import importlib.util
import json
import shlex
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


class UpdaterContract(unittest.TestCase):
    def test_lock_aware_manager_owns_the_input_and_output_pair(self):
        config = json.loads(Path('renovate.json').read_text())
        self.assertIn('pip-compile', config['enabledManagers'])
        self.assertNotIn('pip_requirements', config['enabledManagers'])
        self.assertFalse(config['pip_requirements']['enabled'])
        self.assertEqual(config['pip-compile']['managerFilePatterns'], ['/^requirements-ci\\.lock$/'])

    def test_header_retains_only_the_actual_source_and_explicit_flag_values(self):
        header = Path('requirements-ci.lock').read_text().splitlines()[1]
        command = shlex.split(header.removeprefix('#    '))
        self.assertEqual(command[:4], ['uv', 'pip', 'compile', 'requirements-ci.txt'])
        self.assertIn('--python-version=3.15.1', command)
        self.assertIn('--output-file=requirements-ci.lock', command)
        self.assertNotIn('--no-config', command)
        self.assertNotIn('--python-version', command)
        self.assertNotIn('--output-file', command)

    def test_hosted_regeneration_preserves_the_discoverable_command(self):
        workflow = Path('.github/workflows/lock-refresh.yml').read_text()
        command = Path('requirements-ci.lock').read_text().splitlines()[1].removeprefix('#    ')
        self.assertIn('UV_CUSTOM_COMPILE_COMMAND: ' + command, workflow)


if __name__ == '__main__':
    unittest.main()

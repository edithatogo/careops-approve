"""Run the existing Python quality and 100 percent branch-coverage gates."""
import subprocess
import sys

CHECKS = [
    ('reference/pyproject.toml', ['reference', 'tests/reference'], 'reference', 'tests/reference'),
    ('tests/m365_pilot/pyproject.toml', ['scripts/build_m365_pilot.py', 'tests/m365_pilot'], 'scripts.build_m365_pilot', 'tests/m365_pilot'),
    ('reference/pyproject.toml', ['pilot/studio_store.py', 'pilot/studio_server.py', 'tests/studio'], 'pilot.studio_store,pilot.studio_server', 'tests/studio'),
]
for config, paths, source, tests in CHECKS:
    commands = [
        ['ruff', 'check', '--config', config, *paths],
        ['mypy', '--config-file', config, *paths],
        ['coverage', 'run', '--branch', '--source=' + source, '-m', 'unittest', 'discover', '-s', tests],
        ['coverage', 'report', '--show-missing', '--fail-under=100'],
    ]
    for command in commands:
        subprocess.run([sys.executable, '-m', *command], check=True)

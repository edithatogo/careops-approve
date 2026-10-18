"""Reject declared CI tool changes that are absent from the committed lock."""
import re
from pathlib import Path


def check(declarations, lock):
    expected = {}
    for raw in declarations.splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        match = re.fullmatch(r'([A-Za-z0-9_.-]+)==([A-Za-z0-9_.+!-]+)', line)
        if match is None:
            raise ValueError('CI tools require exact registry versions.')
        name, version = match.groups()
        name = re.sub(r'[-_.]+', '-', name).lower()
        if name in expected:
            raise ValueError('Duplicate declared CI tool.')
        expected[name] = version
    selected = {
        re.sub(r'[-_.]+', '-', name).lower(): version
        for name, version in re.findall(r'^([A-Za-z0-9_.-]+)==([^\s\\]+)', lock, re.M)
    }
    if not expected or any(selected.get(name) != version for name, version in expected.items()):
        raise ValueError('The committed CI lock does not match the declared tools; apply the generated repair.')


if __name__ == '__main__':
    check(Path('requirements-ci.txt').read_text(), Path('requirements-ci.lock').read_text())

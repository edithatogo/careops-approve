"""Select a published .NET 11 preview; never silently run the stable SDK instead."""
import hashlib
import json
import re
import sys
from pathlib import Path


def select(document):
    version = document.get('latest-sdk', '')
    if not re.fullmatch(r'11\.0\.\d+-(?:preview|rc)\.\d+\.\d+\.\d+', version):
        return None
    published = {
        sdk.get('version')
        for release in document.get('releases', [])
        for sdk in [release.get('sdk', {}), *release.get('sdks', [])]
    }
    return version if version in published else None


if __name__ == '__main__':
    manifest, receipt, output = map(Path, sys.argv[1:])
    data = manifest.read_bytes()
    candidate = select(json.loads(data))
    receipt.parent.mkdir(parents=True, exist_ok=True)
    receipt.write_text(json.dumps({
        'state': 'candidate-resolved' if candidate else 'unavailable',
        'sdk': candidate,
        'metadataSha256': hashlib.sha256(data).hexdigest(),
        'metadataSource': 'https://builds.dotnet.microsoft.com/dotnet/release-metadata/11.0/releases.json',
        'promoted': False,
        'nativeWrites': False,
    }, indent=2) + '\n')
    with output.open('a') as stream:
        stream.write('available=' + str(bool(candidate)).lower() + '\n')
        stream.write('version=' + (candidate or '') + '\n')

"""Verify and publish the exact Godot export consumed by GitHub Pages."""
from pathlib import Path, PurePosixPath
import argparse
import hashlib
import json
import os
import re
import subprocess

PROJECT = Path(__file__).resolve().parents[1]
REPOSITORY = PROJECT.parent
CRITICAL = {'index.html', 'index.js', 'index.pck', 'index.wasm', 'bridge.mjs',
            'build-id.mjs', 'build-guard.mjs', 'state-codec.mjs', 'invitations.mjs'}


def safe_name(name):
    path = PurePosixPath(name)
    if not name or path.is_absolute() or '..' in path.parts or '\\' in name or ':' in name:
        raise ValueError(f'Invalid artifact path: {name!r}')
    return path


def verify(directory, source=False, index=False):
    directory = directory.resolve()
    if index:
        prefix = directory.relative_to(REPOSITORY).as_posix()

        def read(name):
            safe_name(name)
            return subprocess.check_output(['git', '-C', str(REPOSITORY), 'show', f':{prefix}/{name}'])
    else:
        def read(name):
            return directory.joinpath(*safe_name(name).parts).read_bytes()

    info = json.loads(read('build-info.json'))
    if info.get('protocolVersion') != 3 or not info.get('buildId'):
        raise ValueError('Not a V3 artifact: build-info.json')
    if not CRITICAL.issubset(info.get('files', {})):
        raise ValueError('Missing critical runtime files in build-info.json')
    for name, expected in info['files'].items():
        data = read(name)
        if len(data) != expected['bytes'] or hashlib.sha256(data).hexdigest() != expected['sha256']:
            raise ValueError(f'Artifact content differs from its build manifest: {name}')
    identity = re.search(r'BUILD_ID\s*=\s*[\'"]([^\'"]+)', read('build-id.mjs').decode())
    if not identity or identity[1] != info['buildId']:
        raise ValueError('JavaScript and artifact build IDs differ')
    if b'build-guard.mjs' not in read('index.html') or b'classroomJoin' not in read('index.html'):
        raise ValueError('Entry HTML is not the V3 shell')
    if source:
        from write_build_info import source_manifest
        if info.get('source', {}).get('digest') != source_manifest()['digest']:
            raise ValueError('Source changed after export. Run tools/build.ps1 before committing docs/.')
    return info


def publish():
    source = PROJECT / 'build'
    target = REPOSITORY / 'docs'
    info = verify(source, source=True)
    target.mkdir(exist_ok=True)
    # Copy only files explicitly hashed by the build; no evidence, recordings or caches.
    # The manifest goes last so it never describes a partially copied local export.
    for name in [*info['files'], 'build-info.json']:
        path = safe_name(name)
        destination = target.joinpath(*path.parts)
        destination.parent.mkdir(parents=True, exist_ok=True)
        temporary = destination.with_name(destination.name + '.publishing')
        temporary.write_bytes(source.joinpath(*path.parts).read_bytes())
        os.replace(temporary, destination)
    verify(target, source=True)
    return info


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['verify', 'publish'])
    parser.add_argument('directory', nargs='?', default=str(REPOSITORY / 'docs'))
    parser.add_argument('--source', action='store_true', help='Require the current sources to match the export')
    parser.add_argument('--index', action='store_true', help='Check staged Git blob bytes, including line-ending filters')
    args = parser.parse_args()
    result = publish() if args.action == 'publish' else verify(Path(args.directory), args.source, args.index)
    print(json.dumps({'action': args.action, 'buildId': result['buildId'], 'files': len(result['files']), 'verified': True}))

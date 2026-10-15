#!/usr/bin/env python3
"""Build the embedded transport from pinned, verified upstream source.

Requires Go >= 1.26.2 (or the local .tooling/go installation). Apple targets
require Xcode; Android requires an SDK/NDK. Does not install a separate app.
"""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / 'packages/yanji_syncthing/native'
VERSION = '2.1.5'
SHA256 = '1b3e217022848b65a1b7ececa4d5e752fc044b4e8643befa1f9a8a9dc9b2bbbf'
MOBILE = 'v0.0.0-20260908204917-8b95e45f8d3e'


def run(arguments, env):
    subprocess.run([str(a) for a in arguments], cwd=NATIVE, env=env, check=True)


def prepare_source():
    tooling = ROOT / '.tooling'
    tooling.mkdir(exist_ok=True)
    archive = tooling / f'syncthing-v{VERSION}.tar.gz'
    if not archive.exists():
        url = f'https://codeload.github.com/syncthing/syncthing/tar.gz/refs/tags/v{VERSION}'
        temporary = archive.with_suffix('.download')
        urllib.request.urlretrieve(url, temporary)
        if hashlib.sha256(temporary.read_bytes()).hexdigest() != SHA256:
            temporary.unlink()
            raise RuntimeError('Upstream source checksum mismatch')
        temporary.rename(archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != SHA256:
        raise RuntimeError('Cached source checksum mismatch')
    source = tooling / f'syncthing-{VERSION}'
    if not source.exists():
        with tarfile.open(archive) as compressed:
            compressed.extractall(tooling, filter='data')
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('target', choices=['apple', 'android', 'windows', 'harness', 'all'])
    args = parser.parse_args()
    prepare_source()
    local_go = ROOT / '.tooling/go/bin/go'
    go = local_go if local_go.exists() else shutil.which('go')
    if not go:
        raise SystemExit('Install Go >= 1.26.2 before building the transport.')
    tools = ROOT / '.tooling/go-tools'
    tools.mkdir(exist_ok=True)
    env = dict(os.environ, GOBIN=str(tools))
    env['PATH'] = os.pathsep.join([str(Path(go).parent), str(tools), env.get('PATH', '')])
    build = NATIVE / 'build'
    build.mkdir(exist_ok=True)
    if args.target in ['apple', 'android', 'all']:
        run([go, 'install', f'golang.org/x/mobile/cmd/gomobile@{MOBILE}'], env)
        run([go, 'install', f'golang.org/x/mobile/cmd/gobind@{MOBILE}'], env)
    if args.target in ['apple', 'all']:
        run([tools / 'gomobile', 'bind', '-target=ios,iossimulator,macos', '-tags=noassets',
             '-o', build / 'Engine.xcframework', './engine'], env)
    if args.target in ['android', 'all']:
        # x/mobile + the upstream Android network adapter use Go linkname hooks.
        run([tools / 'gomobile', 'bind', '-target=android', '-androidapi=26',
             '-tags=noassets', '-ldflags=-checklinkname=0',
             '-o', build / 'engine.aar', './engine'], env)
    if args.target in ['windows', 'all']:
        windows = dict(env, GOOS='windows', GOARCH='amd64', CGO_ENABLED='0')
        run([go, 'build', '-tags=noassets', '-o', build / 'sync-harness-windows-amd64.exe',
             './cmd/bridge'], windows)
    if args.target in ['harness', 'all']:
        run([go, 'build', '-tags=noassets', '-o', build / 'sync-harness', './cmd/bridge'], env)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Isolated Go c-shared gate. Does not build, load or select Syncthing in the app."""
import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sdk', required=True, type=Path, help='Official SDK root containing default/openharmony')
    parser.add_argument('--device', help='Optional disposable emulator target, e.g. 127.0.0.1:10000')
    args = parser.parse_args()
    native = args.sdk.resolve() / 'default/openharmony/native'
    compiler = native / 'llvm/bin/clang'
    go = ROOT / '.tooling/go/bin/go'
    if not go.is_file():
        go = Path(shutil.which('go') or '/missing-go')
    if not compiler.is_file() or not go.is_file():
        raise SystemExit('Official native compiler and Go are required.')
    output = ROOT / 'work/harmonyos/syncthing_abi_gate'
    output.mkdir(parents=True, exist_ok=True)
    source = ROOT / 'tool/probes/syncthing_ohos'
    wrapper = output / 'ohos-clang'
    wrapper.write_text('#!/bin/sh\nexec ' + shlex.join([
        str(compiler), '--target=aarch64-linux-ohos', f'--sysroot={native / "sysroot"}'
    ]) + ' "$@"\n')
    wrapper.chmod(0o700)
    env = dict(os.environ, GOOS='ohos', GOARCH='arm64', CGO_ENABLED='1', GO111MODULE='off', CC=str(wrapper))

    def run(name, command, environment=env):
        process = subprocess.run([str(x) for x in command], env=environment, cwd=ROOT,
                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        (output / f'{name}.log').write_text(process.stdout)
        return process

    version = run('go-version', [go, 'version']).stdout.strip()
    direct = run('native-ohos', [go, 'build', '-buildmode=c-shared', '-o', output/'native.so', source/'main.go'])
    # Experimental compatibility probe, deliberately separate from a real port.
    shim_env = dict(env, GOOS='linux')
    library = output / 'linux-shim.so'
    shim = run('linux-shim', [go, 'build', '-buildmode=c-shared', '-o', library, source/'main.go'], shim_env)
    result = {'go': version, 'nativeOhosBuild': direct.returncode == 0,
              'experimentalLinuxShimBuild': shim.returncode == 0, 'runtimeLoad': None}
    if shim.returncode == 0:
        run('elf', [native/'llvm/bin/llvm-readelf', '-h', '-d', library])
    if args.device and shim.returncode == 0:
        hdc = args.sdk.resolve() / 'default/openharmony/toolchains/hdc'
        loader = output / 'loader'
        run('compile-loader', [wrapper, source/'load.c', '-ldl', '-o', loader])
        prefix = [hdc, '-t', args.device]
        run('send-library', [*prefix, 'file', 'send', library, '/data/local/tmp/yanji_go_probe.so'])
        run('send-loader', [*prefix, 'file', 'send', loader, '/data/local/tmp/yanji_go_loader'])
        run('chmod-loader', [*prefix, 'shell', 'chmod', '700', '/data/local/tmp/yanji_go_loader'])
        runtime = run('runtime', [*prefix, 'shell', '/data/local/tmp/yanji_go_loader'])
        result['runtimeLoad'] = 'YANJI_GO_ABI_PROBE=1' in runtime.stdout
    (output / 'result.json').write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result, ensure_ascii=False))
    print(f'Evidence: {output}')


if __name__ == '__main__':
    main()

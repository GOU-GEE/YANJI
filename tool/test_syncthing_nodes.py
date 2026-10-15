#!/usr/bin/env python3
"""Exercise real embedded nodes over isolated loopback TLS (no public services).
Build first: python3 tool/build_syncthing.py harness
"""
import base64
import hashlib
import json
from pathlib import Path
import socket
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
BINARY = ROOT / 'packages/yanji_syncthing/native/build/sync-harness'


def call(process, request):
    process.stdin.write(json.dumps(request) + '\n')
    process.stdin.flush()
    response = json.loads(process.stdout.readline())
    if 'error' in response:
        raise RuntimeError(response['error'])
    return response


def wait_for(predicate, seconds=45):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.25)
    raise AssertionError('Embedded transfer timed out')


def main():
    processes = []
    with tempfile.TemporaryDirectory(prefix='yanji-sync-nodes-') as temporary:
        root = Path(temporary)
        try:
            configs = []
            for name in ['a', 'b']:
                directory = root / name
                directory.mkdir()
                subprocess.run(['openssl', 'req', '-x509', '-newkey', 'rsa:2048',
                    '-keyout', str(directory / 'key.pem'), '-out', str(directory / 'cert.pem'),
                    '-days', '365', '-nodes', '-subj', '/CN=' + name],
                    check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                der = subprocess.check_output(['openssl', 'x509', '-in', str(directory / 'cert.pem'), '-outform', 'DER'])
                with socket.socket() as listener:
                    listener.bind(('127.0.0.1', 0))
                    port = listener.getsockname()[1]
                configs.append({
                    'command': 'start', 'directory': str(directory / 'engine'),
                    'folder_path': str(directory / 'records'), 'workspace': 'test',
                    'certificate': (directory / 'cert.pem').read_text(),
                    'private_key': (directory / 'key.pem').read_text(),
                    'local_only': True, 'listen': [f'tcp://127.0.0.1:{port}'],
                    '_fingerprint': base64.b64encode(hashlib.sha256(der).digest()).decode(), '_id': name,
                })
            for index, config in enumerate(configs):
                other = configs[1 - index]
                config['peers'] = [{'id': other['_id'], 'fingerprint': other['_fingerprint'], 'addresses': other['listen']}]
                process = subprocess.Popen([str(BINARY)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
                processes.append(process)
                call(process, config)
            a, b = root / 'a/records', root / 'b/records'
            (a / 'proof.txt').write_text('signed application operation transport')
            call(processes[0], {'command': 'scan'})
            wait_for(lambda: (b / 'proof.txt').exists())
            assert (b / 'proof.txt').read_text() == (a / 'proof.txt').read_text()
            assert call(processes[0], {'command': 'status'})['connected'] == ['b']
            (b / 'reply.txt').write_text('application receipt transport')
            call(processes[1], {'command': 'scan'})
            wait_for(lambda: (a / 'reply.txt').exists())
            print('PASS: paired TLS and bidirectional replication', flush=True)
            call(processes[1], {'command': 'stop'})
            (a / 'offline.txt').write_text('saved while recipient offline')
            call(processes[0], {'command': 'scan'})
            assert not (b / 'offline.txt').exists()
            call(processes[1], configs[1])
            wait_for(lambda: (b / 'offline.txt').exists(), seconds=75)
            assert (b / 'offline.txt').read_text() == (a / 'offline.txt').read_text()
            print('PASS: node restart resumes offline backlog', flush=True)
            call(processes[0], {**configs[0], 'command': 'configure', 'peers': []})
            wait_for(lambda: not call(processes[0], {'command': 'status'})['connected'])
            (a / 'revoked.txt').write_text('must not be shared after revocation')
            call(processes[0], {'command': 'scan'})
            time.sleep(3)
            assert not (b / 'revoked.txt').exists()
            print('PASS: revoked recipient receives no subsequent files', flush=True)
        finally:
            for process in processes:
                try:
                    call(process, {'command': 'stop'})
                    process.stdin.close()
                    process.wait(timeout=5)
                except Exception:
                    process.kill()


if __name__ == '__main__':
    main()

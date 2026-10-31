"""Run the already-built notification fixture on an unlocked OHOS emulator.

Usage: python3 tool/probes/harmonyos_study_notification_acceptance.py DEVICE INSTANCE TOOLS_ROOT
Install with -r only; this never uninstalls or opens the user's study database.
The caller must restore the main HAP after acceptance.
"""
from datetime import datetime
import json
from pathlib import Path
import re
import subprocess
import sys
import time
from urllib.request import Request, urlopen

device, instance, tools_root = sys.argv[1:]
root = Path(__file__).resolve().parents[2]
tools_root = Path(tools_root)
logs = root / 'work/harmonyos/study-notification-validation'
logs.mkdir(parents=True, exist_ok=True)
hdc = [str(tools_root / 'sdk/default/openharmony/toolchains/hdc'), '-t', device]
emulator = [str(tools_root / 'bin/Emulator'), '-instance', instance]
lines, seen = [], set()


def run(prefix, *args):
    return subprocess.check_output(prefix + list(args), text=True,
                                   stderr=subprocess.STDOUT, timeout=30)


def collect():
    pid = run(hdc, 'shell', 'pidof', 'com.example.yanji').strip()
    if pid.isdigit():
        for line in run(hdc, 'shell', 'hilog', '-x', '-P', pid).splitlines():
            if line not in seen:
                seen.add(line)
                lines.append(line)
    raw = '\n'.join(lines)
    (logs / 'device.log').write_text(raw)
    return raw


def wait_for(marker):
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        raw = collect()
        if 'Some tests failed.' in raw:
            raise RuntimeError('Device assertion failed; inspect device.log')
        if marker in raw:
            print(marker, flush=True)
            return raw
        time.sleep(1)
    raise RuntimeError(f'Timed out waiting for {marker}')


def layout(name, interactive=True):
    raw = run(emulator, '-uiLayout', *(['-i'] if interactive else []))
    (logs / f'{name}-layout.txt').write_text(raw)
    return raw


def shade(name, expected):
    run(hdc, 'shell', 'uitest', 'uiInput', 'keyEvent', 'Home')
    time.sleep(1)
    run(hdc, 'shell', 'uitest', 'uiInput', 'swipe', '200', '50', '200', '1700', '1000')
    time.sleep(1)
    raw = layout(name)
    if expected not in raw:
        raise RuntimeError(f'{expected} missing from actual system shade')
    run(hdc, 'shell', 'snapshot_display', '-f', '/data/local/tmp/yanji-notification.jpeg')
    run(hdc, 'file', 'recv', '/data/local/tmp/yanji-notification.jpeg', str(logs / f'{name}.jpeg'))
    return raw


def release(phase):
    with urlopen(Request(f'http://127.0.0.1:43171/{phase}', method='POST'), timeout=10) as reply:
        assert reply.status == 204


artifact = root / 'ohos/entry/build/default/outputs/default/entry-default-unsigned.hap'
installed = run(hdc, 'install', '-r', str(artifact))
(logs / 'install.log').write_text(installed)
assert 'install bundle successfully' in installed
run(hdc, 'shell', 'aa', 'force-stop', 'com.example.yanji')
assert 'start ability successfully' in run(hdc, 'shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.example.yanji')
assert 'OK' in run(hdc, 'fport', 'tcp:43171', 'tcp:43171')
try:
    wait_for('YANJI_STUDY_NOTIFICATION_REQUESTING_PERMISSION')
    # On a fresh installation, accept only the notification permission dialog.
    for _ in range(6):
        raw = layout('permission', interactive=False)
        allowed = re.search(r'Button 允许 \[id:(\d+)\]', raw)
        if allowed:
            run(emulator, '-click', allowed[1])
            break
        if 'YANJI_STUDY_NOTIFICATION_ACTIVE' in collect():
            break
        time.sleep(1)
    wait_for('YANJI_STUDY_NOTIFICATION_ACTIVE')
    raw = shade('background', '本段开始于')
    row = re.search(r'Row 通知验收数学 · 学习计时中[^\n]*\[id:(\d+)\]', raw)
    assert row, 'Notification row not found'
    run(emulator, '-click', row[1])
    time.sleep(1)
    release('background')
    wait_for('YANJI_STUDY_NOTIFICATION_PAUSED')
    shade('paused', '已暂停 · 累计')
    run(hdc, 'shell', 'uitest', 'uiInput', 'keyEvent', 'Back')
    run(hdc, 'shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.example.yanji')
    time.sleep(1)
    release('paused')
    raw = wait_for('All tests passed!')
    match = re.search(r'YANJI_STUDY_NOTIFICATION_PASS (\{[^\n]+\})', raw)
    assert match, 'Device result missing'
    result = json.loads(match[1])
    assert all(result[key] is True for key in (
        'foregroundCounterAdvanced', 'pauseCounterFrozen', 'resumeCounterAdvanced',
        'notificationTapReturnsOpen', 'completionRemovesNotification', 'staleSnapshotIgnored'))
    result.update(executedAt=datetime.now().astimezone().isoformat(timespec='seconds'),
                  device=device, instance=instance, success=True)
    (logs / 'result.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
finally:
    run(hdc, 'fport', 'rm', 'tcp:43171', 'tcp:43171')

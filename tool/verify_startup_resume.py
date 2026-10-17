"""Native lifecycle companion for integration_test/startup_reveal_test.dart.

Run beside flutter drive, pointing --log at that run's freshly truncated log.
Uses native screenshots and checks the PID; never uninstalls or clears app data.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--platform', choices=('android', 'ios'), required=True)
parser.add_argument('--device', required=True, help='adb serial or simulator UDID')
parser.add_argument('--log', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--adb', default='adb')
parser.add_argument('--xcrun', default='xcrun')
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)


def run(command):
    return subprocess.check_output(command, stderr=subprocess.STDOUT)


def await_marker(pattern, timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        content = args.log.read_text(errors='replace') if args.log.exists() else ''
        match = re.search(pattern, content)
        if match:
            return match.group(1)
        if 'Some tests failed' in content or 'TEST FAILED' in content:
            raise SystemExit('Acceptance failed; inspect ' + str(args.log))
        time.sleep(.25)
    raise SystemExit('Timed out waiting for ' + pattern)


pid = await_marker(r'YANJI_STARTUP_WARM_READY pid=(\d+)', 900)
if args.platform == 'android':
    adb = [args.adb, '-s', args.device]
    before = run(adb + ['shell', 'pidof', 'com.example.yanji']).decode().strip()
    assert before == pid, (before, pid)
    (args.output / 'profile-before.png').write_bytes(
        run(adb + ['exec-out', 'screencap', '-p']))
    run(adb + ['shell', 'input', 'keyevent', 'KEYCODE_HOME'])
    time.sleep(3)
    run(adb + ['shell', 'am', 'start', '-n', 'com.example.yanji/.MainActivity'])
    after = run(adb + ['shell', 'pidof', 'com.example.yanji']).decode().strip()
else:
    simctl = [args.xcrun, 'simctl']
    run(simctl + ['io', args.device, 'screenshot', str(args.output / 'profile-before.png')])
    run(simctl + ['launch', args.device, 'com.apple.Preferences'])
    time.sleep(3)
    foreground = run(simctl + ['launch', args.device, 'com.example.yanji']).decode()
    after = foreground.strip().split(': ')[-1]
assert after == pid, (after, pid)
reported = await_marker(r'YANJI_STARTUP_NATIVE_RESUME_PASS pid=(\d+)', 120)
assert reported == pid, (reported, pid)
time.sleep(.5)
if args.platform == 'android':
    screenshot = run(adb + ['exec-out', 'screencap', '-p'])
    (args.output / 'today-restored.png').write_bytes(screenshot)
else:
    run(simctl + ['io', args.device, 'screenshot', str(args.output / 'today-restored.png')])
(args.output / 'native-resume.json').write_text(json.dumps({
    'platform': args.platform,
    'same_process': True,
    'device_test_reported_resume_pass': True,
}, indent=2) + '\n')
print('Native background/resume passed with the same process; check flutter drive exit status.')

"""Host-side companion for the Android integration test; use a test emulator."""
import argparse
import pathlib
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument("--serial", required=True)
parser.add_argument("--log", type=pathlib.Path, required=True)
parser.add_argument("--output", type=pathlib.Path, required=True)
parser.add_argument("--adb", default="adb")
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)


def run(*command):
    return subprocess.run(
        [args.adb, "-s", args.serial, *command], check=True, capture_output=True
    ).stdout


def await_stage(stage, timeout):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        text = args.log.read_text(errors="replace") if args.log.exists() else ""
        if stage in text:
            return
        if "Some tests failed" in text or "Gradle task assembleDebug failed" in text:
            raise SystemExit("Integration test failed; inspect its log.")
        time.sleep(0.5)
    raise SystemExit("Timed out waiting for " + stage)


await_stage("YANJI_STAGE_TIMER_RUNNING", 900)
run("shell", "input", "keyevent", "KEYCODE_HOME")
time.sleep(5)
run("shell", "input", "keyevent", "KEYCODE_SLEEP")
time.sleep(5)
run("shell", "input", "keyevent", "KEYCODE_WAKEUP")
run("shell", "wm", "dismiss-keyguard")
run("shell", "am", "start", "-n", "com.example.yanji/.MainActivity")
time.sleep(3)
(args.output / "android-timer.png").write_bytes(run("exec-out", "screencap", "-p"))
(args.output / "android-lifecycle.txt").write_text(
    "Host adb on " + args.serial + ": HOME, 5 s, screen off, 5 s, wake, "
    "dismiss keyguard, foreground. Integration test separately checks elapsed "
    ">= 60 s, pause exclusion, completion and persisted review.\n"
)
await_stage("YANJI_STAGE_CYCLE_SAVED", 180)
(args.output / "android-statistics.png").write_bytes(run("exec-out", "screencap", "-p"))
print("Lifecycle sequence and screenshots captured; check the test exit status.")

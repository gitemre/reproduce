# A run, step by step

`reproduce` is an Agent Skill, not a command-line tool. You give a coding agent a crash; the agent reads
`SKILL.md`, keeps one run folder per crash and follows six steps. This page is the human walkthrough.

Install first ([README's Install](../README.md#install)).

## Start a run

Open your app's repository in the agent and give it the crash:

```text
/reproduce https://sentry.io/organizations/acme/issues/123/
```

A tester without the code opens an empty folder and gives the same link. A crash file, an `.ips`, logcat or a
pasted stack trace works too.

The agent writes `.reproduce/runs/<slug>/` at the nearest folder up that has `.git` or `.reproduce`, else
in the current folder. `progress.md` records one line per step with `done` and the proving file.

## The six steps

| Step | What happens | Proves |
|---|---|---|
| 0 Tools and project | probes the app, its modules and test command; for a device run, its build | `project.yaml` |
| 1 Fetch and analyze | reads the event, stack, device facts, breadcrumbs and logs | `crash.json`, `analysis.json` |
| 2 Code | follows the stack to the bad value and the entry point | `analysis.json` |
| 3 Reproduce | a failing test, or a model-led device run with raw platform tools | `manifest.json`, `observed.json`, UI dump/log/video |
| 4 Referee | a fresh blind referee compares type and place | `verdict/NN.json` |
| 5 Report | the report, the guide and the evidence | `report.md`, `guide.md`, video |

Step 0 records `testable: false` when the app has no usable test target; the device path is next. Step 1
stops when the link cannot be fetched or the format cannot be read: ask for an exported event or a fuller
trace. Never invent the missing half.

## Code path

When the app has a test target and the crash is reachable from it:

1. Find the test source set and the app's own command for the reported build (`./gradlew
   testReleaseUnitTest` for a release report, `swift test -c release`, `flutter test`, `npx jest`, …).
2. Write one test in that source set. It calls the real code with the reported input and lets the exception
   escape. It must not catch the exception (`assertThrows`, `XCTAssertThrows`, `throwsA`, `toThrow`,
   `assertFailsWith`, `runCatching`, `try?`, `@Test(expected = …)`) and must not mock the crashing function.
3. Run the app's command; keep the raw output and any JUnit XML or `.ips` under the run.
4. The reader writes `observed.json` from the raw output; the reproducer does not edit it.

Creating a new test target is not part of the skill. Adding a test file to an existing target needs the
user's explicit yes and is recorded in the report.

## Device path

When the crash is UI/device-level, the app has no usable test, or a tester has only an APK/`.app`, the model
drives a device and chooses the commands. Build the variant the report names — normally the release build;
a debug build is the exception. If the release build needs signing you do not have, use the artifact you were
given. The full vocabulary is in
[device-path.md](../skills/reproduce/references/device-path.md),
[android-device.md](../skills/reproduce/references/android-device.md),
[ios-device.md](../skills/reproduce/references/ios-device.md) and
[ios-ui-automation.md](../skills/reproduce/references/ios-ui-automation.md).

**Android**

```bash
avdmanager create avd -n reproduce-<id> -k 'system-images;android-<api>;google_apis;arm64-v8a' -d pixel_7
emulator -avd reproduce-<id> -read-only -no-snapshot-save -no-boot-anim -no-audio -port 5580 &
adb -s emulator-5580 wait-for-device

adb -s emulator-5580 shell settings put global airplane_mode_on 1
adb -s emulator-5580 shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true
adb -s emulator-5580 shell svc wifi disable
adb -s emulator-5580 install -r -t <app.apk>

adb -s emulator-5580 shell uiautomator dump /sdcard/ui.xml
adb -s emulator-5580 exec-out cat /sdcard/ui.xml > ui-01.xml
# read the nodes, then tap the chosen bounds
adb -s emulator-5580 shell input tap 540 492
adb -s emulator-5580 shell screenrecord --time-limit 180 /sdcard/replay.mp4 &
```

**iOS**

```bash
xcrun simctl create reproduce-<id> '<device type>' <runtime id>
xcrun simctl boot <udid>
xcrun simctl bootstatus <udid> -b
xcrun simctl install <udid> <App.app>
```

`simctl` does not tap. Write a temporary XCUITest yourself
([ios-ui-automation.md](../skills/reproduce/references/ios-ui-automation.md)); UI automation is model-written
and temporary. The simulator shares the Mac's network; if the app reports to production, stop and ask the
developer for an explicit yes (or a build that reports to the team's test project), and record the answer in
`progress.md`.

The evidence is what the device wrote: `ui-*.xml`/`dump-*.json`, `logcat.txt`/`sim-log.txt`, the app's
Sentry/Crashlytics queue or `.ips` report, screenshots and `replay.mp4`. The reader writes
`attempts/NN/observed.json` from it; the referee reads that file, not the page.

## Referee and report

A fresh blind referee reads only the target, the observation and the rules. It writes `verdict/NN.json` with
a status, a level, the matched type and place, and the rules it applied. The orchestrator may reject a
malformed verdict and ask once; it may not overrule or upgrade one.

With no subagent, the fallback writes the evidence to files, starts a new step and reads only those files. It
records `single-context` and the report must say `REPRODUCED (single-context)`.

`report.md` states the verdict, evidence, test path/command, environment, what was inferred and what was not
done. A device report adds the video and screenshots. The reproduction test stays uncommitted unless the
developer asks.

## Verdicts

| Verdict | Means |
|---|---|
| `REPRODUCED (blame-frame)` | same exception type, at the same app frame |
| `REPRODUCED (call-path)` | and the callers match too |
| `REPRODUCED (system-frames)` | no app frame on either side; the framework frames match |
| `REPRODUCED (recursion)` | the same frame repeats on both stacks |
| `REPRODUCED (type-and-message)` | no frames; type and message match |
| `PARTIAL` | only the type, or only the place, matches |
| `NOT_REPRODUCED` | it ran, and nothing matching crashed |
| `NO_VERDICT` | nothing could be checked; the reason says why |

A wrong `REPRODUCED` is worse than a miss. When the evidence is insufficient or two rules conflict, the
lower verdict wins.

## Testers without the code

The agent finds no app, takes the tester path and writes `guide.md`: the exact build, device, OS, language,
time zone and network, numbered steps, variants to try, how to recognize the crash, and a ticket. Every line
is labelled observed, inferred or guess. A guide-only run also writes `report.md` with `NO_VERDICT`. With the
crashing APK or `.app`, the device path runs it without the code; you can boot the emulator or simulator and
install the build yourself, and the agent isolates Android before launch, confirms the device/build and drives
it. See [TESTERS.md](TESTERS.md) and
[references/tester.md](../skills/reproduce/references/tester.md).

## Sandboxes and headless runs

- A link needs the network; a test command writes its build caches (`~/.gradle`, Xcode's); a device needs
  `adb`, the emulator or Xcode outside the sandbox. If the sandbox refuses a command, the agent says so and
  asks; it never retries outside the sandbox without your yes.
- Start at the app's repository root. A marker one folder up keeps a run started in a subfolder inside the
  workspace.
- Devices may run in a window or headless. A headless run uses an Android emulator with `-no-window` and
  an iOS simulator through `simctl` without `Simulator.app`; it records `"headless": true` in
  `device-env.json`. There is no user watching or touching the device, so screenshots, video and the app
  log are the evidence; when a step needs a human, the agent stops and says what is missing.
- An Android emulator on Linux needs KVM. A missing system image is a multi-GB download; only you decide it.

## Checks

```bash
sh scripts/e2e-clean.sh
```

It extracts a clean copy, installs both skills and checks their sizes and links and that they ship no code.

## After the report

If the verdict is `REPRODUCED`, the agent asks once whether to fix. Yes hands the run folder to `fix-crash`;
no keeps the report. `PARTIAL`, `NOT_REPRODUCED` and `NO_VERDICT` are not fixable. The fix flow is in
[fix-crash/SKILL.md](../skills/fix-crash/SKILL.md).

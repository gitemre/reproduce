# For testers without the code

You can make a crash happen again without the app's repository. You need the crash link and a build:
an Android APK, or an iPhone TestFlight/Ad Hoc build. A raw `.app` from a simulator is not installable on
a physical iPhone.

## Two ways

- **Agent-driven:** the device is attached to the agent's machine, or an emulator/simulator is available,
  and `adb`/`Xcode` is installed. The agent installs, drives and records the evidence. See
  [device-path.md](../skills/reproduce/references/device-path.md).
- **Tester-driven:** you have a physical device and no tools, or the device is not attached to the agent's
  machine. The agent writes a one-page brief; you install, reproduce and send the evidence. See
  [tester-manual.md](../skills/reproduce/references/tester-manual.md) and
  [tester-evidence.md](../skills/reproduce/references/tester-evidence.md).

The report records `driver: tester` and `evidence: supplied` for a tester-driven run. It never claims the
agent observed the device.

## Tester-driven, step by step

1. **Install.** Android: download the APK and allow the browser to install unknown apps. iPhone: install
   TestFlight, accept the invite and install the build; an Ad Hoc build needs your UDID registered.
2. **Check the build.** App version/build, OS version and model; screenshot each.
3. **Set up.** Locale, time zone, network, account and permissions. Decide whether a fresh install is
   needed; clearing data can remove the crash state.
4. **Reproduce.** Follow the brief's numbered steps; read the screen before each tap. Note the exact start
   and end time.
5. **Capture.** Screen recording, screenshots, and one of: an Android bug report, an iOS `.ips` from
   Analytics Data, a TestFlight feedback, or the test Crashlytics/Sentry event.
6. **Send back.** One folder or zip with the video, screenshots, log/`.ips`, exact input and time.

The full menu paths and the no-tool evidence options are in
[tester-evidence.md](../skills/reproduce/references/tester-evidence.md).

## What to send the developer

- The issue link, the exact build (version and build number), device, OS, language and time zone.
- The steps, what you expected and what happened; the start/end time.
- The video, screenshots, crash log/bug report/`.ips`, and the test-project event if the app reports to one.
- `guide.md`, `report.md` and the run folder.

If the crash does not happen, send the referee's `NOT_REPRODUCED` and the variants you tried; that is a
useful result, not a failure. If no build is available, the run is guide-only: `guide.md` and a `NO_VERDICT`
report, with the missing piece named.

## Limits

A video can show the app failed, but it may not carry an exception type or frame. A crash log, `.ips` or
test-project event can. The referee decides; a video alone may be `PARTIAL` or `NO_VERDICT`. Do not send a
full device backup, passwords, cookies or personal data; redact names and ids that are not needed to place
the crash.

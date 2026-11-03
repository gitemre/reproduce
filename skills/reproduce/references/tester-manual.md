# Tester-driven run

Use this when the tester has a physical device and no adb/Xcode, or the device is not attached to the
agent's machine. The agent writes the brief and reads the evidence; it does not claim to drive the device.
The run records `driver: tester` and `evidence: supplied`.

## Contents

Ask first · The brief · Install · Check the build · Set up · The test project · Reproduce · Capture ·
Send back · Stop · Privacy · What this proves

## Ask first

Ask these before writing the brief:

- Android or iPhone, model and OS version.
- The build: an APK link, TestFlight, Ad Hoc, or none.
- The app version and build number, and whether it is the reported build.
- Account state, locale, time zone and network (Wi-Fi, cellular, VPN).
- What is installed on the tester's machine: nothing, adb, Xcode, or a device manager.
- Whether the device is attached to the machine where the agent runs.
- The crash link or report, the screen it starts from, and any exact input.

If the device is attached and `adb`/`Xcode` is available, use the agent-driven device path instead
([tester.md](tester.md#agent-driven)). If there is no build, the run is guide-only.

## The brief

Write a one-page brief the tester can follow without the skill or the agent. Use the tester's language;
keep commands and menu names in the device's language. The brief has:

- **What you need:** the build link, device, OS, account and time.
- **Install:** only the tester's platform.
- **Check the build:** app version/build, OS and model; a screenshot of each.
- **Set up:** locale, time zone, network, permissions and account; fresh install or existing data.
- **Steps to try:** numbered, with screen and button labels; include "if you see X, tap Y" branches.
- **Label each step:** observed (in the evidence), inferred (from the stack) or guess.
- **Capture:** screen recording, screenshots and the log path; point to
  [tester-evidence.md](tester-evidence.md).
- **Send back:** the exact file list.
- **Stop:** the conditions below.
- **Privacy:** the note below.

## Install

**Android APK**

1. Open the APK link on the device and download it.
2. Allow the browser or file manager to install unknown apps.
3. Install; accept the Play Protect warning if the build is expected.
4. "App not installed" usually means a different signature, the wrong ABI, too little storage or an
   unsupported OS. Stop and ask the developer for a build that matches the device.

**iPhone**

- **TestFlight:** install TestFlight from the App Store, accept the invite, then install the app. Confirm
  the build number in TestFlight and in the app.
- **Ad Hoc:** the tester's device UDID must be registered in the build. Install from the developer's link.
- **A raw `.app` from a simulator cannot be installed on a physical iPhone.** Do not try; ask for
  TestFlight or an Ad Hoc build.
- If neither exists, stop: there is no physical-device run.

## Check the build

Record the app version and build, the OS version and the device model; screenshot the app's About or
Settings screen. If the build is not the reported one, say so in the brief and the report. A different
build may still reproduce, but it is not the reported build.

## Set up

- Set the reported locale and time zone if the crash may be locale-specific.
- Use the reported network: Wi-Fi, cellular, VPN or offline. On Android, isolation means airplane mode and
  Wi-Fi off; if the route needs the app's backend, stop and ask for a test backend instead of weakening
  isolation silently.
- Sign in with the tester's own account; never ask for a password in chat.
- Grant or deny the permissions the crash needs.
- Decide whether the app needs a fresh install or existing data. Clearing app data can remove the state
  that triggers the crash; record the choice.
- Menu names vary by OEM and language. Search Settings for "Bug report", "Analytics" or "Screen recorder";
  use the label the tester actually sees, not a remembered path.

## The test project

Ask the developer for a build that reports to a **test** Crashlytics or Sentry project. The tester
reproduces; the agent fetches the new event by the start/end time, build and device. No adb/Xcode and no API
token on the tester's machine. A production-reporting build needs the user's explicit yes; redact user data.

If there is no test project, use the on-device evidence in [tester-evidence.md](tester-evidence.md).

## Reproduce

- Follow the numbered steps; read the screen before each tap, not only the remembered coordinate.
- Note the exact start and end time of the attempt.
- If the app reports to a test Crashlytics or Sentry project, the agent can fetch the new event by time and
  build after the tester reproduces; the tester does not need the API.
- If the crash does not happen, retry once from a fresh launch, then try the brief's variant; record what
  changed. Do not invent a crash or edit the evidence.

## Capture

Use [tester-evidence.md](tester-evidence.md). The minimum is a screen recording that shows the crash and a
screenshot of the app version/build and OS. A crash log or test-project event is stronger than a video.

## Send back

Ask for one folder or zip with:

- the screen recording;
- the crash screenshot and the app-version/OS screenshots;
- the crash log, `.ips`, bug report or test-project event link/time;
- the exact input and the start/end time;
- any variant that changed the result.

Name the files so the reader can place them, for example `replay.mp4`, `crash.png`, `build.png`,
`logcat.txt` or `crash.ips`.

## Stop

Stop and say why when:

- the build reports to production and the user has not given an explicit yes;
- the build is not the reported build and no matching build is available;
- there is no build for a physical device;
- the route needs a backend the isolated device cannot reach and no test backend exists;
- the tester cannot capture any evidence;
- the evidence is a video only and the target has no visible type or frame; report the gap instead of
  guessing.

## Privacy

Ask for the crash screen only. Do not ask for a full device backup, passwords, cookies, tokens, personal
messages or photos. Redact names, emails and ids that are not needed to place the crash. The tester signs in
on the device; the agent never asks for the password.

## What this proves

A tester-driven run is a **supplied** observation, not an agent-observed device run. The report says
`driver: tester` and `evidence: supplied`. A crash log or test-project event can place the type and frame; a
video alone may be `PARTIAL` or `NO_VERDICT`. The referee decides; the tester's effort does not upgrade the
evidence.

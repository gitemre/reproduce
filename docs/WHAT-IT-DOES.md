# What it does to your machine

`reproduce` is a skill: it runs the tools you already have. It does not install a binary, does not use
`sudo`, and sends no telemetry.

## Files it writes

All under the app's `.reproduce/runs/<slug>/` (the nearest folder up with `.git` or `.reproduce`):

| File | Content |
|---|---|
| `crash.json`, `analysis.json` | the target crash and the hypothesis |
| `source.json`, `raw/` | the fetched event(s), verbatim; tokens are never written |
| `project.yaml` | the app id, modules and test command |
| `attempts/NN/manifest.json`, `attempts/NN/observed.json` | the test/device run and its raw evidence |
| `verdict/NN.json` | the blind referee's status, level, matched type/place and rules |
| `report.md`, `guide.md` | the report and the tester guide |
| `progress.md` | one line per step |
| `flow.json`, `ui.json`, `actions.log` | the UI steps, when the device path ran |
| `logcat.txt`, `crash.ips`, `screenshots/`, `replay.mp4` | the device evidence, when the device path ran |

It also writes the agent's installed skill copy (outside the app). On iOS it may write temporary XCUITest
automation in a scratch project or a temporary test target; the skill ships no runner.

It never edits the app's production code, dependencies, build configuration or signing. A reproduction test
in an existing test target is uncommitted unless you ask.

## Hosts it contacts

Only when the crash input or the fetch path needs them:

| Host | Why |
|---|---|
| `sentry.io` (or a self-hosted Sentry) | read the issue and its events |
| `firebasecrashlytics.googleapis.com`, `firebase.googleapis.com` | read the Crashlytics issue/events and the app id |
| `console.firebase.google.com`, `*.sentry.io` | the browser fetch path |
| `crash-stats.mozilla.org` | a Mozilla crash-stats link |

Tokens come from the environment (`SENTRY_AUTH_TOKEN`, `REPRODUCE_GOOGLE_TOKEN` or
`GOOGLE_OAUTH_ACCESS_TOKEN`) and are never printed or written to the run. The browser path uses your existing
session; it never reads cookies, local storage or authorization headers.

The app under test may contact its own backend. The Android device is isolated before launch (airplane mode,
wifi and data off), so its SDKs see no network. The iOS simulator shares the Mac's network and cannot be
isolated; an app with a reporting SDK runs there only after your explicit yes.

## Programs it starts

- `adb`, the Android emulator and `avdmanager` (Android device path).
- `xcrun simctl` and, when UI automation is needed, `xcodebuild` for the model-written XCUITest (iOS device path).
- The app's own build/test tools: Gradle, `xcodebuild`, `swift test`, `flutter test`, Jest.


No proxy, mock server, third-party device tool or `sudo`.

## Downloads

The skill downloads nothing. It may ask you to install an Android system image (a multi-GB SDK download) or an
iOS simulator runtime through Xcode; that is your decision, and the run stops until it is there. Building the
The temporary iOS automation uses the local Xcode toolchain only.

## What it does not do

- No telemetry, analytics or crash reporting of its own.
- No edits to the crash service: every request is a read (`GET`); it never resolves, assigns, shares or
  deletes an issue.
- No production deploy, signing change or store upload.
- No claim without evidence: the blind referee writes the verdict, and a missing observation is
  `NO_VERDICT`, not a pass.

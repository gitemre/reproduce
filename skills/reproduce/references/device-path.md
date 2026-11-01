# Device path (model-led)

Use this page when the crash needs the app's UI or a device: the blamed code needs Android's own classes
or a `Context`, an Activity/Fragment/View/ViewModel lifecycle, a UI route, or the app has no usable
unit-test target. The code path ([code-path.md](code-path.md)) stays the first choice when a test can reach
the crash.

There is no `reproduce` binary, no Python driver and no bundled UI runner. The platform tools are `adb`,
`emulator`, `avdmanager`, `xcrun simctl` and `xcodebuild`. If iOS needs UI automation, write a temporary
XCUITest yourself; the skill gives the constraints, not the code.

## You decide the sequence

- Read the screen and the evidence; choose the next command from what the app actually shows. Do not follow a
  fixed example list when the screen says otherwise.
- Use raw platform tools or a helper from this skill, whichever gives the better evidence. A helper is not a
  required step.
- If a documented command does not fit the device or the app, adapt it and record why in `progress.md`.

Non-negotiables:

- Isolate the Android device before launch; on iOS ask before launching an app that reports to production.
- One crash gets one run folder: `.reproduce/runs/<slug>/`. Keep the evidence you actually used.
- Keep the run folder out of git: add `.reproduce/` to the app's local `.git/info/exclude` or `.gitignore`.
- No production code, dependency, build configuration or signing change.
- Do not fake a device, log, screenshot, video or verdict.

## 0 Project and build

Probe the app with [code-path.md](code-path.md): app id, module, build command, test source set, toolchain.
Build the app's own artifact **for the build the crash came from**: normally the release build in
production, not debug. Match the version, build and flavor the report names; if the crash came with an APK
or `.app`, use that artifact first, and a local build of the same version is the fallback. Android:
`./gradlew :app:assembleRelease` or the flavor's release task, `flutter build apk --release`, or the React
Native release task. iOS: `xcodebuild -project … -scheme … -configuration Release -sdk iphonesimulator
-derivedDataPath .reproduce/DerivedData build`. A debug build is the exception, for a debug-only report. If
the release build needs signing you do not have, use the artifact the user provides; never change signing.
Keep the artifact path. Do not change production code, dependencies, build configuration or signing.

## 1 Crash and analysis

Resolve the crash with the code path's fetch ([browser-fetch.md](browser-fetch.md),
[api-fetch.md](api-fetch.md), [formats/](formats/)). Write `crash.json` and `analysis.json`: exception chain,
blame frame, trigger, screens, platform, OS, locale. The device path adds the UI route that reaches it.

## 2 Environment

### device-env.json

Write `device-env.json`:

| Field | Type | Notes |
|---|---|---|
| `platform` | string | `android` or `ios` |
| `os` | string | Android API level or iOS version |
| `device` | string | AVD or simulator name and model |
| `locale`, `timezone` | strings | the language and time zone the run used |
| `app_id` | string | package name or bundle identifier |
| `artifact` | string | the installed APK or `.app` path |
| `variant` | string | `release` or `debug`; the build the crash came from |
| `isolation` | string | `airplane`, `read-only` or `none` (iOS), and how it was checked |
| `headless` | boolean | optional; `true` when no emulator or simulator window was opened |

Boot a device of the run's own. A headless run is allowed: Android adds `-no-window`, iOS stays on
`simctl` without `Simulator.app`, and the run records `"headless": true`; the evidence is still the
screenshots, video and app log.

- Android: [android-device.md](android-device.md) — emulator, install, locale, network cut, UI tree, logcat
  and video.
- iOS: [ios-device.md](ios-device.md) — simulator, install, crash reports, and when to ask about reporting.
  For UI, write temporary automation with [ios-ui-automation.md](ios-ui-automation.md).

## 3 Reproduce

Drive the app to the reported trigger. Prefer the route the analysis names, but read each screen before the
next action; an unexpected dialog, onboarding screen or permission prompt is information, not an obstacle to
tap through blindly.

Android: `uiautomator dump` gives an XML tree; read the nodes, choose a node by its text/content-desc and
bounds, and tap its centre. Re-dump after navigation; a dump during a splash animation may return a null
root, so wait and retry. Keep `ui-*.xml`, `logcat.txt` and `replay.mp4`.

iOS: `simctl` handles lifecycle, install and video; it does not tap. Write a temporary XCUITest yourself
([ios-ui-automation.md](ios-ui-automation.md)); keep `dump-*.json`, `sim-log.txt`/the `.ips`, and `replay.mp4`.

## 4 Evidence and the verdict

The evidence is what the device wrote, not what the page says:

- Android: `logcat.txt` (fatal exception and frames), the app's Sentry/Crashlytics queue, `ui-*.xml`,
  screenshots and `replay.mp4`.
- iOS: `.ips` reports in the Mac's `Library/Logs/DiagnosticReports`, SentryCrash JSON in the app's data
  container, the app's queued Sentry events, screenshots and `replay.mp4`.

The reader writes `attempts/NN/observed.json` from these files, as on the code path
([reader.md](reader.md)); the referee reads that file, not the page. Keep the raw evidence unedited.
Record the run in `attempts/NN/manifest.json` with `mode: device`, the artifact, the commands, the start
time and `raw` ([schemas.md](schemas.md#manifestjson)); it is context, never evidence. A device manifest is:

```json
{"mode":"device","test_path":"","test_command":"","artifact":"app-debug.apk",
 "commands":["adb install -r -t app-debug.apk","adb shell am start -W -n com.shop.app/.MainActivity"],
 "raw":["logcat.txt","replay.mp4"],"started_at":"2026-11-01T10:00:00Z"}
```

The observation uses the `crash.json` exception shape with `evidence: observed`, `source: logcat.txt` and
`raw: logcat.txt`; the reader writes it, never the reproducer.

Hand the target and the evidence to the blind referee ([referee.md](referee.md), [rules.md](rules.md)).
Record the status and level; never upgrade a status because a screen looks right.

## 5 Report

Write `report.md` and `guide.md` with [report.md](report.md): verdict, evidence, UI steps, device/OS,
isolation, video/screenshots, what was inferred and what was not done. The Reproduction section names the
device run, artifact, manifest and evidence instead of a test path. Leave a reproduction test uncommitted
unless the developer asks for it.

## When it fails

- **No emulator/simulator or tool:** stop; the user installs it. Do not fake a device.
- **App not buildable/installable/launchable:** read the build log, emulator log or `logcat.txt`; stop with
  the reason.
- **The crash does not happen:** re-read the evidence, retry the route from a fresh launch, try the next
  analysis hypothesis; then report `NOT_REPRODUCED` with the reason.
- **The route needs a signed-in session:** ask the user to sign in on the device, or use the app's test
  account; never ask for a password in chat and never put one in a command.
- **The route needs the app's backend:** the isolated Android device cannot reach it; stop and say so. Do not
  weaken isolation without the user's explicit yes.
- **Isolation refused:** stop; do not continue on a production-reporting app.
- **iOS UI automation unavailable:** write a minimal XCUITest, or report `NO_VERDICT`; do not claim a UI run
  that did not happen.

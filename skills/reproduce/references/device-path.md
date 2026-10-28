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
- No production code, dependency, build configuration or signing change.
- Do not fake a device, log, screenshot, video or verdict.

## 0 Project and build

Probe the app with [code-path.md](code-path.md): app id, module, build command, test source set, toolchain.
Build the app's own artifact. Android: `./gradlew :app:assembleDebug`, `flutter build apk --debug`, or the
React Native Gradle task. iOS: `xcodebuild -project … -scheme … -configuration Debug -sdk iphonesimulator
-derivedDataPath .reproduce/DerivedData build`. Keep the artifact path. Do not change production code,
dependencies, build configuration or signing.

## 1 Crash and analysis

Resolve the crash with the code path's fetch ([browser-fetch.md](browser-fetch.md),
[api-fetch.md](api-fetch.md), [formats/](formats/)). Write `crash.json` and `analysis.json`: exception chain,
blame frame, trigger, screens, platform, OS, locale. The device path adds the UI route that reaches it.

## 2 Environment

Write `device-env.json`: platform, OS/API level, device profile, locale, timezone, app id, artifact,
isolation. Boot a device of the run's own.

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

Hand the target and the evidence to the blind referee ([referee.md](referee.md), [rules.md](rules.md)).
Record the status and level; never upgrade a status because a screen looks right.

## 5 Report

Write `report.md` and `guide.md` with [report.md](report.md): verdict, evidence, UI steps, device/OS,
isolation, video/screenshots, what was inferred and what was not done. Leave a reproduction test uncommitted
unless the developer asks for it.

## When it fails

- **No emulator/simulator or tool:** stop; the user installs it. Do not fake a device.
- **App not buildable/installable/launchable:** read the build log, emulator log or `logcat.txt`; stop with
  the reason.
- **The crash does not happen:** re-read the evidence, retry the route from a fresh launch, try the next
  analysis hypothesis; then report `NOT_REPRODUCED` with the reason.
- **Isolation refused:** stop; do not continue on a production-reporting app.
- **iOS UI automation unavailable:** write a minimal XCUITest, or report `NO_VERDICT`; do not claim a UI run
  that did not happen.

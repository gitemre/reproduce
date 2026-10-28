# iOS device path (raw simctl)

The model chooses the commands. `xcrun simctl` handles the simulator lifecycle, install, launch and video.
It cannot tap or read the accessibility tree; for UI, write temporary automation yourself
([ios-ui-automation.md](ios-ui-automation.md)).

## Create and boot

List what the Mac has:

```bash
xcrun simctl list runtimes
xcrun simctl list devicetypes
```

A runtime supports only some device types. Create an iPad or iPhone of the crash's model and OS, then boot:

```bash
xcrun simctl create reproduce-<id> '<device type>' <runtime id>
xcrun simctl boot <udid>
xcrun simctl bootstatus <udid> -b
xcrun simctl install <udid> <App.app>
```

Use the same bundle identifier as the crash. `simctl launch <udid> <bundle>` starts it;
`simctl terminate`, `simctl io <udid> screenshot shot.png` and
`simctl io <udid> recordVideo --codec=h264 replay.mp4` are the other lifecycle commands.

## Isolation

The iOS simulator shares the Mac's network; Apple's tools cannot cut it for one simulator. If the app reports
to production (Sentry, Crashlytics, analytics), stop and ask the developer for an explicit yes, or use a build
that reports to the team's test project. Record the answer in `progress.md`. Never launch such an app on the
simulator without that yes.

## UI

`simctl` does not tap. Write the UI automation yourself: a temporary XCUITest target or scratch Xcode
project, run with `xcodebuild test`. The app needs no production change; a temporary test target is still a
build change, so ask before adding one and remove it after. Do not expect a bundled runner or script. Read the
dump before each action; choose by label/frame, not by a remembered coordinate.

## Evidence

The device writes the crash, not the page:

- `.ips` reports in `$HOME/Library/Logs/DiagnosticReports` (newest first).
- SentryCrash JSON under the app's data container:
  `xcrun simctl get_app_container <udid> <bundle> data`, then `Library/Caches/SentryCrash/<App>/Reports/`.
- The app's queued Sentry events.
- The simulator log:
  `xcrun simctl spawn <udid> log show --last 10m --style compact --predicate 'process == "<App>"'`.
- `replay.mp4`, screenshots and the app's own error text.

Symbolicate a Swift trap with `atos -arch arm64 -o <App.app>/<App> -l <image_addr> <pc>`; the app binary is
in the `.app`, the addresses are in the SentryCrash report.

## When it fails

- **No runtime/device type:** install the runtime or pick a supported type; do not fake an iPad with a phone.
- **App not installable/launchable:** read the `simctl` error and the simulator log; stop with the reason.
- **No UI access:** write an XCUITest; do not claim taps you did not perform.
- **Reporting app without permission:** stop; do not launch it.

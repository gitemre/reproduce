# Tester path (device)

## Scope

The device path is available and skill-native: no `reproduce` binary, no app test target. A tester with the
crash link and an APK or a simulator `.app` can use it. The code path (a test in the app) is the developer's;
the device path needs no checkout.

## What to do

1. Make a folder for the run and the artifact: `.reproduce/runs/<slug>/` (the folder is the run root).
2. Read the crash with the skill's readers ([browser-fetch.md](browser-fetch.md),
   [api-fetch.md](api-fetch.md), [formats/](formats/)). Write `crash.json` and `analysis.json`: exception,
   frame, trigger, screens, platform.
3. Boot a device of the run's own; [device-path.md](device-path.md) has the exact commands.
   - Android: create/boot an emulator, install `<app.apk>`, cut the network, launch.
   - iOS: create/boot a simulator, install `<App.app>`; ask before launching an app that reports to
     production (the simulator shares the Mac's network).
4. Drive the UI with raw platform tools; [android-device.md](android-device.md) has the adb vocabulary,
   [ios-device.md](ios-device.md) the simctl lifecycle and [ios-ui-automation.md](ios-ui-automation.md) how
   to write temporary iOS UI automation. A crash right after a step is the evidence; otherwise repeat the
   analysis hypothesis once.
5. Record the video and screenshots with the platform tools (`adb shell screenrecord`, `simctl io
   recordVideo`, `screencap`/`simctl io screenshot`), collect the logs (Android `logcat`, Sentry queue; iOS
   `.ips` and SentryCrash reports, the app's queue), and hand the target and evidence to the referee.
6. Write `report.md` and `guide.md` with [report.md](report.md); name the device, the isolation, the video
   and the evidence. Stop the emulator/simulator when done.

Never fake a device, a screenshot, a video or a verdict. A guardrail (`NO_VERDICT`) is better than a claim.

## No code and no APK?

Stop. Ask for the crash link and, if they have it, the build. A guide from the report is still possible, but
it is not a reproduction; never claim a device run, a video or a verdict that did not happen.

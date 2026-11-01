# Tester path (device)

## Scope

The device path is available and skill-native: no `reproduce` binary, no app test target. A tester with the
crash link and an APK or a simulator `.app` can use it. The code path (a test in the app) is the developer's;
the device path needs no checkout.

The tester may prepare the device instead of the agent: boot the emulator or simulator and install the
crashing build; on Android, do not launch it before the agent isolates the device. The agent then confirms
the app id, version and build, isolates Android before launch, drives the UI and records the evidence. It
never claims a run it did not see. If the route needs a signed-in session, the tester can sign in on the
device; never ask for a password in chat.

## What to do

1. Make a folder for the run and the artifact: `.reproduce/runs/<slug>/` (the folder is the run root).
2. Read the crash with the skill's readers ([browser-fetch.md](browser-fetch.md),
   [api-fetch.md](api-fetch.md), [formats/](formats/)). Write `crash.json` and `analysis.json`: exception,
   frame, trigger, screens, platform. With only an artifact, read its package/bundle id and version
   (`aapt`/`plutil`; the platform pages have the command).
3. Boot a device of the run's own, or use the one the tester prepared and installed. In that case confirm
   the app id, version, build and isolation before step 4. If it was already launched, force-stop it, apply
   the isolation, and start it again. [device-path.md](device-path.md) has the platform vocabulary; you
   choose the commands from the screen.
   - Android: create/boot an emulator, install `<app.apk>`, cut the network, launch.
   - iOS: create/boot a simulator, install `<App.app>`; ask before launching an app that reports to
     production (the simulator shares the Mac's network).
4. Drive the UI with raw platform tools; [android-device.md](android-device.md) has the adb vocabulary,
   [ios-device.md](ios-device.md) the simctl lifecycle and [ios-ui-automation.md](ios-ui-automation.md) how
   to write temporary iOS UI automation. A crash right after a step is the evidence; otherwise repeat the
   analysis hypothesis once.
5. Record the video and screenshots with the platform tools (`adb shell screenrecord`, `simctl io
   recordVideo`, `screencap`/`simctl io screenshot`), collect the logs (Android `logcat`, Sentry queue; iOS
   `.ips` and SentryCrash reports, the app's queue). The reader writes `attempts/NN/observed.json` from that
   evidence; hand the target and the observation to the referee.
6. Write `report.md` and `guide.md` with [report.md](report.md); name the device, the isolation, the video
   and the evidence. Stop the emulator/simulator when done.

Never fake a device, a screenshot, a video or a verdict. A guardrail (`NO_VERDICT`) is better than a claim.

## No code and no APK?

This is a guide-only run: read the crash with the readers (`SKILL.md` step 1), write `crash.json` and
`analysis.json`, then `guide.md` and a `report.md` with `NO_VERDICT`. It is not a reproduction; never claim
a device run, a video or a verdict that did not happen. Ask for the build when the tester has one.

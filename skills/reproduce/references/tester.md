# Tester path

The device path needs no app test target. There are two ways to run it: the agent drives an attached
device or an emulator/simulator, or the tester drives a physical device and sends the evidence.

## Who drives?

- **Agent-driven:** the device is attached to this machine, or an emulator/simulator is available, and
  `adb`/`Xcode` is installed. Follow [device-path.md](device-path.md) and the steps below.
- **Tester-driven:** a physical device, no adb/Xcode, or no USB access from the agent. Follow
  [tester-manual.md](tester-manual.md) and [tester-evidence.md](tester-evidence.md). The agent writes the
  brief and reads the evidence; the run records `driver: tester` and `evidence: supplied`.
- **Guide-only:** no app and no build. Write `guide.md` and a `NO_VERDICT` report; never claim a run.

A physical iPhone cannot install a raw `.app`; it needs TestFlight, Ad Hoc or the App Store. A simulator
`.app` is not installable on a physical device.

## Agent-driven

1. Make a folder for the run and the artifact: `.reproduce/runs/<slug>/` (the folder is the run folder).
2. Read the crash with the skill's readers ([browser-fetch.md](browser-fetch.md),
   [api-fetch.md](api-fetch.md), the matching file in `formats/`). Write `crash.json` and `analysis.json`:
   exception, frame, trigger, screens, platform. With only an artifact, read its package/bundle id and
   version (`aapt`/`plutil`; the platform pages have the command).
3. Boot a device of the run's own, or use the one the tester prepared and installed. Confirm the app id,
   version, build and isolation before step 4. If it was already launched, force-stop it, apply the
   isolation, and start it again. [device-path.md](device-path.md) has the platform vocabulary; you choose
   the commands from the screen.
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

## Tester-driven

Use this when the tester has the device and the agent does not. The agent still reads the crash, writes the
brief, and reads the returned evidence.

1. Read the crash and write `crash.json`/`analysis.json` as above.
2. Ask the questions in [tester-manual.md](tester-manual.md#ask-first): device, OS, build source, version,
   account, locale, network and tools.
3. Write `guide.md` as the tester brief; add the install, build-check, setup, capture, send-back, stop and
   privacy sections from [tester-manual.md](tester-manual.md).
4. The tester installs the build, reproduces, and sends the files in
   [tester-evidence.md](tester-evidence.md).
5. The reader turns the returned log, `.ips`, bug report or test-project event into
   `attempts/NN/observed.json` with `evidence: supplied`; a video alone may be `PARTIAL` or `NO_VERDICT`.
6. The report says `driver: tester`; it does not claim an agent-observed device run. The referee decides.

## Guide-only

No app and no build: read the crash with the readers, write `crash.json` and `analysis.json`, then `guide.md`
and a `report.md` with `NO_VERDICT`. It is not a reproduction; never claim a device run, a video or a
verdict that did not happen. Ask for the build when the tester has one.

Never fake a device, a screenshot, a video or a verdict. A guardrail (`NO_VERDICT`) is better than a claim.

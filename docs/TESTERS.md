# For testers without the code

You can make a crash happen again without the app's repository. You need the crash link and, for a device
run, the crashing APK or simulator `.app`.

## What you get

Open a coding agent in an empty folder and give it the crash. The skill finds no app, so it takes the tester
path and writes:

- `guide.md` — the exact build, device, OS, language, time zone and network; numbered steps to the crash;
  variants to try; how to recognize the crash; a ticket to fill in. Each line is labelled **observed**,
  **inferred** or **guess**.
- `report.md` — the engineering record once a run has happened.
- A run folder under `.reproduce/runs/<slug>/` with the fetch output and, for a device run, the flow,
  screenshots and `replay.mp4`.

A guide alone is not a reproduction. Never claim a device run, a video or a verdict that did not happen.

## With the APK or `.app`

The device path needs no code and no test target:

1. Put the artifact and the run folder in the same place (`.reproduce/runs/<slug>/`).
2. The agent reads the crash with the skill's readers and writes `crash.json`/`analysis.json`.
3. It boots its own emulator or simulator, installs the artifact and isolates Android before launch.
   The iOS simulator shares the Mac's network; an app that reports to production needs your explicit yes.
4. It drives the UI with raw `adb`/`simctl` and, on iOS, temporary XCUITest automation; records `replay.mp4` and
   collects the app's logs, `.ips`/SentryCrash report or queued Sentry events.
5. A fresh blind referee writes `verdict/NN.json`; the report cites the exact evidence.

The commands are in [device-path.md](../skills/reproduce/references/device-path.md) and
[USAGE.md](USAGE.md#device-path).

## What to send the developer

- The issue link and the exact build tested (version and build number).
- The device, OS, language and time zone.
- The steps, what you expected and what happened.
- The time of the crash, and the new event link if the app reports to a test project.
- `report.md`, `replay.mp4` and the run folder.

If the crash does not happen, send the referee's `NOT_REPRODUCED` and the variants you tried; that is a
useful result, not a failure. If no device or artifact is available, the run stops at `NO_VERDICT` with the
missing piece named.

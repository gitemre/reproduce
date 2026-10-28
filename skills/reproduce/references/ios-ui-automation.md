# iOS UI automation (model-written)

`xcrun simctl` cannot tap or read the accessibility tree. If the crash needs an iOS UI action, **write the
temporary UI automation yourself**; do not expect a bundled runner or a script in this skill.

## What to write

Use Apple's XCUITest in a temporary test target or a scratch Xcode project. The test should:

- launch the app by bundle id (the app needs no production change),
- read the accessibility tree or query elements by label/identifier,
- tap, type, swipe and wait as the route requires,
- let the crash happen; do not catch it,
- take screenshots and keep the test output.

XCUITest is the first-party option. If you choose another tool, it must run on the simulator, need no change
to the app's production target, and leave the same evidence.

## Rules

- Do not add a permanent test target to the app; a temporary target/project is a build change and needs the
  user's explicit yes. Remove it after the run, or keep it uncommitted outside the app.
- Do not modify the app's production code, dependencies, build configuration or signing.
- Read the dump before each action; do not guess coordinates or reuse a previous screen's frames.
- Keep `dump-*.json`, `sim-log.txt`/the `.ips`, screenshots and `replay.mp4`.
- If you cannot write or run the automation, stop and report `NO_VERDICT`; never claim taps that did not
  happen.

## Evidence

The crash is the app's, not the test's: use the `.ips`/SentryCrash report, the simulator log, the app's
Sentry queue and the video. The test file is a tool; the app's report is the target evidence.

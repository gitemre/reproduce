# Changelog

All notable changes to `reproduce` are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html): from 1.0.0 on, a change to a command, a flag or a
file format that breaks its earlier use comes with a new major version.

Version 2.0 has no version constant: a release is a git tag. The last Go implementation is in the private `reproduce-dev` repository.

## [Unreleased]

## [2.0.1] - 2026-10-28

### Changed

- **The model owns the device strategy.** The skill gives the goal, the constraints and the evidence
  standard; the agent chooses the commands from the screen. No fixed command sequence is required.
- **Android is raw `adb`/`uiautomator`.** Android setup, isolation, the UI tree, logcat and video are
  documented as platform vocabulary in `references/android-device.md`.
- **iOS is raw `simctl`.** `references/ios-device.md` covers the simulator and crash reports. When UI
  automation is needed, `references/ios-ui-automation.md` tells the model to write a temporary XCUITest
  itself; the skill ships no runner.

### Removed

- `skills/reproduce/scripts/android_ui.py`, `skills/reproduce/scripts/ios_ui.py`,
  `skills/reproduce/references/drivers.md`, `skills/reproduce/assets/ios-runner/` and
  `skills/reproduce/references/ios-runner.md`. The skill has no Python runtime, no Swift runner and no code
  asset; the public smoke check enforces a Markdown-only skill.

### Evaluation

- Model-led runs without the Python drivers: Kese K-01 (raw adb, call-path), Rota R-04 (raw adb,
  blame-frame) and Kiler S-04 (raw simctl + XCUITest automation, system-frames) all REPRODUCED.

## [2.0.0] - 2026-10-28

`reproduce` is now an Agent Skill. The Go CLI, the binary and the legacy skill are gone.

### Added

- **Skill-native device path.** `scripts/android_ui.py` (adb + `uiautomator`) and `scripts/ios_ui.py` +
  `assets/ios-runner/` (simctl + XCUITest) drive the app, keep `ui.json`/`flow.json`/`actions.log`, record
  `replay.mp4` and collect logcat, `.ips`, SentryCrash and queued Sentry evidence. No binary, no test target
  on the app.
- **Binary-free install.** `scripts/install-skill.sh` copies the skill into `~/.claude/skills`,
  `~/.agents/skills`, Antigravity's folder, a project's `.claude/skills`/`.agents/skills`, or any
  `--skills-dir`. `npx skills add gitemre/reproduce` is the network path.
- **Public smoke check.** `scripts/e2e-clean.sh` extracts a fresh checkout, installs the skill and runs both
  device drivers' `--help`. The full benchmark, schema checkers and unit tests are maintainer material kept outside
  this public repository.
- **Evaluation.** 19 real crash scenarios (Kese 4, Kiler 5, Rota 5, Nabız 5): 19 REPRODUCED, each with a
  device or code run, a video/report and a blind-referee verdict.

### Changed

- The six steps (tools/project, fetch/analyze, code, reproduce, referee, report) are the product; the code
  path writes a test only when the app has an existing test target, and the device path covers UI/device
  crashes, apps without one, and testers with an APK/`.app`.
- Reports and guides are the skill's output; the run folder is `.reproduce/runs/<slug>/`.
- The public repo ships the skill, the installer and the user docs only; the benchmark and tests are kept
  outside this public repository.

### Removed

- `cmd/`, `internal/`, `go.mod`, `go.sum`, `testdata/`, `spike/`, `scripts/ips-summary.sh`,
  `skill/embed.go`, `skill/embed_test.go`, `skill/pages.go`, `skill/pages_test.go` and
  `skill/reproduce-legacy/`. They remain in the private `reproduce-dev` repository.
- `docs/CLI.md` and the CLI command tables.
- The public `benchmark/` tree (33-case seed, fixtures, checkers, scorer and tests); it stays private.

### Known limits

- Creating a new test target is not part of the skill; apps without one use the device path, so the
  answer-key E criterion (a failing test) is not exercised there.
- The iOS simulator cannot be isolated from production reporting; an app with a reporting SDK needs the
  user's explicit yes.

## [1.0.0] - 2026-10-24

The first public release.

### Added

- **Inputs.** Crashlytics links (the Crashlytics API with a `gcloud` or `REPRODUCE_GOOGLE_TOKEN` token; the
  Firebase app id is looked up when the project has no `google-services.json`), Sentry links (the event, the
  issue's events through every page, up to five attachments) and Mozilla crash-stats links. Files and pasted
  text: Crashlytics and Sentry event JSON (one event or a list), a stack trace copied from the Crashlytics
  console, Sentry's issue text, Apple `.ips` and `.crash`
  reports, logcat (fatal exceptions, crash handlers such as ACRA, logged throwables as non-fatals), Java and
  Kotlin traces, JUnit XML, XCTest and `swift test` output. `fetch adb:<serial>` reads a connected Android
  device's latest crash with its facts; `fetch sim:<udid>` a simulator's newest crash report on the Mac.
  Flutter (Dart) and React Native (JavaScript) errors are unwrapped from any of these into their own
  exception chain, and `flutter test` and Jest failures are read.
- **Analysis.** Category and engine, trigger, screens, the values in the message, device facts, what each
  fact of the report means and its effect on the reproduction (evidence), the session's breadcrumbs as a
  timeline, ranked hypotheses, and where in the app's source the report's events, screens and values are
  (`analysis.json`). The issue's other events (up to `--events N`, 100) are clustered by stack variant, app
  version, OS, device and state, and the report says which cluster a reproduction covers. `fetch --json`
  prints a brief of at most 16 KB; `reproduce show` gives the rest a slice at a time. `reproduce hint` keeps
  a crash service's AI reading or a person's as a suggestion, never as evidence.
- **Engines.** The code engine runs one test under `reproduce verify -- <test command>` (Gradle with a JDK
  its version accepts, `xcodebuild`, `swift test`, `flutter test` with the Flutter the project pins, Jest;
  `--offline` with no host outside the machine). The device engine creates its own emulator or simulator from
  `crash-env.yaml` (OS level, device profile, locale, time zone, permissions, launch arguments and intent
  extras, process state), installs and starts the app, and reads its log and crash reports. `reproduce build`
  builds the app with the JDK or Flutter SDK it needs.
- **Verification.** `reproduce verify` is the only judge: REPRODUCED (blame frame, call path or system
  frames), PARTIAL, NOT_REPRODUCED or NO_VERDICT, with its reasons, by exception type, crash location and
  call path. A test that throws the exception itself or a crash in a file the agent wrote never counts;
  obfuscated names match only within one build; the reported crash itself is never its own reproduction.
- **Isolation from production.** Before an app is installed or started, the Android device is cut off
  (`offline`) or the hosts of crash and analytics SDKs are blocked on it (`reporting`), and that is checked
  on the device; when it cannot be, `reproduce` refuses. The iOS simulator cannot be isolated, so an app
  with such an SDK is refused unless the developer accepts. `reproduce`'s own emulator boots read-only, on a
  free port, with an id of its own.
- **UI driver.** `reproduce ui` drives the app on Android (adb, `uiautomator` and its own screen reader) and
  the iOS simulator (its own XCUITest runner): the screen as elements, tap, type, swipe, back, deep links,
  process death, permissions, chained actions, and a step handed to a person. Each step is recorded in
  `flow.yaml` with checkpoints, and a crash right after a step is verified at once. `reproduce export`
  writes the flow as steps for testers, a UIAutomator test, an XCUITest or a Maestro flow.
- **Replay recording and `report.html`.** `reproduce replay` replays the flow from a clean start, records the
  screen and takes a screenshot after each step. `reproduce report` writes `report.md` and `report.html`: the
  video with a chapter per step, the steps with a screenshot each, the test environment next to the field
  device, the evidence and how to repeat it.
- **Flutter framework errors on devices.** For a Flutter debug build, `reproduce` reads the framework's errors
  from the app's own Dart VM service (one breakpoint, nothing written to the app).
- **Tester guide and the path to the error.** `reproduce guide` writes `guide.md` and `guide.html` from the
  report alone for a tester without the code: set up, steps from the breadcrumbs, the app's frames, logs and
  keys (or, after a device run that reached the error, its recorded steps), ranked variants as device actions
  (timing ones included: "right away, within about 0.4 s"), what may cause it, how to recognize the crash, and a
  ticket filled from a device run; each fact labelled observed, inferred or guess. `guide.html`
  (`reproduce guide --open`) draws the path to the error with branches a tester marks. The build's own UI
  strings name controls when the APK or `.app` is given. With the crashing APK or `.app` a tester can run it on
  an isolated device without the code; `fetch -` also reads a stack trace copied from the Crashlytics console.
- **Non-fatal errors.** For an error the app catches and hands to Sentry or Crashlytics, `verify`, `ui` and
  `replay` read the app's queued reports on reproduce's own device, and on iOS the app's own error lines in
  the simulator's log; when nothing can show it, the verdict is NO_VERDICT, never NOT_REPRODUCED.
- **The run's own reports.** Every run records the device's and the reporting SDKs' installation ids;
  `fetch`, clustering and the report keep events of reproduce runs apart, and when the developer let a run
  report to production (`network.isolation=none`), its own event found in the reported issue is evidence
  (level `same-issue`). `reproduce build` and the iOS plan never upload R8 mappings or dSYMs to production.
- **Devices you can watch.** Emulators and simulators run with a window (the simulator front end of the
  active Xcode, DeviceHub or Simulator) unless `--headless`, `REPRODUCE_HEADLESS=1`, CI or no display.
  `env stop` ends every emulator, simulator and UI runner the run started; `env apply` checks free disk first;
  `env set platform=` resets the other platform's device fields; `env set app.artifact=` refuses an `.aab`,
  `.ipa` or device build and compares package and version.
- **Report history.** report.md and report.html say what came after the attempt they stand on: later replays
  that did not reproduce, a flaky reproduction, a step after which the screen turned one flat colour (a
  possible visible symptom).
- **Symbols.** `reproduce retrace` maps R8-obfuscated frames and checks the mapping belongs to the crashing
  build. `reproduce symbolize` maps Dart AOT frames (`--symbols`, checked by build id or against the crashing
  version's APK, App Bundle, `.app`, `.ipa` or `.xcarchive`), React Native bundle positions (`--sourcemap`)
  and iOS addresses (`--dsym`, or the dSYM it finds on the Mac by UUID, through `xcrun atos`).
- **Redaction.** Signatures, tokens, keys and users' ids in URLs are masked in the analysis, verdicts,
  reports, the guide and `show`; Sentry user ids are hashed when the crash is read.
- **The skill.** An [Agent Skills](https://agentskills.io) skill embedded in the binary: `reproduce skill
  install` writes it for Claude Code (`~/.claude/skills`), the agents that read `~/.agents/skills` (Codex,
  OpenCode, Gemini CLI, Cursor, GitHub Copilot) and Antigravity CLI (`~/.gemini/config/skills`, when
  `~/.gemini` is there); `reproduce skill print` gives it to an agent without skills, starting with a file of
  the same text for the agent's file tool, and `--page N` in pages of about 8 KB for a shell tool that shows
  only part of a long output.
  `reproduce doctor` names the copy of `reproduce` that ran and its version, and checks the machine, an app's
  needs (`--dir`), an agent's sandbox (it tries a write where `reproduce` writes and a TLS handshake with the
  crash service's host) and whether each installed copy of the skill is this version's.
- Test runners read besides the platforms' own: `flutter test` (widget errors too), Jest (failures and
  `console.error` blocks) and `node --test` (spec and TAP).

[Unreleased]: https://github.com/gitemre/reproduce/commits/main

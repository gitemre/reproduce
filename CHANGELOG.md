# Changelog

All notable changes to `reproduce` are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html): a change to a command, a flag or a file
format that breaks its earlier use comes with a new major version.

## [1.0.1] - 2026-11-01

### Changed

- **Headless device runs are documented and allowed.** Android adds `-no-window`; iOS uses `simctl`
  without `Simulator.app`. The run records `"headless": true` in `device-env.json`; screenshots, video and
  the app log remain the evidence, and the agent stops instead of asking a user to look at the screen.
- The device-path table and schema name the optional `headless` field; the platform pages show how to
  start each device headless and how to open a window when a person needs to watch or act.

## [1.0.0] - 2026-11-01

The first public release of the Markdown-only, mobile Agent Skill.

### Added

- **The six-step skill.** `SKILL.md` is the only entry point: tools/project, fetch/analyze, code,
  reproduce, referee, report. It names one reference per step; the agent reads only that one.
- **No binary and no runner.** The skill is Markdown only; there is no Go command, Python driver,
  Swift runner or bundled test asset. The binary-free installer writes it to a skills folder, and
  `npx skills add gitemre/reproduce` is the network path.
- **A device path with evidence.** The reader writes `attempts/NN/observed.json` from logcat, an
  `.ips`, SentryCrash or the app's queued reports; `manifest.json` records `mode: device`, the
  artifact and the commands; `device-env.json` records the device, locale, variant and isolation.
- **Release-first builds.** The device path builds the reported variant, normally release, and
  falls back to the user's artifact when signing is unavailable. Debug is the exception.
- **A tester-prepared device.** A tester can boot the emulator or simulator and install the crashing
  build; the agent confirms the app id, version, build and isolation, then drives it and records the
  evidence. A tester with no app and no artifact gets a guide-only run and `NO_VERDICT`.
- **Platform pages.** Android uses raw `adb` and `uiautomator`; iOS uses raw `simctl`, and a
  temporary, model-written XCUITest when UI automation is needed. Artifact identity, deep links,
  permissions, crash reports and cleanup are covered.
- **R15: React Native JS carriers and the reporting layer.** `JavaScriptError`,
  `JavascriptException` and `RCTFatalException` are carriers; the JS type is read from the message
  and the bundle position. A carrier matches an observed JS error at the same bundle position (or
  its source-mapped frame) and message; `fatal`/`non_fatal` is the reporting layer, and a one-column
  difference is the 0/1-based encoding.
- **Public smoke check.** `scripts/e2e-clean.sh` extracts a fresh checkout, installs the skill and
  checks the frontmatter, sizes, links, Markdown-only files, private vocabulary, absolute paths and
  TODO markers. CI runs it on every push and pull request.
- **Install and uninstall.** `scripts/install-skill.sh` writes to one agent, a project or any skills
  directory, refreshes an existing copy by default, and `--uninstall` removes it.

### Changed

- **Device evidence reaches the referee through `observed.json`**, not the reproducer's story.
  `manifest.json` has `mode`, `artifact`, `commands` and `raw`; the referee reads only the target,
  the observation and the rulebook.
- **Adding a test file to an existing test target always needs the user's explicit yes**; a new test
  target is not part of the skill.
- **A failed reproduction is left as it is.** The rulebook is conservative: a wrong `REPRODUCED` is
  worse than a miss, and `fatal`/`non_fatal`, a carrier type or a per-run address is not treated as
  an identity by itself.

### Removed

- The Mozilla crash-stats input path and its reader; the skill is mobile-only (Crashlytics, Sentry,
  Apple `.ips`/`.crash`, logcat, stack traces, JVM, Apple, Flutter and JS formats).
- The Go CLI, the binary, the Python device drivers, the Swift XCUITest runner, the old runners and
  the CLI command tables. The private `reproduce-dev` repository keeps the old implementation and
  the full benchmark material.

### Evaluation

- 19 real crash scenarios (Kese 4, Kiler 5, Rota 5, Nabız 5) were run with run folders and
  independent blind-referee verdicts: 19 REPRODUCED. The iOS null-text case uses the Sentry report
  of the same bug because the Crashlytics event carries only the React Native error-handler frame,
  not the JS throw frame; the run and report record that choice.

### Known limits

- The iOS simulator cannot be isolated from production reporting; an app with a reporting SDK needs
  the user's explicit yes.
- A target event that carries only a React Native handler frame, without the JS throw stack, has no
  app place; the matching report from the other service is used instead, and that is recorded.
- Creating a new test target is not part of the skill; apps without one use the device path.

[1.0.1]: https://github.com/gitemre/reproduce/releases/tag/v1.0.1
[1.0.0]: https://github.com/gitemre/reproduce/releases/tag/v1.0.0

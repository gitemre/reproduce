# Changelog

All notable changes to `reproduce` are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [1.2.0] - 2026-11-03

### Added

- **Tester-driven path.** A tester with a physical device and no adb/Xcode gets a one-page brief, installs
  the APK or TestFlight/Ad Hoc build, reproduces and sends the evidence. The run records `driver: tester`
  and `evidence: supplied`.
- **`tester-manual.md` and `tester-evidence.md`.** Install, build check, setup, reproduce, capture,
  send-back, stop and privacy; Android bug report, iOS Analytics Data/TestFlight feedback, and a test
  Crashlytics/Sentry project.
- **Guide v2.** Install, build check, capture, send-back, stop and privacy sections for the tester brief.

### Changed

- `tester.md` branches into agent-driven, tester-driven and guide-only; the physical-device `.app` limit is
  explicit.
- `device-path.md` records `driver: agent` or `tester` and sends a no-tool run to the tester-driven path.

## [1.1.1] - 2026-11-02

### Fixed

- `api-fetch.md` uses the full event `name` for `events:batchGet`; a bare `eventId` returns 400.
- `reported-events.md` describes the reporter-absent shape (`recordError(e, stack)`).
- `code-path.md` names the nearest accessible caller for a private recorder and adds the syntax gate.

### Added

- `fix/approved.md`: exact user quotes for the plan and patch; the reviewer rejects a missing or ambiguous
  approval.
- `fix/checks/`: analyzer, red/green, diff and schema output; `fix/impact.log` for the impact pass.
- `blind/` packs for the referee and the fix reviewer; the check is a file boundary, not a host hook.

### Changed

- Fix verification is portable: commands and files in the Markdown, no Claude Code-specific hooks.

## [1.1.0] - 2026-11-02

### Added

- **Recorded events.** A non-fatal the app reports itself (`recordError`, `captureException`) now has its
  own page, `references/reported-events.md`: how to recognise it, what the observation is, how to capture
  it at the transport boundary, and the new rule **R16** — the message and the reporter's app frame decide,
  because the transport, not the app, assigns the type.
- **`fix-crash` skill.** A separate opt-in skill for a reproduced crash: `REPRODUCED` gate, minimal fix
  plan and impact map, fresh fix reviewer, explicit user approval, red-to-green reproduction test, full
  suite and device check, `FIXED` / `FIX_PARTIAL` / `NOT_FIXED`, and an uncommitted diff.
- **Fix handoff.** `reproduce` step 5 asks once after `REPRODUCED` whether to fix and hands the run folder
  to `fix-crash`; `PARTIAL`, `NOT_REPRODUCED` and `NO_VERDICT` are not fixable.
- **Two-skill packaging.** The installer installs both skills; the smoke check checks both; README,
  architecture and compatibility document the fix flow.

### Changed

- `schemas.md` allows `observations[].kind: "recorded"` with its `reporter`; `reader.md`, `referee.md`,
  `report.md`, `formats/crashlytics.md` and `SKILL.md` name the recorded path.
- R16 uses the message and the reporter's app frame in the tie-break; the recorded-event examples are generic.
- `scripts/install-skill.sh` installs and removes both skills; `--skills-dir PATH` writes `PATH/reproduce`
  and `PATH/fix-crash`.
- `scripts/e2e-clean.sh` checks each skill's `SKILL.md`, description, sizes, links and Markdown-only rule.

## [1.0.0] - 2026-11-02

The first public release of the Markdown-only, mobile Agent Skill.

### Added

- **Six-step workflow.** `SKILL.md` is the only entry point: tools/project, fetch/analyze, code,
  reproduce, referee, report. It names one reference per step; the agent reads only that one.
- **Crash readers.** Crashlytics and Sentry links, Apple `.ips`/`.crash`, logcat, JUnit, JVM,
  Flutter and React Native stacks, and pasted traces.
- **Code path.** One test that calls the real code and lets the exception escape, run with the
  app's own test command.
- **Device path.** Raw `adb`/`uiautomator` and `xcrun simctl`; a model-written XCUITest when iOS
  needs UI automation. Release-first builds, isolation before launch, headless runs, screenshots
  and `replay.mp4`.
- **Blind referee.** A fresh referee compares exception type and place against the target and writes
  `verdict/NN.json`; the reader writes `observed.json`, never the reproducer.
- **Conservative verdicts.** `REPRODUCED`, `PARTIAL`, `NOT_REPRODUCED`; a wrong `REPRODUCED` is worse
  than a miss. `NO_VERDICT` is the orchestrator's when no run happened.
- **Report and guide.** `report.md` records the verdict and evidence; `guide.md` gives a tester a
  manual route. Reproduction tests stay uncommitted unless the developer asks.
- **Safety.** No production code, dependency, build or signing change; no reports to production;
  crash data is data; no secrets; no sandbox bypass.
- **Install and checks.** `scripts/install-skill.sh` writes to one agent, a project or any skills
  directory; `scripts/e2e-clean.sh` checks the install, frontmatter, sizes, links and Markdown-only
  rule.
- **Docs.** Usage, testers, architecture, compatibility and what-it-does pages.

[1.2.0]: https://github.com/gitemre/reproduce/releases/tag/v1.2.0
[1.1.1]: https://github.com/gitemre/reproduce/releases/tag/v1.1.1
[1.1.0]: https://github.com/gitemre/reproduce/releases/tag/v1.1.0
[1.0.0]: https://github.com/gitemre/reproduce/releases/tag/v1.0.0

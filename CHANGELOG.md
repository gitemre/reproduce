# Changelog

All notable changes to `reproduce` are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

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

[1.0.0]: https://github.com/gitemre/reproduce/releases/tag/v1.0.0

# Architecture

`reproduce` is a skill, not a program. The product is `skills/reproduce/`: Markdown the agent reads, and the
platform tools it invokes (`adb`, `emulator`, `xcrun simctl`, `xcodebuild`).

The contract is written where the agent reads it.

## The product

```text
skills/reproduce/
  SKILL.md                  the six steps, the rules, the reference index (under 12 KB)
  references/
    browser-fetch.md        reading a whole event in a browser
    api-fetch.md            the headless API and token fallback
    reader.md               the fresh reader pass
    formats/                jvm, logcat, junit, apple, crashlytics, sentry, flutter, js
    code-path.md            project probe, test locations, test commands
    device-path.md          the model-led device path and its principles
    android-device.md       raw adb: emulator, install, isolation, UI tree, logs, video
    ios-device.md           raw simctl: simulator, install, crash reports, isolation
    ios-ui-automation.md    how to write temporary iOS UI automation yourself
    referee.md              the blind-referee protocol
    rules.md                the verdict rulebook and levels
    schemas.md              every run file and field
    report.md               report and guide layouts
    recovery.md             blocked steps, refused commands, truncated output
    tester.md               the tester's path
```

`SKILL.md` is the only entry point. It names one reference per step; the agent reads only that one. The public
smoke check enforces the size and Markdown-only rules so the skill stays loadable.

## Design

The skill is a written contract: the six steps, the stops, the done criteria, the evidence files and a blind
referee. The model chooses the commands; the contract binds the outcome. The referee sees the target and the
observations, not the analysis or the test, and applies [rules.md](../skills/reproduce/references/rules.md).

What follows for contributors:

- **Automation is temporary.** When automation is needed, the model writes it for the run — a temporary
  XCUITest or a local reader script — and the run records it.
- **Short references.** 12 KB for `SKILL.md` and 10 KB for each reference are attention limits: a long
  document is a document the model skips.
- **The evidence is the record.** `crash.json`, `observed.json`, `raw/`, `manifest.json` and
  `verdict/NN.json` make the run auditable; the report restates the verdict and never re-judges it.

The same run can differ between models and contexts; the mitigation is a sharper contract, the referee and
the conservative rules.

## Device tooling

The model chooses the device sequence. Android uses `adb`/`uiautomator dump`/`input`; iOS uses `xcrun simctl`
for lifecycle. `simctl` cannot tap, so if UI automation is needed the model writes a temporary XCUITest itself
([references/ios-ui-automation.md](../skills/reproduce/references/ios-ui-automation.md)). The agent reads the
screen or the dump, chooses the next command, and records what it actually used.

The skill is Markdown and the platform tools.

## The run folder

One crash gets one run: `.reproduce/runs/<slug>/` at the nearest folder up with `.git` or `.reproduce`
(else the current folder).

| File | Writer | Purpose |
|---|---|---|
| `project.yaml` | probe | app id, modules, test command/source root, `testable` |
| `device-env.json` | device path | platform, OS, device, locale, timezone, app id, artifact, variant, isolation |
| `crash.json` | reader | the target: exception chain, frames, app, environment |
| `analysis.json` | orchestrator | trigger, screens, hypothesis, root cause |
| `raw/source.json`, `raw/` | fetcher | the event(s) as fetched, verbatim |
| `attempts/NN/manifest.json` | reproducer | code/device mode, test or device, raw files, start time |
| `attempts/NN/observed.json` | reader | the observed crash from the test output or the device evidence |
| `verdict/NN.json` | referee | status, level, matched type/place, rules, reasons |
| `report.md`, `guide.md` | orchestrator | the report and the tester guide |
| `progress.md` | orchestrator | one line per step with `done` and the proving file |
| `ui-*.xml`, `dump-*.json` | device | the UI tree the model used |
| `logcat.txt`, `crash.ips`, `replay.mp4` | device | the device evidence |

`references/schemas.md` is the human reference for the JSON/YAML shapes.

## Repository scripts

| Script | What |
|---|---|
| `scripts/install-skill.sh` | copies the skill into an agent's folder, or removes it |
| `scripts/e2e-clean.sh` | extracts a fresh commit, installs the skill, checks its frontmatter, sizes and links and that it stays Markdown-only |

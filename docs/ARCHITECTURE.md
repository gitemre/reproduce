# Architecture

`reproduce` 2.0 is a skill, not a program. The product is `skills/reproduce/`: Markdown the agent reads, and
the platform tools it invokes (`adb`, `emulator`, `xcrun simctl`, `xcodebuild`). There is no Go tree, no
`reproduce` binary, no Python runtime and no bundled UI runner. The last Go implementation is in the private
`reproduce-dev` repository.

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

`SKILL.md` is the only entry point. It names one reference per step; the agent reads only that one. The private
checker enforces the size limits so the skill stays loadable.

## Device tooling

The model chooses the device sequence. Android uses `adb`/`uiautomator dump`/`input`; iOS uses `xcrun simctl`
for lifecycle. `simctl` cannot tap, so if UI automation is needed the model writes a temporary XCUITest itself
([references/ios-ui-automation.md](references/ios-ui-automation.md)); the skill ships no runner. The agent
reads the screen or the dump, chooses the next command, and records what it actually used.

There is no Python driver and no bundled code. The public skill is Markdown and the platform tools.

## The run folder

One crash gets one run: `.reproduce/runs/<slug>/` at the nearest folder up with `.git` or `.reproduce`.

| File | Writer | Purpose |
|---|---|---|
| `project.yaml` | probe | app id, modules, test command/source root, `testable` |
| `crash.json` | reader | the target: exception chain, frames, app, environment |
| `analysis.json` | orchestrator | trigger, screens, hypothesis, root cause |
| `source.json`, `raw/` | fetcher | the event(s) as fetched, verbatim |
| `attempts/NN/manifest.json` | reproducer | test path/command, raw files, start time |
| `attempts/NN/observed.json` | reader | the observed crash from the raw output |
| `verdict/NN.json` | referee | status, level, matched type/place, rules, reasons |
| `report.md`, `guide.md` | orchestrator | the report and the tester guide |
| `progress.md` | orchestrator | one line per step with `done` and the proving file |
| `ui-*.xml`, `dump-*.json` | device | the UI tree the model used |
| `logcat.txt`, `crash.ips`, `replay.mp4` | device | the device evidence |

The private dev repo's `validate.py` checks the JSON/YAML shapes; `references/schemas.md` is the human
reference.

## Benchmark and tests (private)

The frozen 33-case referee benchmark, the schema/static checkers, the scorer and the unit tests are
maintainer material kept outside this public repository. They are not installed, not shipped here, and not
needed to use the skill.

## Repository scripts

| Script | What |
|---|---|
| `scripts/install-skill.sh` | copies the skill into an agent's folder; no Go, no network |
| `scripts/e2e-clean.sh` | extracts a fresh commit, installs the skill and checks it ships no code |

## What is not here

- No `cmd/`, `internal/`, `go.mod`, `go.sum`, `testdata/`, `spike/`, `skill/reproduce-legacy/` or
  `scripts/ips-summary.sh`. They were removed in 2.0; the private `reproduce-dev` repository keeps them.
- No CI service configuration; the public smoke check is local and runs from a clean checkout.
- No benchmark, schema checker or unit-test suite: those are maintained outside this public repository.
- No network call, no telemetry and no device in the default checks.
- No Python runtime, bundled runner or code asset: the device path is raw platform tools plus model-written
temporary automation.

# Architecture

`reproduce` 2.0 is a skill, not a program. The product is `skills/reproduce/`: Markdown the agent reads, and
the platform tools it invokes (`adb`, `emulator`, `xcrun simctl`, `xcodebuild`). There is no Go tree, no
`reproduce` binary, no Python runtime and no bundled UI runner. The last Go implementation is in the private
`reproduce-dev` repository.

The form is deliberate: an agent re-derives or ignores a shipped binary, so the contract is written where
the agent reads it. The [Why Markdown](#why-markdown) section below has the reasoning and the trade.

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
smoke check and the private checker enforce the size and Markdown-only rules so the skill stays loadable.

## Why Markdown

An earlier `reproduce` implementation was a Go binary. A model asked to reproduce a crash usually did one of
two things: when it had the source, it read the Go code and re-derived the logic in its own way; when it did
not, it ignored the binary and used its own commands. Either way the program did not constrain the run. A model does not
adopt a shipped binary as its own plan; it trusts the code it writes and the evidence it can inspect.

The skill is a written contract instead: the six steps, the stops, the done criteria, the evidence files and
a blind referee. The model chooses the commands; the contract binds the outcome. This trades **procedural
determinism** (one program, one path) for **adjudicated determinism** (one evidence standard, one independent
verdict). The referee is the substitute for the binary's judgment: it sees the target and the observations,
not the analysis or the test, and applies [rules.md](../skills/reproduce/references/rules.md).

What follows for contributors:

- **No shipped helper scripts in the skill.** A script shipped with the skill is another opaque box. When
  automation is needed, the model writes it for the run — a temporary XCUITest or a local reader script — and
  the run records it.
- **No private benchmark vocabulary.** Case ids, "seeded", "unmeasured" and benchmark gates make the text
  read as an evaluation harness rather than the task's own plan.
- **Short references.** 12 KB for `SKILL.md` and 10 KB for each reference are attention limits: a long
  document is a document the model skips.
- **The evidence is the record.** `crash.json`, `observed.json`, `raw/`, `manifest.json` and
  `verdict/NN.json` make the run auditable; the report restates the verdict and never re-judges it.

A pure skill is model-dependent: the same run can differ between models and contexts. That is the known price
of not shipping a runner; the mitigation is a sharper contract, the referee, the conservative rules and the
private benchmark.

## Device tooling

The model chooses the device sequence. Android uses `adb`/`uiautomator dump`/`input`; iOS uses `xcrun simctl`
for lifecycle. `simctl` cannot tap, so if UI automation is needed the model writes a temporary XCUITest itself
([references/ios-ui-automation.md](../skills/reproduce/references/ios-ui-automation.md)); the skill ships no
runner. The agent reads the screen or the dump, chooses the next command, and records what it actually used.

There is no Python driver and no bundled code. The public skill is Markdown and the platform tools.

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

The private dev repo's `validate.py` checks the JSON/YAML shapes; `references/schemas.md` is the human
reference.

## Benchmark and tests (private)

The frozen 33-case referee benchmark, the schema/static checkers, the scorer and the unit tests are
maintainer material kept outside this public repository. They are not installed, not shipped here, and not
needed to use the skill.

The GitHub Actions workflow runs the public smoke check (`scripts/e2e-clean.sh`) on every push and pull
request; it does not run the private benchmark.

## Repository scripts

| Script | What |
|---|---|
| `scripts/install-skill.sh` | copies the skill into an agent's folder, or removes it; no Go, no network |
| `scripts/e2e-clean.sh` | extracts a fresh commit, installs the skill, checks its frontmatter, sizes and links and that it stays Markdown-only |

## What is not here

- No `cmd/`, `internal/`, `go.mod`, `go.sum`, `testdata/`, `spike/`, `skill/reproduce-legacy/` or
  `scripts/ips-summary.sh`. They were removed in 2.0; the private `reproduce-dev` repository keeps them.
- No benchmark, schema checker or unit-test suite: those are maintained outside this public repository.
- No network call, no telemetry and no device in the default checks.
- No Python runtime, bundled runner or code asset: the device path is raw platform tools plus model-written
temporary automation.

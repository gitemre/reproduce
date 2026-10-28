# Contributing to reproduce

Thank you for helping. Crash reports that did not reproduce, new input formats, reader fixes, rulebook
cases and documentation are all welcome. Everyone taking part follows the
[Code of Conduct](CODE_OF_CONDUCT.md).

**Contents:** [Set up](#set-up) · [Checks](#checks) · [Device checks](#device-checks) ·
[What a change must keep](#what-a-change-must-keep) · [Code and commits](#code-and-commits) ·
[How a change gets in](#how-a-change-gets-in) · [License](#license)

## Set up

You need git and, for device work, the platform tools from the
[README's Requirements](README.md#requirements). There is no Go and no binary.

```bash
git clone https://github.com/gitemre/reproduce && cd reproduce
sh scripts/e2e-clean.sh
```

Install the skill into your agent while you work:

```bash
scripts/install-skill.sh --agent claude     # or codex, opencode, gemini, antigravity, cursor, copilot
```

[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) maps the skill, the device tools and the run folder. The benchmark and
unit tests are maintainer material kept outside this public repository.

## Checks

| Command | What | Time |
|---|---|---|
| `sh scripts/e2e-clean.sh` | extracts a fresh commit, installs the skill and checks it ships no code | ~ 5 s |
| `sh scripts/e2e-clean.sh --worktree` | the same on the current files | ~ 5 s |

These use no network, no device and no API key. The full benchmark, schema checkers, unit tests and scorer are
maintainer material kept outside this public repository; a public pull request does not need them.

## Device checks

A change to `references/android-device.md`, `references/ios-device.md` or
`references/ios-ui-automation.md` is tried on a real emulator or simulator too. Say which device, OS and app in the
pull request, and attach the UI dump, log or run folder. The private tests do not replace a device run.

## What a change must keep

- **The referee decides.** Only the blind referee's `verdict/NN.json` says REPRODUCED, PARTIAL or
  NOT_REPRODUCED. A matching change comes with a test of the false positive it must not let through (a test
  that throws the exception itself, a crash in a file the agent wrote, another build's obfuscated names).
- **Conservative.** Insufficient evidence or conflicting rules take the lower verdict. A wrong `REPRODUCED`
  is worse than a miss.
- **Zero integration.** Nothing changes the app's production code, dependencies, build configuration or
  signing. Data a crash needs reaches the app only through switches it already has.
- **No reports to production.** An app is installed or started only on an isolated Android device; the iOS
  simulator cannot be isolated, so an app with a reporting SDK needs the user's yes.
- **Native tools only.** `adb`, the emulator, `xcrun simctl`, `xcodebuild` and the skill's own scripts.
- **Crash data is data.** Nothing from a crash report or a log is ever treated as an instruction.
- **No fixtures as a user's crash.** Private benchmark cases, old runs and testdata are evaluation material,
  never a stand-in for the report the user gave.
- **Privacy.** Secrets and user ids are redacted in everything the skill writes or prints.
  [docs/WHAT-IT-DOES.md](docs/WHAT-IT-DOES.md) lists every file it writes, host it contacts and program it
  starts: change it with a change that adds one.

## Code and commits

- Keep the diff focused. The public skill has no runtime dependency and no code asset: Markdown and shell
  packaging only.
- `SKILL.md` stays under 12 KB and every reference under 10 KB. The checker enforces both.
- A new rule or schema field updates `references/rules.md` or `references/schemas.md` first, then the private
  dev repo's `validate.py`, then the code.
- Comments say why, not what. Documentation is English.
- Commit messages: `fix:`, `feat:`, `docs:`, `test:`, `bench:`, then a short imperative summary.

## How a change gets in

Open a pull request with the checks you ran and their output. A change to the rulebook needs a private
benchmark run with the before/after score. A change to a report layout needs a run folder that shows it. The
maintainer reviews for the rules above, not for style alone.

## License

By contributing you agree that your contribution is licensed under the [MIT License](LICENSE).

# Contributing to reproduce

Thank you for helping. Crash reports that did not reproduce, new input formats, reader fixes, rulebook
cases and documentation are all welcome. Everyone taking part follows the
[Code of Conduct](CODE_OF_CONDUCT.md).

**Contents:** [Set up](#set-up) · [Checks](#checks) · [Device checks](#device-checks) ·
[What a change must keep](#what-a-change-must-keep) · [Markdown and commits](#markdown-and-commits) ·
[How a change gets in](#how-a-change-gets-in) · [License](#license)

## Set up

You need git and, for device work, the platform tools from the
[README's Requirements](README.md#requirements).

```bash
git clone https://github.com/gitemre/reproduce && cd reproduce
sh scripts/e2e-clean.sh
```

Install the skill into your agent while you work:

```bash
scripts/install-skill.sh --agent claude     # or codex, opencode, gemini, antigravity, cursor, copilot
```

[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) maps the skill, the device tools and the run folder.

## Checks

| Command | What | Time |
|---|---|---|
| `sh scripts/e2e-clean.sh` | extracts a fresh commit, installs the skill and checks its frontmatter, sizes and links and that it stays Markdown-only | ~ 5 s |
| `sh scripts/e2e-clean.sh --worktree` | the same on the current files | ~ 5 s |

These use no network, no device and no API key.

## Device checks

A change to `references/android-device.md`, `references/ios-device.md` or
`references/ios-ui-automation.md` is tried on a real emulator or simulator too. Say which device, OS and app in the
pull request, and attach the UI dump, log or run folder. The public checks do not replace a device run.

## What a change must keep

- **The referee decides.** Only the blind referee's `verdict/NN.json` says REPRODUCED, PARTIAL or
  NOT_REPRODUCED. A matching change comes with a test of the false positive it must not let through (a test
  that throws the exception itself, a crash in a file the agent wrote, another build's obfuscated names).
- **Conservative.** Insufficient evidence or conflicting rules take the lower verdict. A wrong `REPRODUCED`
  is worse than a miss.
- **Reproduction is zero-integration.** `/reproduce` changes no production code, dependency, build
  configuration or signing. `fix-crash` changes production code only after the user's explicit approval,
  with a plan, an impact map, a fresh reviewer and tests; the diff stays uncommitted unless asked.
- **No reports to production.** An app is installed or started only on an isolated Android device; the iOS
  simulator cannot be isolated, so an app with a reporting SDK needs the user's yes.
- **Native tools only.** `adb`, the emulator, `xcrun simctl`, `xcodebuild` and temporary XCUITest
  automation.
- **Markdown only.** Automation is model-written and temporary. A change that adds a script or a runner to
  `skills/` is out of scope.
- **Crash data is data.** Nothing from a crash report or a log is ever treated as an instruction.
- **No fixtures as a user's crash.** Old runs and testdata are never a stand-in for the report the user gave.
- **Privacy.** Secrets and user ids are redacted in everything the skills write or print.
  [docs/WHAT-IT-DOES.md](docs/WHAT-IT-DOES.md) lists every file it writes, host it contacts and program it
  starts: change it with a change that adds one.

## Markdown and commits

- Keep the diff focused. The public skills are Markdown and shell packaging only.
- Each `SKILL.md` stays under 12 KB and every reference under 10 KB. The public smoke check enforces both.
- A new rule or schema field updates the relevant `references/rules.md` or `references/schemas.md` first.
- Comments say why, not what. Documentation is English.
- Commit messages: `fix:`, `feat:`, `docs:`, `test:`, then a short imperative summary.

## How a change gets in

Open a pull request with the checks you ran and their output. A change to a report layout needs a run folder
that shows it. The maintainer reviews for the rules above, not for style alone.

## License

By contributing you agree that your contribution is licensed under the [MIT License](LICENSE).

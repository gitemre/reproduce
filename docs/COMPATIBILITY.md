# Compatibility

`reproduce` is Markdown plus the host's tools. It does not require a specific agent, model, MCP server,
binary or language runtime. This page lists the install targets, the environment each path needs, and
what is actually verified.

## Install targets

The installer and the Agent Skills CLI write the same `skills/reproduce/` folder to:

| Agent | Folder | Installer flag |
|---|---|---|
| Claude Code | `~/.claude/skills` | `--agent claude` |
| Codex, OpenCode, Gemini CLI, Cursor, GitHub Copilot | `~/.agents/skills` | `--agent codex` (also `opencode`, `gemini`, `cursor`, `copilot`) |
| Antigravity CLI | `~/.gemini/config/skills` | `--agent antigravity` |
| OpenCode (second location) | `~/.config/opencode/skills` | `--agent opencode` |
| A project | `./.claude/skills` and `./.agents/skills` | `--project` |
| Any skills directory | `PATH/reproduce` | `--skills-dir PATH` |

See [`README.md`](../README.md#install) and [`scripts/install-skill.sh`](../scripts/install-skill.sh) for
the exact behavior. The public smoke check installs to a temporary directory, so it does not depend on an
agent being present.

## Requirements

| Path | Needs |
|---|---|
| The skill itself | A file tool and a shell; no runtime, network or device |
| Code path | A shell and the app's own build/test tools (Gradle, Xcode, SwiftPM, Flutter, Jest) |
| Android device path | `adb`, the emulator, `avdmanager`, a system image and a JDK the app accepts |
| iOS device path | macOS, Xcode, `xcrun simctl`; `xcodebuild` for temporary XCUITest automation |
| Fetch | A browser tool preferred; an API token or a pasted trace as the fallback |
| Referee | A fresh subagent preferred; the single-context fallback is documented |

The skill never installs a toolchain. A missing tool is a stop, not an install step.

## What is verified

- **Structure:** [`scripts/e2e-clean.sh`](../scripts/e2e-clean.sh) installs the skill into a clean
  temporary directory and checks the frontmatter, sizes, relative links and Markdown-only rule.
- **Real runs:** the changelog's evaluation entry records 19 real crash scenarios; see
  [`EVALUATION.md`](EVALUATION.md).
- **Device pages:** a change to `android-device.md`, `ios-device.md` or `ios-ui-automation.md` is expected
  to come with a real emulator or simulator run ([CONTRIBUTING.md](../CONTRIBUTING.md)).

## What is not verified here

A model-by-model trigger and workflow matrix is not recorded in this repository. The compatibility claim
is about the install targets and the tools, not about a measured trigger rate on every agent. If you test
one, add a row:

| Agent | Model | Trigger | Code path | Device path | Notes |
|---|---|---|---|---|---|
| | | | | | |

A reproducible failure is more useful than a compatibility claim.

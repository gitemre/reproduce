# Compatibility

`reproduce` is Markdown plus the host's tools. This page lists the install targets and the environment each
path needs.

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
the exact behavior.

## Requirements

| Path | Needs |
|---|---|
| The skill itself | A file tool and a shell |
| Code path | A shell and the app's own build/test tools (Gradle, Xcode, SwiftPM, Flutter, Jest) |
| Android device path | `adb`, the emulator, `avdmanager`, a system image and a JDK the app accepts |
| iOS device path | macOS, Xcode, `xcrun simctl`; `xcodebuild` for temporary XCUITest automation |
| Fetch | A browser tool preferred; an API token or a pasted trace as the fallback |
| Referee | A fresh subagent preferred; the single-context fallback is documented |

The skill never installs a toolchain. A missing tool is a stop, not an install step.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for the public checks and the pull request process.

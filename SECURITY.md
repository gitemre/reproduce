# Security policy

## Supported versions

Security fixes go into `main` and the next release. Only the latest release and `main` are supported; there
are no maintained older branches. A release is a git tag; the release notes name the commit.

## Reporting a vulnerability

Please report it privately, through GitHub's private vulnerability reporting on this repository: the
**Security** tab, then **Report a vulnerability**. Do not open a public issue, pull request or discussion
with the details.

Until private reporting is enabled on the repository, open an issue that only asks for a security contact,
with no details of the problem, and the maintainer will answer with one.

Include the skill step and the command that ran (the agent's prompt, the driver command, the test command),
the release tag or commit, the host OS and the device or simulator. Leave out tokens, signed URLs and users'
personal data, or replace them with placeholders: they are not needed to understand the problem.

## Scope

In scope, in this repository (the skill in `skills/reproduce`, the two device drivers and the XCUITest runner
they build):

- **Reports to production.** An app installed or started by the device path reaches its production crash
  reporting or analytics backends (Crashlytics, Analytics, Sentry, …) although the isolation said it was in
  place, or the skill starts an app without isolating the device when it should have refused.
- **Isolation failures.** The Android network cut does not hold, a check passes on a device that is not
  isolated, or the skill drives a device other than its own or the one it was given. The iOS simulator shares
  the Mac's network; launching a reporting app without the user's explicit yes is in scope.
- **Secrets and personal data in outputs.** A token, a key, a URL signature, a user's id or another user's
  personal data from a crash report that ends up unredacted in the analysis, the report, the guide, a verdict
  or anything else the skill writes or prints.
- **Doing more than it says.** A file written, a host contacted, a download or a program started that
  [docs/WHAT-IT-DOES.md](docs/WHAT-IT-DOES.md) does not list, or crash data from the field (a message, a log
  line) that the skill treats as an instruction.
- **Installer or checker bypass.** `scripts/install-skill.sh` writes outside the requested skills folder, or
  a file the checker should reject ships in `skills/reproduce/`.

Out of scope: bugs in the app being reproduced (that is what the skill is for), in the vendors' tools (`adb`,
the emulator, Xcode, Gradle) and in your coding agent or its sandbox.

## What to expect

This is a small project maintained on a best-effort basis: there is no guaranteed response time. You will
get an answer when the report has been read, and a note when a fix is released. Please give a reasonable
time for a fix before you disclose the problem publicly; you will be credited in the release notes unless you
prefer not to be.

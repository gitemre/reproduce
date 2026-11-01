## What and why

<!-- What this changes, and the case that needed it (an issue, a crash report kind, a device). -->

## How it was tested

<!-- Paste what you ran. A change to a device path also needs the device run for that platform. -->

- [ ] `sh scripts/e2e-clean.sh` (or `--worktree` before the commit)
- [ ] Device path tried on an emulator or a simulator (when the change touches one: which, and the result)

## Checklist

- [ ] The referee decides: no new way to say REPRODUCED outside the blind referee, and a matching change has a test of the false positive it must not let through
- [ ] Conservative: a wrong REPRODUCED is worse than a miss; the lower verdict wins when the evidence is insufficient
- [ ] Zero integration: nothing changes the app's code, dependencies, build or signing
- [ ] No reports to production: isolation is not weakened, and a refusal stays a refusal
- [ ] Android and iOS stay symmetric where the platforms allow (or the PR says why not)
- [ ] No tokens, signed URLs or users' personal data in code, tests, fixtures or this description
- [ ] Docs updated where users or agents see the change (README, `AGENTS.md`, the skill, `docs/`, `CHANGELOG.md`)

<!-- Accepted changes are carried into the development repository with you as author or co-author and come back
here with the next published copy; see CONTRIBUTING.md, "How a change gets in". -->

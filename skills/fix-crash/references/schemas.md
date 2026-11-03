# Fix schemas

The fix run lives under `.reproduce/runs/<slug>/fix/`. The reproduction files are read-only inputs.

```text
fix/
  approved.md    the user's exact yes for the plan and the patch
  plan.md        the root cause, minimal patch, impact map, regression test, rollback
  impact.log     the mechanical impact pass
  diff.patch     git diff of the applied change
  review.json    the fresh reviewer's verdict
  checks/        analyze, red/green, diff and schema output
  after/         test output, JUnit, device video/log/screenshots
  report.md      the fix record: status, diff, tests, impact, residual risk
```

The reviewer's `blind/` pack sits beside `fix/` and contains `plan.md`, `approved.md`, `impact.log`,
`diff.patch`, `checks/`, `after/`, `crash.json`, `observed.json`, `manifest.json`, `verdict/NN.json` and
`review.md`. The reviewer reads only `blind/`.

## Contents

fix/approved.md · fix/plan.md · fix/review.json · fix/checks/ · fix/report.md · Status · diff.patch

## fix/approved.md

```markdown
# Fix approval

- Scope: `plan`
- Approved at: `<RFC 3339 UTC>`
- Quote: "<the user's exact words>"

# Fix approval

- Scope: `patch`
- Approved at: `<RFC 3339 UTC>`
- Quote: "<the user's exact words>"
```

| Field | Type | Notes |
|---|---|---|
| `Scope` | string | `plan` or `patch`; one entry per scope |
| `Approved at` | string | RFC 3339 UTC |
| `Quote` | string | the user's exact words, not a summary |

A missing, summarized or ambiguous quote is not an approval; the reviewer rejects the fix.

## fix/plan.md

```markdown
# Fix plan: <crash>

Run: `<run folder>` · Verdict: `REPRODUCED (blame-frame)` · File: `verdict/NN.json`

## Root cause

<The blame frame, the bad value and the condition, one paragraph.>

## Minimal patch

- `<file>` — <the smallest change>
- `<file>` — <the test>

## Impact map

| Caller / use | Old behavior | New behavior | Risk | Test |
|---|---|---|---|---|
| `<caller>` | `<old>` | `<new>` | `<risk>` | `<test>` |

## Regression test

<The input, the assertion and the command. The test must fail before the patch and pass after.>

## Rollback

`<the revert command and the files to restore>`
```

## fix/review.json

| Field | Type | Notes |
|---|---|---|
| `schema` | string | exactly `reproduce/fix-review@1` |
| `status` | string | `APPROVED`, `CHANGES_REQUESTED` or `REJECTED` |
| `independence` | string | `subagent` or `single-context` |
| `root_cause` | string | the symbol and file the patch changes |
| `impact` | array | each item has `caller`, `risk` and `test` strings |
| `tests.red_green` | boolean | true only when the same input failed before and passes after |
| `tests.suite` | string | `pass`, `fail` or `not-run` |
| `approval` | string | `fix/approved.md`; the reviewer checks the quote |
| `checks` | array | paths under `fix/checks/` the reviewer read |
| `diff` | string | `fix/diff.patch` |
| `reasons` | array | non-empty; one line per deciding fact |
| `risks` | array | what remains untested or uncertain |

A `REJECTED` review may omit `impact` and `tests`; its reasons say why. A `CHANGES_REQUESTED` review
names the defect and what would make it approvable.

## fix/checks/

```text
fix/checks/
  analyze.log    the analyzer or compiler output
  red.xml        the reproduction test before the patch
  green.xml      the same test after
  after.log      the same input/device sequence after the patch
  diff.log       the cmp of fix/diff.patch and the working tree
  schema.log     the jq or manual schema check
```

The files are evidence, not a substitute for the reviewer. A missing or failing check is a change
request, not an approval.

## fix/report.md

```markdown
# Fix report: <crash>

Run `<run folder>` · Reproduction verdict `REPRODUCED (blame-frame)` · Fix status `FIXED`

## What changed

- `<file>` — <the change>
- `<test>` — <the regression test>

## Impact

<The callers checked, the contracts unchanged, the untested paths and the residual risk.>

## Verification

- Analyzer: `<command>` — pass
- Reproduction test: `<command>` — fail before, pass after
- Target signature: absent in `fix/checks/after.log`
- Full suite: `<command>` — pass
- Device: `<build, device, UI sequence, video/log>` or `not applicable`

## Approval

`fix/approved.md` — plan and patch quotes.

## Checks

- Red/green: `fix/checks/red.xml`, `fix/checks/green.xml`
- Diff: `fix/checks/diff.log`
- Schema: `fix/checks/schema.log`

## Review

`fix/review.json` — `<reviewer status>`, independence `<subagent|single-context>`, `<file>`.

## Rollback

`<the revert command>`

## Limits

- <What was not tested.>
- <What remains risky.>
```

## Status

- `FIXED`: reviewer `APPROVED`, red-to-green reproduction test, target signature absent, full suite pass.
- `FIX_PARTIAL`: the fix was verified, but the impact map, the full suite or an automated regression
  test is incomplete.
- `NOT_FIXED`: the suite failed, the reviewer rejected, or the root cause was not reached.

## diff.patch

Write the applied change with `git diff --no-ext-diff > fix/diff.patch`. Do not include unrelated
working-tree changes; if the app already had changes, say which files are the fix. The patch is the
rollback record, not a commit.

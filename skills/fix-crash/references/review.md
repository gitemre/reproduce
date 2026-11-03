# Fix review

The reviewer answers one question for one fix: is this the smallest safe change that fixes the
reproduced crash without breaking another caller?

## Independence

Use a fresh subagent that has not seen the implementer's notes or chat. The orchestrator creates `blind/`
with copies of the files below and this protocol; the reviewer reads only `blind/`:

- `blind/plan.md`;
- `blind/approved.md` and `blind/impact.log`;
- `blind/diff.patch`;
- `blind/checks/` and `blind/after/` (test output, JUnit, device video/log);
- `blind/crash.json`, `blind/observed.json`, `blind/manifest.json`, `blind/verdict/NN.json`;
- the code the patch touches, only to verify call sites.

Do not give it the implementer's reasoning, `analysis.json`, the test source or the chat. The plan is the
claim; the diff and the tests are the evidence. If only the current context can review, start a new step,
read only those files, write `independence: single-context`, and label the result `FIXED (single-context)`
or `FIX_PARTIAL`; say it was not independently reviewed.

## Checklist

- **Approval.** Does `blind/approved.md` quote a clear user yes for `plan` and a second for `patch`? A
  missing, summarized or ambiguous quote is `REJECTED`, not an approval.
- **Root cause.** Does the patch change the blame frame and the bad value, not the place where the
  exception surfaced?
- **Minimality.** Is every changed line needed? Any drive-by refactor, rename, formatting or unrelated
  file is a change request.
- **Impact.** Does the plan list every caller? Are the contracts, shared state, platform variants and
  untested callers covered? A missing caller is a change request.
- **Syntax gate.** Does `blind/checks/analyze.log` pass on the touched files?
- **Tests.** Does the reproduction test fail on the old code and pass on the new code? Is it asserting
  the intended behavior, not the old crash? Was any assertion weakened, caught broadly or deleted?
- **Red/green.** Do `blind/checks/red.xml` and `blind/checks/green.xml` name the same test, with a
  failure in red and none in green? Logs are accepted only when the runner cannot emit JUnit.
- **Diff.** Does `blind/checks/diff.log` show `cmp` success between `blind/diff.patch` and the working
  tree?
- **Schema.** Does `blind/checks/schema.log` show the required fields for `verdict/NN.json` and
  `fix/review.json`, with `jq` or a recorded manual check?
- **Suite.** Does the app's full test suite pass? If it could not run, the status cannot be `FIXED`.
- **Provenance.** Was the reproduction `supplied` by a tester (`driver: tester`)? Then the fix verification
  must be agent-run, or a clear tester rerun on the fix build; a tester-only verification cannot be
  `FIXED`.
- **Future.** If the fix introduces an invariant, is it protected by a test, a type or a comment? Does
  it change a public contract without a decision?
- **Rollback.** Is the revert path recorded and does it restore the touched files?
- **Scope.** No dependency, build, signing or test-target change unless the user asked.

## Verdict file

Write `fix/review.json` ([schemas.md](schemas.md#fixreviewjson)):

```json
{
  "schema": "reproduce/fix-review@1",
  "status": "APPROVED",
  "independence": "subagent",
  "root_cause": "PriceParser.parse at PriceParser.kt:18",
  "impact": [
    {"caller": "CartViewModel.load", "risk": "none for valid input", "test": "CartTest"}
  ],
  "tests": {"red_green": true, "suite": "pass"},
  "approval": "fix/approved.md",
  "checks": ["fix/checks/analyze.log", "fix/checks/red.xml", "fix/checks/green.xml", "fix/checks/diff.log", "fix/checks/schema.log"],
  "diff": "fix/diff.patch",
  "reasons": ["the patch changes the parser at the blame frame", "the regression test fails before and passes after"],
  "risks": ["no test covers Checkout.submit"]
}
```

- `status`: `APPROVED`, `CHANGES_REQUESTED` or `REJECTED`.
- `independence`: `subagent` or `single-context`.
- `root_cause`: the symbol and file the patch changes.
- `impact`: one entry per caller or risk; empty is allowed only for a one-line fix with no caller.
- `tests`: `red_green` is true only when the same input failed before and passes after; `suite` is
  `pass`, `fail` or `not-run`.
- `approval`: `fix/approved.md`; the reviewer read the quote.
- `checks`: the files under `fix/checks/` the reviewer read.
- `reasons`: one non-empty line per deciding fact.
- `risks`: what remains untested or uncertain; empty only when the impact map is exhaustive.

`APPROVED` requires an exact plan and patch approval, the root cause at the blame frame, a minimal diff,
a complete impact map, a passing syntax gate, a red-to-green test, a matching diff, a schema check, a
passing suite and no test weakening. `CHANGES_REQUESTED` names the defect and what would make it
approvable. `REJECTED` means the wrong root cause, a missing or ambiguous approval, a dependency or
product decision, or a test that cannot be made honest.

## Malformed reviews

A review is malformed when the file is not one JSON object, `status` is missing or unknown,
`independence` is missing, `reasons` is empty, or `APPROVED` has no root cause, no test result, no
approval, no checks or a `red_green` that is not true. Ask the same reviewer once for a redo, naming the
defect. If it is still malformed, the fix cannot be `FIXED`; report `FIX_PARTIAL` or `NOT_FIXED` with the
reason.

## No self-approval

The implementer may not write, edit or "fix" the review. The reviewer may read the code and the plan,
never edit the patch or the tests. If the reviewer asks for a change, the implementer revises once and
the reviewer reviews again; the orchestrator cannot overrule a `REJECTED` or upgrade a
`CHANGES_REQUESTED`.

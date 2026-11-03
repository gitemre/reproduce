# Fix playbook

## Contents

- Impact map
- Approval record
- Patch rules
- Syntax gate
- Mechanical checks
- From reproduction to regression test
- Device path
- Dynamic languages
- Stop conditions

## Impact map

The fix is only as safe as the map of what it touches. Before the patch, list every caller of the
changed symbol and decide whether the new behavior is safe for it.

| Caller / use | Old behavior | New behavior | Risk | Test |
|---|---|---|---|---|
| `CartViewModel.load` | throws on `"1,2"` | returns `1.2` | none for valid input | `CartTest` |
| `Checkout.submit` | catches the throw | no throw | error path changes | add a boundary test |

Cover:

- **Direct and indirect callers.** Use the IDE's references, the compiler or type checker, and
  `git grep` for the symbol. An override or interface implementation is a caller too.
- **Contracts.** Return type, exception type, nullability, serialization, API and UI state. A changed
  contract is a product decision, not a mechanical fix.
- **Shared state.** Caches, singletons, lifecycle, mutable objects and concurrency. A value that was
  invalid for one path may be valid for another.
- **Platform variants.** Android/iOS/Flutter/React Native; a shared function can be reached from each.
- **Tests.** Which existing tests cover the changed code? Which callers have no test? Record the gap.
- **Future code.** Does the fix introduce an invariant? A test, a type or a short comment must make it
  hard to break. If the fix changes a public contract, say so in the report.

If a caller is unknown, do not patch; investigate or ask. A fix that only makes the reproduction test
pass is not a fix.

The map is a claim; back it with commands. Write `fix/impact.log`:

```bash
git diff --unified=0 > fix/impact.diff
git grep -n "<changed symbol>" >> fix/impact.log
```

Run the grep for each changed symbol and name every caller it prints in the plan. A caller in the log
that the plan omits is a stop; the reviewer makes the same check.

## Approval record

Write `fix/approved.md` after each explicit yes. It is not a summary and not a "probably":

```markdown
# Fix approval

- Scope: `plan`
- Approved at: `<RFC 3339 UTC>`
- Quote: "<the user's exact words>"
```

Add a second entry with `Scope: patch` before the patch. A missing or ambiguous record is a rejected fix,
not an approval.

## Patch rules

- Patch the root cause at the blame frame, not the place where the exception surfaced.
- Keep the diff minimal. No drive-by refactor, formatting-only change or rename.
- No dependency, build, signing or test-target change unless the user explicitly asks.
- Preserve the app's style; run its formatter and linter on the touched files only.
- Do not add a feature flag unless the app already has one.
- If the correct behavior is ambiguous (throw vs return empty, clamp vs reject), stop and ask. The
  skill cannot invent product semantics.
- If the bug is in a third-party dependency, do not patch the dependency; report the upgrade or
  workaround as a decision.

## Syntax gate

Before the test command, run the app's analyzer or compiler on the touched files and save the output to
`fix/checks/analyze.log`:

- Dart/Flutter: `dart analyze` or `flutter analyze`.
- Gradle: the app's compile task for the test source set.
- Xcode/SwiftPM: `xcodebuild build-for-testing` or `swift build`.
- TypeScript/React Native: `npx tsc --noEmit` or the app's lint/typecheck script.

A syntax error is not a test failure; fix it and rerun the analyzer. Do not start the test command while
the analyzer fails.

## Mechanical checks

Write the output to `fix/checks/`. The reviewer rejects a missing or failing check.

- **Red before green.** Keep `fix/checks/red.xml` and `fix/checks/green.xml` (or the runner's logs). The
  same test name must fail in red and pass in green; a JUnit `<failure>` in red and none in green is the
  clean form.
- **Target signature.** After the patch, run the same input or device sequence and save
  `fix/checks/after.log`. Grep it for the target exception type and blame frame; they must be absent. A
  passing test that still logs them is not a fix.
- **Diff equality.** `git diff --no-ext-diff > /tmp/fix.diff` and `cmp -s fix/diff.patch /tmp/fix.diff`;
  the patch must match the working tree.
- **Schema.** Check `verdict/NN.json` and `fix/review.json` against `schemas.md` with `jq -e` when it is
  installed; otherwise record `manual` and the fields checked. A `FIXED` report cannot claim a schema pass
  it did not run.
- **Impact.** `fix/impact.log` from the impact pass; every caller it shows is in the plan.

## From reproduction to regression test

The reproduction test is written to let the exception escape. After the fix it must assert the
intended behavior. Keep the same input and add the assertion.

Kotlin/JUnit:

```kotlin
// before: proves the crash
@Test fun parsesTheReportedInput() {
    PriceParser.parse("1,2")
}

// after: proves the fix
@Test fun parsesTheReportedInput() {
    assertEquals(1.2, PriceParser.parse("1,2"))
}
```

XCTest:

```swift
func testParsesTheReportedInput() throws {
    XCTAssertEqual(try PriceParser.parse("1,2"), 1.2)
}
```

Flutter:

```dart
test('parses the reported input', () {
  expect(PriceParser.parse('1,2'), 1.2);
});
```

Jest:

```js
test('parses the reported input', () => {
  expect(PriceParser.parse('1,2')).toBe(1.2);
});
```

If the intended behavior is a domain error, assert that specific error, not a broad catch. The test is
the contract: do not weaken it, catch the exception generically, or delete it to make the suite green.

## Device path

For a device-only crash there may be no unit test. Rebuild the reported variant, install it on the
same device or simulator, and run the same UI sequence. Capture the video, log and screenshots in
`fix/after/`. Without an automated regression test the status is `FIX_PARTIAL`: the fix was verified
on the device, but future code is not protected by a test.

## Dynamic languages

Dart, JavaScript and TypeScript make static call-site analysis weaker. Combine:

- the type checker or analyzer;
- `git grep` for the symbol and its imports;
- the existing tests for the module;
- a runtime path that exercises each known caller.

If a dynamic call site cannot be resolved, list it as an untested risk instead of guessing.

## Stop conditions

Stop and report, without patching, when:

- the verdict is not `REPRODUCED`;
- the root cause is not at the blame frame;
- the fix needs a product decision;
- the bug is in a dependency;
- the reproduction is flaky or not deterministic;
- the full suite cannot run and the change is not device-verifiable;
- the only way to make the test pass is to weaken it.

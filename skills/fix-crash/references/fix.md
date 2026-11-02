# Fix playbook

## Contents

- Impact map
- Patch rules
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

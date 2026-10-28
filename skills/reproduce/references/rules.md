# Verdict rulebook

Apply these rules to the evidence, not the attempt's story. Each rule names one example and its cases; the
tie-break decides conflicts. The levels are `blame-frame`, `call-path`, `system-frames`,
`recursion` and `type-and-message` (R14 defines them); `PARTIAL` and `NOT_REPRODUCED` have no level. Test
frames (`src/test`, `Tests`, `test`, `__tests__`) are not app frames even when marked `in_app` (R1); the
blame frame is the innermost app frame of the root exception.

## Rules

### R1 — Test code is not the app

A test-source frame is not an app frame, even when marked `in_app`. It does not count toward a call path
and cannot establish the location. If the exception appears only in the test, the test threw it instead of
the app: the place does not match, so the verdict is at most `PARTIAL` (type only). When a real app frame
matches too, count it and ignore the test frame.

Example: C32's `PriceParserCrashTest.fakes it` is test code → `PARTIAL`; C08, C11 and C30 count only
`PriceParser.parse` → `blame-frame`.

Cases: C08, C11, C30, C32.

### R2 — The reported crash itself is not a reproduction

Ignore an observation that is the target's own crash: same `event_id`, `source_path`, or logcat
entry/time. It proves the report exists, not that the test reproduced it. If only self-observations
remain, the verdict is `NOT_REPRODUCED` with that reason; if another observation is new, decide on it and
say the self-observation was ignored.

Example: C16's logcat entry and C26's `.ips` are the report itself → `NOT_REPRODUCED`; C28 and C33 add a
new observation.

Cases: C16, C26, C28, C33.

### R3 — Line drift is not a new place

Use the blame frame. Same symbol and file at a different line is the same place at function level
(`location: function`): the code moved or the build differs. Same file and line with an empty symbol is
also the same place (`location: file-line`). A different symbol or file is a different place. R3 repairs
one blame frame; it never repairs a repeated recursion cycle (R13).

Example: C11's `PriceParser.parse` moves 18 → 21 → `REPRODUCED`, `blame-frame`; C18's frame is only
`CartViewModel.swift:42` → the same place.

Cases: C11, C18.

### R4 — A generic wrapper is not evidence by itself

A generic wrapper (`java.lang.RuntimeException`, `Exception`, `Error`, `Throwable`) is not evidence by
itself: build tools, test runners and plugins throw it too. A generic type match with no matching place is
not a reproduction. Build tooling with no app frame → `NOT_REPRODUCED`; the same wrapper in app code
elsewhere → at most `PARTIAL`. `REPRODUCED` still needs type and place.

Example: C14's Gradle-wrapper `RuntimeException` has no app frame → `NOT_REPRODUCED`; C15's comes from
`HomeActivity.onCreate` → `PARTIAL`.

Cases: C14, C15.

### R5 — A stack overflow is placed by its repeated cycle

A stack overflow is placed by the frame(s) its recursion repeats, not by depth, entry point, or where it
struck. Find the shortest repeating cycle on each side; it is the same crash when both repeat the same
frame at the same place (`level: recursion`). A different repeated frame is a different crash (R13 covers
its line). Repeated framework frames from a touch dispatch (`ViewGroup.dispatchTouchEvent`) are not a
recursion.

Example: C04 and C24 repeat the same cycle → `REPRODUCED`, `recursion`; C23's cycle moves 407 → 455 →
`PARTIAL`; C31's touch-dispatch repeat is not recursion → `PARTIAL`.

Cases: C04, C23, C24, C31.

### R6 — FlutterError is a Dart wrapper

`FlutterError` is Flutter's wrapper for every Dart error. It matches an observed Dart error of any Dart
type at the same place (`AssertionError`, `StateError`, a custom Dart exception); the observed type need
not be named `FlutterError`. It does not match a non-Dart exception (`java.lang.IllegalStateException`,
Kotlin, Swift) even at the same frame: type mismatch, at most `PARTIAL`.

Example: C27's `AssertionError` at `cart_screen.dart:99` → `REPRODUCED`; C03's `IllegalStateException`
there → `PARTIAL`.

Cases: C03, C27.

### R7 — JavaScript errors are placed by bundle position

JavaScript errors are placed by bundle position, not function name. `anonymous` functions are identified
by `raw` (`anonymous@1:604210`); the same position is the same place. A React Native
`JavascriptException`/`JavaScriptError` wrapper is typeless: it takes the recorded JS error's type, so a
different wrapper class is not a type mismatch. At the same position the messages must match; same
position, another message is at most `PARTIAL`.

Example: C02 same position and message → `REPRODUCED`; C05 another position → `PARTIAL`; C25 same
position, another message → `PARTIAL`.

Cases: C02, C05, C25.

### R8 — Swift.FatalError is the Swift runtime trap

`Swift.FatalError` is the Swift runtime trap, recorded as `EXC_BREAKPOINT/SIGTRAP` or
`EXC_CRASH/SIGABRT`; they map to each other and are a type match when the frame matches.
`EXC_BAD_ACCESS/SIGSEGV` is a memory fault, not the Swift trap: one against the other is a type mismatch (at
most `PARTIAL` even at the same frame). Do not compare Mach or signal text as a message (R10).

Example: C01, C10 and C12 → `REPRODUCED`; C13 and C06 → `PARTIAL`.

Cases: C01, C06, C10, C12, C13.

### R9 — A recorded NSError matches by domain and code or by message

A recorded `NSError` (`Non-fatal: Error`) matches by domain and code or by message. Read them from
`custom_keys.error_domain` or the message (`Error Domain=NSCocoaErrorDomain Code=260`); the same domain and
code is a type match even when the observed type is a custom name (`ReceiptError`). Another code or domain
is a different error; with no domain key, the full message must match. A different type at the same frames
→ `PARTIAL`.

Example: C07 (Code 260) and C20 (same message) → `REPRODUCED`; C17 (Code 4) and C19 → `PARTIAL`.

Cases: C07, C17, C19, C20.

### R10 — Mach exception text is not a message

Mach exception text is not a message: `Exception 6, Code 1, Subcode 8`, `EXC_BAD_ACCESS (SIGSEGV)`,
`KERN_INVALID_ADDRESS`, `ABORT at 0x...`, `SIGABRT` and similar OS text describe the trap, not the app's
error. Never make a message mismatch or match from it. Compare app messages only when both sides have one;
a missing observed message is not a mismatch.

Example: C10's `ABORT at 0x...` vs a Swift message: R8 and the frame decide → `REPRODUCED`; C06's
type mismatch is R8 (`EXC_BAD_ACCESS` vs `Swift.FatalError`); its `KERN_INVALID_ADDRESS` is Mach text.

Cases: C06, C10.

### R11 — Obfuscated names are build-scoped

Obfuscated names (`$r8$lambda$...`, ProGuard short names) mean something only inside one build. A name
match counts only when the observation is from the target's build (same version code/build id). For another
build, compare the non-obfuscated frames; a differing obfuscated frame is not by itself a different place,
and the stable frames decide the level. Never use an obfuscated name to promote a verdict beyond them.

Example: C33's new-pid crash differs only in the `$r8$lambda$...` name; four stable app frames match →
`REPRODUCED`, `call-path`; the same-event entry is ignored by R2.

Cases: C33.

### R12 — With no stack on either side, type and message decide

When neither the target nor the surviving observation has frames (`frames` empty or null), the location is
`none`; the verdict is `REPRODUCED` at `type-and-message` only when the type and messages match (after
R10). A type match with a different message, or a type mismatch, is `NOT_REPRODUCED`. Never invent a
location from a title or a test name.

Example: a stackless `IllegalStateException: no item` against the same type and message → `REPRODUCED`,
`type-and-message`; another message → `NOT_REPRODUCED`.

Cases: none in the seeded 33; **unmeasured** — add the first real stackless pair.

### R13 — Line drift applies to the blame frame, not the repeated cycle

R3 may move one blame frame along the same function, but a stack overflow is placed by its cycle: if the
repeated frame's line differs, it is a different recursion even when symbol and file are the same. Compare
the cycle's symbol, file and line; a differing line is a location mismatch, so the verdict is at most
`PARTIAL` (type matches, place does not). This outranks R3 and R5.

Example: C23's `Indexer.walk` moves 407 → 455 → `PARTIAL`; C24 keeps 407 → `REPRODUCED`, `recursion`;
C11's blame frame drifts by 3 → `REPRODUCED` (R3).

Cases: C11, C23, C24.

### R14 — Level taxonomy

`call-path` when at least two app frames (test frames excluded, R1) match in order; `blame-frame` when
only the blame frame matches. `recursion` when R5 places a stack overflow by its cycle. `system-frames`
when the innermost frame is a framework/system frame that matches and neither side has an app frame
(**unmeasured**: no seeded case). `type-and-message` only for R12. `PARTIAL` and `NOT_REPRODUCED` have no
level.

Example: C07 and C20 have two app frames → `call-path`; C28, C29 and C33 have three or more → `call-path`;
C08, C11 and C30 ignore the test frame and count one → `blame-frame`.

Contested level cases: C07, C08, C11, C20, C28, C29, C30, C33.

Cases C09, C21 and C22 need no special rule: a base type/place decision lists `[]`.

## Tie-break

1. Drop the reported crash itself (R2). Match the type (R4, R6–R10) and the place (R1, R3, R5, R13).
2. Choose the best observation: most matching app frames, then exact over drifted, then message match; one
   match is enough.
3. Set the level (R14). If rules conflict, the lower verdict wins: `NOT_REPRODUCED` < `PARTIAL` <
   `REPRODUCED`. A wrong `REPRODUCED` is worse than a miss.
4. `REPRODUCED` needs type and place; `PARTIAL` needs exactly one; `NOT_REPRODUCED` has neither.
5. Caps: a generic build-tool wrapper with no matching place is `NOT_REPRODUCED` (R4); a test-only place is
   at most `PARTIAL` (R1); a self-observation is not evidence (R2). The best observation decides (C30); a
   self one is ignored (C28); only unrelated ones is `NOT_REPRODUCED` (C21).

When ambiguous, choose the lower verdict. A new fact becomes a rule here, never a one-off answer.

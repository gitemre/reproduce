# Flutter and Dart

A Flutter test run, a Flutter framework error and a Dart VM log all print the
same Dart error chain. The runner's progress lines are not part of it.

## Inputs

`flutter test` / `dart test` output has one block per failed test. The terse
reporter prints the error under the test's `[E]` line:

```text
00:00 +0 -1: a price with a decimal comma [E]
  FormatException: Invalid double
  12,5
  dart:core                                         double.parse
  package:shop_flutter/cart/price_parser.dart 7:19  PriceParser.parse
  test/price_parser_crash_repro_test.dart 10:11     main.<fn>
```

A widget test often prints the error above the test's failure line, inside
frame rules; the test line then says only `Test failed. See exception logs
above.`:

```text
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════
The following FormatException was thrown building CartScreen(dirty, state: …):
Invalid double
12,5

The relevant error-causing widget was:
  CartScreen

When the exception was thrown, this was the stack:
#0      double.parse (dart:core-patch/double_patch.dart:111:7)
#1      PriceParser.parse (package:shop_flutter/cart/price_parser.dart:7:19)
```

A Dart VM log prints `Unhandled Exception: <Dart error>` followed by `#N`
frames, often with a `build_id: '…'` line. A caught framework error can also
be a build, layout or paint assertion (`The following assertion was thrown
during layout:`) or an error thrown in the test body (`… was thrown running
a test:`).

One file may hold several failed tests and several caught blocks. Each error
is one crash candidate; do not merge them. A caught block belongs to the
failed test above it, and the first error that broke that test is the one
that explains it.

## What to extract

1. Find the failed test's `[E]` line (or the `EXCEPTION CAUGHT BY` header).
   Ignore `loading …`, passing progress lines, `Some tests failed.` and the
   closing `Failing tests:` list.
2. Read the error text from its first line to the first frame or blank line.
   Split the first line at the first `: ` after the type: the type is before
   it, the rest is the message. Continuation lines that are indented and are
   not frames continue the message, joined with `\n` (the fixture's
   `Invalid double` + `12,5`). Drop a leading `Unhandled Exception: `.
3. Read the Dart chain. A `ClientException with SocketException: Failed host
   lookup` is two exceptions: the outer `ClientException`, then the inner
   `SocketException`, both with the text after the inner type's colon as
   message. Keep the chain outermost first.
4. Read frames in printed order, innermost first. Terse frames are
   `<uri> <line>:<column>  <symbol>`; full frames are
   `#N <symbol> (<uri>:<line>:<column>)` or `#N <symbol> (<uri>)`. Keep the
   line, drop the column, and keep the URI as the file. A bare `dart:core` is
   a file with line `0`. Skip `<asynchronous suspension>`, `(elided … frames
   …)` and `...` lines.
5. A failed expectation is not a crash: skip `TestFailure`, `Expected: …
   Actual: …`, snapshot mismatches and the runner's own
   `TimeoutException … Test timed out after …`. A `The following
   FormatException was thrown …` block is a crash even when the test's own
   line only says "Test failed. See exception logs above."

Some Dart values print no type. Map only these known forms, and keep the
printed text as the message:

| printed text starts with | type |
|---|---|
| `Bad state: ` | `StateError` |
| `Null check operator used on a null value` | `TypeError` |
| `type '…' is not a subtype of type '…'` | `TypeError` |
| `RangeError (` | `RangeError` |
| `LateInitializationError: ` | `LateError` |
| `Failed assertion` | `AssertionError` |
| `Instance of 'CartFailure'` | `CartFailure` |

`LateInitializationError` is the text `LateError` prints; the class is
`LateError`. `_TypeError` is `TypeError`'s private implementation class: keep
the printed name, do not rename it. A leading `_` is part of a library-private
class (`_CartScreenState`), and a private field's `@<digits>` suffix
(`Field '_poller@4410' has not been initialized`) is a library id that changes
between builds: keep the message as printed rather than inventing a public
name.

## Fields

- `platform`: `unknown`. A test run says nothing about Android or iOS.
- `kind`: `fatal`. A test output's `fatal` means the run ended with an
  uncaught error; it does not say the app's process crashed. The report calls
  the observation a test result.
- `app.id`: empty unless the input names an application id. A `package:`
  URI names a Dart package, not the bundle identifier; the app's pubspec name
  may identify its frames but is not the id.
- `exceptions[].signal`: empty; a Dart error is not a POSIX signal.
- `session_data`: `missing`; `breadcrumbs`, `logs` and `custom_keys` stay
  empty unless the file really carries them. The test name is evidence, not a
  breadcrumb; `context` stays empty unless the file names a device.
- `tags.test`: the test description from the progress line. A widget error
  may also keep `caught_by` (`widgets library`, `flutter test framework`) and
  `thrown` (`building CartScreen(dirty, …)`).

## in_app and `package:` frames

The file of a `package:` frame is `package:<package>/<path>.dart`; the symbol
is `Class.method`. Mark it `in_app` when its package is the app's own Dart
package (the pubspec name, often the app id's last segment). Without the
package name, every package except `package:flutter`, `package:flutter_test`,
`package:test_api`, `package:matcher` and `package:stack_trace` is app code.
`dart:` frames are the SDK and are not app code. A `file:///…_test.dart` or
`test/…_test.dart` frame is test code: it explains how the error was reached,
but it is not the production location and is not `in_app`.

## Blame frame

`exception.blame_frame` is the first `in_app` frame of the **last** exception
(the root cause), then an outer exception's first `in_app` frame, then the
crash's first frame. In the fixture it is `PriceParser.parse` in
`package:shop_flutter/cart/price_parser.dart`, line `7`, not `double.parse`
(SDK) and not the test's `main.<fn>`. If every frame is a test or framework
frame, the failure never entered app code: leave the blame at the first frame
the report has and say so in `analysis.json`.

## FlutterError wrappers

Crashlytics' Flutter plugin reports every Dart error as
`io.flutter.plugins.firebase.crashlytics.FlutterError`; the iOS SDK may write
a bare `FlutterError` or `FlutterError - StateError: Bad state: …`. The
message is the Dart error's text. Keep the wrapper as the outermost
exception, append the Dart chain after it, and move the wrapper's Dart stack
to the innermost exception when the inner one has no frames. The root cause
(the last exception) is the Dart error, so that is the type and the blame
frame; the wrapper is not the crash type when the Dart type is known. A
framework assertion with no Dart class is `FlutterError`, message its
`The following … was thrown …` text.

## AOT offsets

A release build without symbols prints frames like:

```text
#00 abs 000000708bd5c497 virt 0000000000139497 _kDartIsolateSnapshotInstructions+0x22a17
build_id: 'b7188509402ec2511ab80642300cfe6a'
```

Keep the symbol exactly, with an empty file and line `0`, and mark it
`in_app: false`: it places nothing until it is symbolized with the build's
split-debug-info symbols (`flutter symbolize`). It is never the blame frame
before symbolication. Keep the `build_id` in `context` when the report has
one; a VM header such as `os: android arch: arm64` is device context too.

## Worked examples

`flutter_test_failure.txt` is a terse `flutter test` run of a shop app:
type `FormatException`, message `Invalid double\n12,5`, three frames
(`double.parse`, `PriceParser.parse`, `CartViewModel.total`) and the test's
`main.<fn>`. Result: `platform: unknown`, `kind: fatal`, empty `app.id`,
`session_data: missing`. `PriceParser.parse` is the blame frame:
`package:shop_flutter/cart/price_parser.dart`, line `7`.

`flutter_widget_test_failure.txt` is a widget test whose build caught a
`FormatException`; the test's own failure line only says "Test failed. See
exception logs above." The first caught error is the build's `FormatException`
with the same message and the same blame frame. The later blocks are another
thrown `FormatException` in the test body and an error the test threw itself;
the failed expectation is not a crash. The first caught error is the target.

## Failure modes

- The compact reporter rewrites a progress line with `\r`; a line may start
  with the return, and the `[E]` header is not at the start of the buffer.
- A caught block's `The relevant error-causing widget was:` names the widget
  and a source location; it is not a frame and not the blame.
- An error whose text has no type is not a crash candidate; do not write an
  empty `exceptions[].type` (the schema requires a non-empty type).
- A `TestFailure` with `Expected:`/`Actual:` is a failed expectation, not an
  app crash. Do not turn it into an exception.
- `dart:core` terse frames carry no line; write file `dart:core` and line
  `0`. Do not invent the source line.
- A development build's stack may name `file:` paths and `_test.dart` test
  frames; keep the paths, but a test frame is not the production blame.
- AOT offsets and `build_id` lines are unsymbolicated. Keep them as printed
  and say in `analysis.json` that symbolication is needed.

Schema: `../schemas.md`.

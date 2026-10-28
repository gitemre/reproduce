# Apple crash reports

Apple inputs are an `.ips` report (a JSON header line and body), a text
`.crash` report, or an XCTest backtrace. One report is one crash; never merge
two.

## Signature

An `.ips` begins with a JSON object on its first line, then a JSON body:

```json
{"app_name":"MyApp","bundleID":"com.shop.app","bug_type":"309"}
{"exception":{"type":"EXC_BREAKPOINT","signal":"SIGTRAP"},"threads":[...],"usedImages":[...]}
```

`bug_type` is `309` (some exports use `109` with a text body). A `.crash`
has `Exception Type:`, `Triggered by Thread:` and `Thread 0 Crashed:`. An
XCTest backtrace has a `Fatal error:` line, `*** Program crashed: System
trap`, `Thread 0 crashed:` frames, or an `XCTAssert` failure.

## Header and fields

- `source.kind`: `ips`, `apple-text` or `xctest`. `source.event_id` is the
  incident id (`incident_id` in an `.ips`, `Incident Identifier:` in a
  `.crash`); an XCTest run has none. A file input keeps `source.path` and
  `source.fetched_at`; when `raw/source.json` names the same event, copy its
  `url`, `event_id`, `issue_id`, `selected`, `reason`, `transport` and
  `fetched_at`; never invent a link.
- `platform`: `ios` for these formats, including an XCTest run of an iOS
  target whose host prints macOS. `kind`: `fatal` for a process crash.
- `app.id`: `bundleID` / `bundleInfo.CFBundleIdentifier` in an `.ips`,
  `Identifier:` in a `.crash`. An XCTest backtrace names a test bundle, not
  the app: leave `app.id` empty. Keep its name/version/build from the report.
- Device facts the report prints may go in `context`; do not infer a model
  or locale.

## Exception types and signals

An `.ips` body has `exception` with `type`, `signal`, `codes` and sometimes
`subtype`. A `.crash` prints `Exception Type: EXC_BAD_ACCESS (SIGSEGV)`: the
part before the parenthesis is the type, the part inside is the signal. Use
the report's signal; the table is only for a report that omits it.

| Mach type | usual signal | meaning |
|---|---|---|
| `EXC_BAD_ACCESS` | `SIGSEGV` or `SIGBUS` | invalid pointer or address |
| `EXC_BAD_INSTRUCTION` | `SIGILL` | illegal instruction |
| `EXC_BREAKPOINT` | `SIGTRAP` | trap, debugger, Swift precondition |
| `EXC_CRASH` | `SIGABRT` | abort or uncaught language exception |
| `EXC_GUARD` | `SIGKILL` | guarded resource |
| `EXC_RESOURCE` | `SIGKILL` | resource limit |

Choose `exception.type` in this order:

1. **Swift runtime trap.** `Application Specific Information` (`.ips`) or the
   `Fatal error:` line (`.crash`, XCTest) carries the message. Type
   `Swift.FatalError`; message is the text after `Fatal error:` with the
   `File.swift:line:` prefix removed. Signal is the printed one (`SIGTRAP`
   for `EXC_BREAKPOINT`, `SIGABRT` for `EXC_CRASH`).
2. **Objective-C exception.** `EXC_CRASH`/`SIGABRT` with `Last Exception
   Backtrace`, `Exception Reason`/`Message`, or `*** -[__NSArrayM ...]: ...`.
   Type is the exception name (`NSRangeException`,
   `NSInternalInconsistencyException`, ...); message is the reason without
   the `*** ` wrapper; signal `SIGABRT`. Without a name use `NSException`.
3. **C++ exception.** `libc++abi: terminating due to uncaught exception of
   type std::out_of_range: vector` gives type `std::out_of_range`, message
   `vector`, signal `SIGABRT`.
4. **Mach exception.** Otherwise type is the Mach type and signal the printed
   signal. Message is `Exception Subtype` (`KERN_INVALID_ADDRESS at 0x...`),
   a `KERN_...` code, or the first application-specific line; empty when
   there is none.

Mach text is not a message. Do not copy `EXC_BAD_ACCESS (SIGSEGV)`,
`Exception Codes`, `Termination Reason: Namespace SIGNAL` or an `EXC_...`
line into `message`; those belong in `type`/`signal`. The fault detail from
`Exception Subtype` is the one exception: keep it as the message when no
application text exists. CoreSimulator or device
text in `Application Specific Information` is context, not a message. A
`Fatal error:` line with `EXC_BAD_ACCESS`/`SIGSEGV` is not `Swift.FatalError`
and an `EXC_BAD_ACCESS` with Swift frames stays `EXC_BAD_ACCESS`.

## Threads and frames

- `.ips`: `faultingThread` is a zero-based index into `threads`; a thread may
  also have `triggered: true`. Name it from `name`, else `queue`. Each frame
  has `imageIndex` into `usedImages`, `imageOffset`, `symbol` and sometimes
  `sourceFile`/`sourceLine`; frames are innermost first.
- `.crash`: the crashing thread is `Triggered by Thread:` or the `Thread N
  Crashed:` block. A frame is `index module address symbol + offset
  (file:line)`; `Last Exception Backtrace` is the exception's stack for an
  Objective-C exception. Thread names come from `Thread N name:` or `Thread
  N:: name`.
- XCTest: the crash is `Thread 0 crashed:`; a frame is `index [ra] [thunk]
  address symbol + offset in image at path:line:column`. The file is the
  path's basename and the line is the printed line.

Keep the crashed thread's frames in `exceptions[0].frames`. Other threads may
be kept in `threads` with `name`, `crashed` and `frames`; never append another
thread's frames to the crashing stack. `usedImages` and `Binary Images` may
be copied to `images` (`uuid`, `name`, `path`, `addr`, `size`, `arch`) for
later symbolication.

## Symbolication

- An `.ips` frame is already symbolized: copy `symbol`, `sourceFile` (the
  basename) and `sourceLine`. Do not invent a line from `symbolLocation` or
  `imageOffset`; those are instruction offsets, not source lines.
- An unsymbolicated frame prints an address and offset only, for example
  `MyApp 0x104b3a2c4 0x104b30000 + 41668`. Write `Module + offset`
  (`MyApp + 41668`), file empty and line `0`; do not turn the offset into a
  function name.
- A `sourceFile` of `<compiler-generated>` with a zero line is not a source
  location: keep the marker and `line: 0`; do not guess a file.
- An XCTest `[thunk]` or `@objc` frame is compiler glue, not app code.

## in_app from the app binary

`in_app` means the app's own code, not a framework, runtime, Xcode or test
machinery. Use image paths, not symbol names:

- `.ips`: the app image is the `usedImages` entry whose `path` ends in the
  `procPath` binary (usually index 0). Other images inside the app bundle
  (`MyApp.app/`, an embedded `.framework`, an `.appex`) are app code. System
  images (shared cache, `usr/lib`, `System/Library`, simulator runtime,
  Xcode) are not.
- `.crash`: use the `Binary Images` paths the same way; the entry whose path
  is the app's `MyApp.app/MyApp` is the app binary.
- XCTest: the image is the test bundle for the app's sources too (a Swift
  package compiles them into the test bundle). Use the source path: a file
  under the app's `Sources/` is app code even when the frame says `in
  ShopIOSTests`. `XCTestCore`, `xctest`, `CoreFoundation` and `dyld` are not.
  A test method is app-bundle code, but it is test code, not production.

`_assertionFailure`, `objc_exception_throw`, `__exceptionPreprocess`,
`objc_msgSend` and XCTest runner frames are never app code.

## Blame frame

The blame frame is the first `in_app` frame of the last exception (the root
cause), then the crashed thread's first `in_app` frame, then the first frame.
In the examples that is `CartViewModel.selectItem(at:)`,
`ImageCache.thumbnail(for:)` and `PriceParser.parse(_:)`. Do not promote a
framework frame, the Swift trap frame, or the test method that called the
real code.

## Session data

These reports are stack-only: `session_data: missing`, `breadcrumbs: []`,
`logs: []`, `custom_keys: {}` unless the file carries app-level data. A test
name goes in `tags.test`, a thread name in `tags.thread`. Never invent a
breadcrumb, key or device fact; keep app/OS facts in `app`/`context`.

## Worked examples

`swift_index_out_of_range.ips`: header `bundleID: com.shop.app`,
`EXC_BREAKPOINT`/`SIGTRAP`, and `Application Specific Information`:

```text
Swift/ContiguousArrayBuffer.swift:691: Fatal error: Index out of range
```

Result: `platform: ios`, `kind: fatal`, `app.id: com.shop.app`, `session_data:
missing`, type `Swift.FatalError`, message `Index out of range`, signal
`SIGTRAP`. The first in-app frame is `CartViewModel.selectItem(at:)` in
`CartViewModel.swift`, line `42`; `_assertionFailure` is libswiftCore.

`bad_access.crash`: `Exception Type: EXC_BAD_ACCESS (SIGSEGV)`, `Exception
Subtype: KERN_INVALID_ADDRESS at 0x0000000000000010`, and thread 0 has
`objc_msgSend` then `ImageCache.thumbnail(for:)` (`ImageCache.swift:57`).
Result: type `EXC_BAD_ACCESS`, signal `SIGSEGV`, message
`KERN_INVALID_ADDRESS at 0x0000000000000010`, app id `com.shop.app`, session
missing; blame `ImageCache.thumbnail(for:)`, because the `libobjc` frame is
not app code.

`swift_test_backtrace.txt`: `ShopIOS/PriceParser.swift:7: Fatal error:
Unexpectedly found nil while unwrapping an Optional value` and a `Thread 0
crashed:` backtrace. The first in-app frame is `PriceParser.parse(_:)` in
`PriceParser.swift`, line `7`; the next frame is the test method, not the
blame. Result: type `Swift.FatalError`, message `Unexpectedly found nil while
unwrapping an Optional value`, signal `SIGTRAP`, empty `app.id` (the file
names a test bundle), session missing.

## Failure modes

- Header without a body: keep the type, write `frames: []`, and say in
  `analysis.json` that it places nothing.
- Several reports in one file: read the one the user names, else the last
  complete one; never join frames from two incidents.
- `EXC_BAD_ACCESS` with no subtype or application text: leave `message`
  empty.
- An Objective-C exception with no `Last Exception Backtrace`: use the
  crashing thread; `objc_exception_throw`/`__exceptionPreprocess` are not app
  code and the throw site is not necessarily the blame.
- A simulator `.crash` may print macOS/CoreSimulator text while the app is
  iOS; the bundle identifier decides. That text is context, not a message.
- A redacted or missing symbol (`???`, address only): keep `Module + offset`
  or the address, file empty and line `0`; never guess a source location.
- An `XCTAssert`/`XCTUnwrap` failure with no trap is a test failure, not a
  process crash: `kind: non_fatal`, no signal, keep the failure's message,
  and do not turn it into `Swift.FatalError`.

Schema: `../schemas.md`.

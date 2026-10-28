# JavaScript and Jest

Jest output and React Native reports carry a JavaScript error. The wrapper a
crash reporter puts around it is not the error: read the JS error and its
frames.

## Inputs

Jest's failure block names the test after `●`, prints the error, a code
frame and then the V8 frames:

```text
FAIL src/cart/__tests__/PriceParserCrash.test.ts
  ● a price with a decimal comma

    PriceFormatError: For input string: "12,5"

      15 |     const value = text.trim();
    > 17 |       throw new PriceFormatError(…);
         |             ^

      at PriceParser.parse (src/cart/PriceParser.ts:17:13)
      at parse (src/cart/CartScreen.tsx:35:63)
          at Array.reduce (<anonymous>)
      at CartViewModel.reduce [as total] (src/cart/CartScreen.tsx:35:23)
      at Object.total (src/cart/__tests__/PriceParserCrash.test.ts:7:23)

Test Suites: 1 failed, 1 total
Tests:       1 failed, 1 total
```

A React Native report wraps the same error in a native exception:
`com.facebook.react.common.JavascriptException` on Android or
`RCTFatalException` on iOS, whose message starts `Unhandled JS Exception: `
or holds the JS error's own text, its component stack and its stack.
`io.invertase.firebase.crashlytics.JavaScriptError` is the wrapper
react-native-firebase records; its message is `<Name>: <message>` or just
the message and its first frame is a fake `<unknown> (<Name>)`.

## Failure shapes

- Each `● <test name>` block is one failed test and one crash candidate.
  `Test suite failed to run` is a build, import or configuration error, not
  an app crash: leave it out or report it as a gap.
- A failed expectation (`expect(…)`, `Expected:`/`Received:`, a snapshot
  mismatch) is not a crash. Its header is `expect(` or `AssertionError` from
  the matcher, and it has no app throw site.
- A `console.error` / `console.warn` block in a passing run is an error the
  app caught and logged. Keep it as `kind: non_fatal` with its frames; it is
  not a failed test and not a fatal crash.
- Several `●` blocks in one file are several candidates. Do not merge their
  frames.

## What to extract

1. Read the error line at the start of the block: `<Type>: <message>`. The
   type is the name before the first `: ` (`PriceFormatError`, `TypeError`,
   `RangeError`). Continuation lines before the code frame continue the
   message, joined with `\n`.
2. Ignore Jest's code frame (`15 | …`, `> 17 | …`, `| ^`). It repeats the
   source around the throw; the stack's `file:line` is the evidence.
3. Read every `at …` line in printed order, innermost first.
4. For a React Native wrapper, keep the wrapper as the outermost exception
   and put the JS error after it; the JS error is the root cause. When the
   wrapper's message holds `This error is located at:` (component stack),
   `, stack:` followed by `fn@1:<col>` frames, or `, js engine: hermes`,
   keep only the error's own text as the message. The component stack names
   components, not frames.
5. For a `JavaScriptError`, read `<Name>: <message>` from the message. If the
   message has no type, the fake first frame `<unknown> (<Name>)` or
   `(<Name>:0)` names it. Drop that fake frame; it is not a location.

## Frames, symbols and positions

A V8 frame is one of:

- `at Class.method (src/file.ts:17:13)` — the class is the frame's
  module and `method` is the symbol the device shows (`parse`, not
  `PriceParser.parse`); keep `file` and `line`, drop the column.
- `at fn (src/file.tsx:35:63)` — symbol `fn`.
- `at Class.method [as alias] (src/file.tsx:35:23)` — the class is the
  module and `alias` is the symbol (`total`, not `reduce`).
- `at file.ts:17:13` — file and line, no function: use `anonymous` as the
  symbol.
- `at Array.reduce (<anonymous>)` — an engine built-in, not app code.
- `parse@1:603386`, `anonymous@1:712202`,
  `fn@index.android.bundle:1:603386`,
  `at fn (address at index.android.bundle:1:603386)` — a Hermes/JSC bundle
  position.

For a source file, the line is real. For a bundle position, `1` is the
bundle's single line and the column is the position: write the bundle name
as the file (empty when the frame names no bundle), line `0`, keep
`fn@1:<col>` as the raw frame, and do not write line `1` as a source line.
The position places the crash only inside that one build: it is
unsymbolicated until the build's source map maps it to a source file. An
`anonymous@1:<col>` is an unnamed app function at a bundle position (an
arrow function, often the throw site); an `anonymous` frame with no bundle
position and no column places nothing.

A development bundle (`localhost:8081`, `…?dev=true`) is not a release
bundle: its line and column move with any edit. Keep the position as raw
evidence, line `0`; a named function stays app code, an anonymous one places
nothing until the dev server's source map is used.

## in_app and JS/native separation

JavaScript frames belong to the app when their file is the app's source or
bundle and is not under `node_modules/`; a test file (`__tests__/`,
`*.test.ts`, `*.spec.js`) is test code, not the production location. Engine
built-ins (`<anonymous>` for `Array.reduce`, `(native)`,
`InternalBytecode.js`, `[native code]`), React internals, and Babel/Hermes
helpers (`_construct`, `_wrapNativeSuper`, `_callSuper`, `_inherits`) are
not app code. The root error's own constructor frame at the top
(`new ReceiptError`, `ReceiptError.constructor`) is where the error object
was made, not where the app crashed.

A React Native wrapper's native part is not app code either:
`com.facebook.react.*`, `com.facebook.jni.*`, `com.facebook.hermes.*`,
`expo.modules.*`, `RCTFatal`, `-[RCTExceptionsManager …]`,
`ExceptionsManagerModule.reportException` and `facebook::react::…` are the
bridge that reported the error. If a JS error has only native frames and no
JS frame, it places nothing: do not blame the bridge or the thread that
reported it.

## Fields

- `platform`: `unknown` for Jest output. A React Native report that names
  Android or iOS (`JavascriptException` on an Android event, a
  `RCTFatalException` on iOS) takes the report's platform.
- `kind`: `fatal` for an uncaught JS error or a failed test with an error; a
  test output's `fatal` means the run ended with an uncaught error, not that
  the app's process crashed. `non_fatal` for an error the app logged through
  `console.error`/`warn`.
- `app.id`: only when the report names the app id (a package id, a
  `Bundle ID`, an `app` context); a source path or a class name is not an id.
- `exceptions[].signal`: empty; a JS error is not a POSIX signal.
- `session_data`: `missing` for Jest output; `breadcrumbs: []`, `logs: []`,
  `custom_keys: {}` unless the file carries them. A React Native event may
  carry breadcrumbs; then `session_data: present` and keep them.
- `tags.test`: the Jest test name after `●`. A device event may keep
  `runtime: js` and the component stack.

## Blame frame

`exception.blame_frame` is the first `in_app` frame of the **last** exception
(the JS error), then an outer exception's first `in_app` frame, then the
crash's first frame. In the Jest fixture it is `parse` in
`src/cart/PriceParser.ts`, line `17` — the app function that threw, not the
`CartViewModel.total` call above it and not the test's `Object.total`. In a
React Native report do not blame the `JavascriptException`/`RCTFatalException`
wrapper, the bridge, or a native thread; a JS error with no JS frame has no
blame frame in app code.

## Worked example

`jest_failure.txt` is a Jest run of a store app. Type `PriceFormatError`,
message `For input string: "12,5"`, frames `PriceParser.parse`
(`src/cart/PriceParser.ts:17:13`), `parse` (`src/cart/CartScreen.tsx:35:63`),
`Array.reduce` (anonymous), `CartViewModel.reduce [as total]`
(`src/cart/CartScreen.tsx:35:23`) and the test's `Object.total`. Result:
`platform: unknown`, `kind: fatal`, empty `app.id`, `session_data: missing`,
and the blame frame `parse` in `src/cart/PriceParser.ts`, line `17`.

## Failure modes

- The code frame's `>` line is not a stack frame; do not use it as a frame
  or as the message.
- A `console.error` block can appear in a passing suite; it is a non-fatal
  the app caught, not a failed test.
- `Test suite failed to run`, a module-resolution error or a TypeScript
  compile error is a build failure, not an app crash.
- `Array.reduce (<anonymous>)` is a built-in; do not promote it to the blame
  frame and do not give it a source line.
- A bundle position is line `1` by construction. Writing `line: 1` loses the
  column that actually places the crash; keep the position in the raw frame
  and symbolize before placing it.
- A React Native message may include React's component stack and
  `, js engine: hermes`; neither is the message or a frame.
- A `JavaScriptError` fake first frame (`<unknown> (<Name>:0)`) names the
  error, not a source location. Drop it before choosing the blame frame.
- `new ReceiptError` / the error's constructor is not the throw site; the
  next app frame is.

Schema: `../schemas.md`.

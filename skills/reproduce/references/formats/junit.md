# JUnit XML

A JUnit report written by Gradle, Maven, Bazel or a JUnit runner. It records
the tests that ran; a failing test is a stack trace, not an app crash.

## Signature

The root is `<testsuite>` or `<testsuites>`; each `<testcase>` may hold a
`<failure>` or `<error>` element:

```xml
<testsuite name="com.shop.app.cart.PriceParserCrashTest" tests="2" errors="1">
  <testcase name="reproduces crashlytics issue 9f3c2a"
            classname="com.shop.app.cart.PriceParserCrashTest">
    <failure message="java.lang.NumberFormatException: For input string: &quot;12,5&quot;"
             type="java.lang.NumberFormatException">java.lang.NumberFormatException: ...
	at com.shop.app.cart.PriceParser.parse(PriceParser.kt:18)
```

(The sample is abridged; real reports close every element.)

`failure` and `error` are both crashes for this purpose. A passing or skipped
test has neither and is not a crash. Gradle may write a report with no
failure when the build failed before a test ran; that is not a crash either.

## What to extract

1. Walk every `<testcase>`; a test with one or more `<failure>`/`<error>`
   elements is one crash candidate. A test with two problem elements is two
   candidates; keep them in document order.
2. `type` comes from the element's `type` attribute. `message` comes from its
   `message` attribute; XML entities are already decoded by the XML parser.
3. The element's text is the stack trace. It follows the JVM grammar in
   [jvm.md](jvm.md): exception headers outermost first, frames printed
   innermost first, `Caused by:` starts the next exception. When the body has
   a header, trust it over the attributes for a chained exception; otherwise
   the attributes name the exception. A frame may start with a module prefix
   such as `java.base/`; drop the prefix from the symbol and keep the file and
   line.
4. `tags.test` is `<classname>.<name>`, the test that failed. Keep it; it
   tells the report which reproduction attempted the crash.
5. `platform`: `unknown`. A unit-test report does not say Android or iOS.
6. `kind`: `fatal`. A test output's `fatal` means the run ended with an
   uncaught error; it does not say the app's process crashed, and the report
   calls the observation a test result.

## app id and in_app

The XML names a test class, not an app package. Leave `app.id` empty rather
than guessing it from `com.shop.app.cart.PriceParserCrashTest`; the test
package and the app id are not the same thing. Mark frames `in_app` with the
same framework prefixes as [jvm.md](jvm.md): the production function the test
calls is app code; the test class and JUnit/JDK/Mockito frames are not. A test
frame is `in_app: false` (R1) even when it carries the app's package.

The blame frame is still the first `in_app` frame of the root cause. In the
worked example that is `PriceParser.parse`, not the test method: the test
called the real code and the real code threw. If every frame is a test
runner or the test itself, the failure never entered app code; say that in
`analysis.json` and do not name a production function.

## Session data, threads and keys

- `session_data`: `missing` for a normal report. `<system-out>` and
  `<system-err>` are the test process's output, not the user's breadcrumbs.
  If they carry real app log lines, keep those lines in `logs`, use
  `partial`, and do not turn them into breadcrumbs.
- `threads`: omit. A JUnit failure records one thread's stack, not a thread
  dump.
- `custom_keys` and `context`: empty. The test name is a tag, not a custom
  key. Do not invent device, app-version or screen fields.
- `signal`: empty; a unit test failure is a Java exception.

## Observed evidence

A JUnit report is normally read after a reproduction test runs, so it is
`observed.json` material: `evidence` is `supplied` when the report file was
given to the run, and `raw` names that file. It is not proof by itself, and
it is not the reported crash when it is the report the user gave. The reader
still writes `crash.json` when the user hands over a JUnit file as the
target; the analysis then says the source is a test report.

## Missing fields

- No `type`: fall back to the header in the body. No header either: skip the
  candidate and report the gap; `crash.json` requires a non-empty exception
  type, so do not write an empty one.
- No `message`: use the header's message, else `""`.
- No frames: write `"frames": []`; an assertion failure often has no stack.
  The analysis says the report does not place the crash.
- No app id, thread, session data or signal: leave empty/`missing`; do not
  fill from the fixture or from the test class name.

## Worked example

In the private maintainer benchmark,
a synthetic JUnit fixture `TEST-com.shop.app.cart.PriceParserCrashTest.xml`
has two test cases and one `<failure>`:

```text
type:    java.lang.NumberFormatException
message: For input string: "12,5"
frames:  jdk.internal.math.FloatingDecimal.readJavaFormatString (FloatingDecimal.java:2054)
         java.lang.Float.parseFloat (Float.java:476)
         com.shop.app.cart.PriceParser.parse (PriceParser.kt:18)
         com.shop.app.cart.PriceParserCrashTest.reproduces crashlytics issue 9f3c2a (PriceParserCrashTest.kt:12)
```

The result has `platform: unknown`, `kind: fatal`, empty `app.id`,
`session_data: missing`, the type and message above, and the eight frames in
the body's order. `PriceParser.parse` is `in_app`; the test method and the
JDK and JUnit frames are not. The blame frame is
`com.shop.app.cart.PriceParser.parse` in `PriceParser.kt`, line `18`.

## Failure modes

- `failure` with an assertion message but no stack: keep the type/message,
  leave `frames` empty, and do not use the test method as the crash site.
- A report with several failures: one candidate each; do not merge their
  frames. If the user gave the file as a target and did not name a test, use
  the only failure; with several, say which one and why.
- XML escapes (`&quot;`, `&lt;`) must be decoded once; do not write the
  entity text into the message.
- A `system-out` stack from another test is not the failure's stack; keep
  the failure element's body.
- A Gradle wrapper or compiler error in `<system-err>` is not the app's
  crash; it is a build failure and the run records it as such.

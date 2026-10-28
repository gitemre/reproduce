# JVM text

A Java or Kotlin stack trace copied from a crash console, a test log or a
bug report. It is the same grammar Android writes in logcat, without the log
prefixes.

## Inputs

- The exception header: `java.lang.NumberFormatException: For input string: "12,5"`.
- Zero or more `\tat class.method(File.kt:18)` lines under it.
- `Caused by:` headers with their own frames, outermost first.
- `Exception in thread "main" …` and a `Process:` line may sit above it; a
  `FATAL EXCEPTION:` line makes it [logcat](logcat.md) instead.
- `Suppressed:` and `... N more` lines are part of the printed trace, not new
  exceptions.

## What to extract

1. Read the exception chain from the top. Each `Caused by:` line starts the
   next exception; keep the printed order in `exceptions` (outermost first).
   The last item is the root cause.
2. Split each header at the first `: ` after the class name: the class is
   `type`, the rest is `message`. A header with no colon has an empty message.
3. Read the frames under each exception in printed order. The printed order is
   innermost first, so keep it unchanged: `frames[0]` is where the exception
   was raised.
4. A frame line is `at <class>.<method>(<file>:<line>)`. Split the last `.` to
   get the class and method; the symbol is `<class>.<method>`. A Java 9+ line
   may start with a module prefix (`java.base/java.lang.Float.parseFloat`);
   drop the prefix from the symbol and keep the file and line. `Native Method`
   and `Unknown Source` mean a file with line `0`; keep the text as the file
   and do not invent a line.
5. `... N more` means N frames were elided. Do not fabricate them. If the same
   frames appear in the parent exception, copy those frames only when the
   printed trace makes the match unambiguous; otherwise leave the trace as
   printed and say frames were elided in `analysis.json`.
6. `Suppressed:` exceptions are not part of the cause chain. Leave them out of
   `exceptions`; mention one in `context` only when it explains the trigger.

## Fields

- `platform`: `android` when any frame is in `android.`, `androidx.`,
  `com.android.` or `dalvik.`; otherwise `unknown`.
- `kind`: `unknown` for a pasted trace. A `FATAL EXCEPTION:` or ANR header is
  logcat evidence; a thrown exception in a test log is not automatically
  fatal.
- `app.id`: only when the input names it, for example a `Process:` line or an
  app-id header. A package-looking class does not name the app id; leave it
  empty.
- `exceptions[].signal`: empty for a Java exception. A signal belongs to a
  native crash, not a `NumberFormatException`.
- `session_data`: `missing` for a bare trace. A copied stack has no
  breadcrumbs, logs, custom keys or device context, so `breadcrumbs`, `logs`
  and `custom_keys` are empty. `context` — the environment fields such as app
  version, device model, OS and locale — stays empty too.
- `threads`: omit unless the input prints a named thread with a separate
  stack. A trace without a thread header has no thread evidence.

## in_app

Mark a frame `in_app` when its class is app code, not the platform, the
language runtime, a test runner or a common library. Common framework
prefixes include `java.`, `javax.`, `jdk.`, `sun.`, `android.`, `androidx.`,
`kotlin.`, `retrofit2.`, `okhttp3.`, `org.junit.`, `org.mockito.`,
`com.google.` and `io.reactivex.`.

When the app id is known, prefer its package and its first two segments; that
avoids marking a dependency that happens to share a prefix. Without an app
id, every non-framework class is app code. A test class is not app code:
mark test frames `in_app: false` even though they are not framework code.
A test frame shows how the call was reached, never the production crash
site; the blame frame is the first `in_app` frame of the root cause.

## Blame frame

`exception.blame_frame` is the first `in_app` frame of the **last** exception
(the root cause). If the root cause has no `in_app` frame, use the first
`in_app` frame of the next outer exception; if none exists, use the root
cause's first frame and say in `analysis.json` that the trace names no app
code. Keep `symbol`, `file` and `line` exactly as printed.

## Missing fields

- No message: use `""`; do not fill it from the type or the analysis.
- No frames: write `"frames": []`; the analysis says why the crash cannot be
  placed. A stack-only input is valid.
- No app id, thread, platform or signal: leave the value empty/`unknown`; do
  not infer it from the fixture, the class name or the message.
- No session data: `session_data: missing`. Never turn the exception message
  or a guess into a breadcrumb.

## Worked example

In the private maintainer benchmark, a synthetic `number_format.txt` fixture
is an Android trace:

```text
java.lang.NumberFormatException: For input string: "12,5"
	at jdk.internal.math.FloatingDecimal.readJavaFormatString(FloatingDecimal.java:2054)
	...
	at com.shop.app.cart.PriceParser.parse(PriceParser.kt:18)
	at com.shop.app.cart.CartViewModel.onPriceLoaded(CartViewModel.kt:42)
```

The result has `platform: android` (Android frames are present), `kind:
unknown`, an empty `app.id`, `session_data: missing`, type
`java.lang.NumberFormatException`, message `For input string: "12,5"`, and
16 frames in printed order. The three `com.shop.app` frames are `in_app`; the
retrofit, JDK and Android frames are not. The blame frame is
`com.shop.app.cart.PriceParser.parse` in `PriceParser.kt`, line `18`.

## Failure modes

- A multi-line message continues on indented lines before the first frame;
  keep the lines in the message rather than turning them into frames.
- `Caused by:` may repeat the outer message; do not merge the exceptions and
  do not drop the chain.
- A frame copied from a minified release build has short names or
  `SourceFile`; keep it, mark it `in_app` only when the package says so, and
  note that a mapping is needed before placing it.
- A test-only stack (JUnit, Mockito, Gradle) names no app code. Do not use the
  test class as the production crash site.

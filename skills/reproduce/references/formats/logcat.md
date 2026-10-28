# Logcat

Android's system log, as captured with threadtime or brief formatting, from
Android Studio, a bug report or a crash console.

## Signature

A threadtime line looks like:

```text
10-19 20:53:35.516  4288  4288 E AndroidRuntime: FATAL EXCEPTION: main
```

The columns are `MM-DD hh:mm:ss.mmm`, pid, tid, level and `tag: message`.
Other captures use `E/AndroidRuntime(4288):` (Android Studio) or drop the
timestamp. A crash is a block of lines with one tag and pid:

- `FATAL EXCEPTION: main`
- `Process: com.shop.app, PID: 4288`
- `java.lang.NumberFormatException: For input string: "12,5"`
- `\tat com.shop.app.cart.PriceParser.parse(PriceParser.kt:18)`

Native crashes use `Fatal signal 11 (SIGSEGV) …` and `DEBUG`/`crash_dump`
frames; ANRs use `ANR in com.shop.app` and a `Reason:` line. ACRA and
CustomActivityOnCrash write their own handler line and then the trace.

## What to extract

1. Start at the `FATAL EXCEPTION` line, or at `Process:` or the exception
   header when the capture was cut above its FATAL line. Take the following
   lines that belong to the same tag and pid until the next crash starts.
2. The exception chain and frames follow the JVM grammar in
   [jvm.md](jvm.md): headers are outermost first, frames are printed
   innermost first, and `Caused by:` starts the next exception.
3. `kind`: `fatal` for an uncaught `AndroidRuntime` crash; `anr` for
   `ANR in`; `non_fatal` for a `System.err` trace or an exception the app
   logged under its own tag at error/warning level; `unknown` when the block
   does not say.
4. `app.id`: take it from `Process: <package>` first, then from
   `Start proc <pid>:<package>/` in the same capture, then from an ACRA
   handler line. Do not derive it from a class name.
5. `threads`: logcat normally prints only the crashing thread. Keep
   `FATAL EXCEPTION: main` as `tags.thread` (and `tags.pid`); do not build a
   thread list from unrelated lines.
6. `source.event_id`: with a timestamp, use `logcat:<pid>@<timestamp>` so the
   same buffered crash is recognisable. Without a timestamp, leave it empty;
   a pid alone repeats across boots.

## Fields

- `platform`: always `android`.
- `signal`: empty for a Java exception. A native crash's signal (for example
  `SIGSEGV`) goes in `exception.signal`; the type is the signal name and the
  message is the fault address and cause when printed.
- `session_data`: `missing` for a crash-only capture. The system's
  `ActivityManager` start/display lines are not breadcrumbs, and the
  exception message is not a log line. If the capture also has an app-level
  event trail, keep those entries in `logs`, never invent one, and use
  `partial`.
- `custom_keys`, `context`: empty. A logcat has no device facts (model, OS,
  locale); do not invent them from the fixture. `tags` may hold `pid`,
  `thread`, `handler` and `logged_by`.
- A logcat line whose level is `I` and whose text is not the crash is
  transport, not evidence. Quote it in `analysis.json` when it explains the
  route to the crash.

## in_app

Use the same package test as [jvm.md](jvm.md): framework and library
prefixes are not app code; when `app.id` is known, only its package (and its
first two segments) is app code. Native frames are app code when the library
path is under the app's data directory, not the system's. The first `in_app`
frame of the root cause is the blame frame.

## Blame frame and missing fields

- One crash per `FATAL EXCEPTION` block. If the file has several, read the
  one the user names; otherwise the last complete one, and record why. Never
  mix lines from two pids into one stack.
- A truncated capture may start at `Process:` or at the exception header;
  parse what is there. If no frame remains, `frames` is empty and the
  analysis says the capture was cut.
- No `Process:` line, no app id: leave `app.id` empty. Do not borrow the app
  id from a neighbouring crash of another process.
- `AndroidRuntime` under a pid of `system_server` is the framework's crash,
  not the app's. Skip it when the capture is the app's.
- A brief-format log has no timestamp: `event_id` stays empty.

## Worked example

In the private maintainer benchmark,
a synthetic `emulator_shop_android.txt` fixture opens with the
launcher start, then one `AndroidRuntime` block for `com.shop.app`:

```text
E AndroidRuntime: FATAL EXCEPTION: main
E AndroidRuntime: Process: com.shop.app, PID: 4288
E AndroidRuntime: java.lang.NumberFormatException: For input string: "12,5"
E AndroidRuntime: 	at com.shop.app.cart.PriceParser.parse(PriceParser.kt:18)
```

The result has `platform: android`, `kind: fatal`, `app.id: com.shop.app`,
`tags.pid: 4288`, `tags.thread: main`, `session_data: missing`, type
`java.lang.NumberFormatException`, message `For input string: "12,5"`, and
the 17 printed frames. The `com.shop.app` frames, including the two R8
synthetic `CartLoader` frames, are `in_app`; the JDK and Android frames are
not. The blame frame is `com.shop.app.cart.PriceParser.parse` in
`PriceParser.kt`, line `18`.

## Failure modes

- Interleaved lines from another process: keep only the crash's tag and pid.
- A second crash in the same file: do not append its frames to the first.
- ACRA's handler line and AndroidRuntime's copy can describe one crash; keep
  one crash and note the handler.
- A native crash has no Java message. Do not invent a Java type; use the
  signal and the printed fault text.
- An ANR is not an exception. Its type is `ANR`; put the `Reason:` text in
  the message and do not read the main-thread dump as the app's stack.

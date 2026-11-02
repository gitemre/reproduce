# Recorded events

Some reports are not crashes. The app caught the error, decided it was worth reporting, and called a
reporter itself: `FirebaseCrashlytics.recordError`, Sentry `captureException` / `captureMessage`, Bugsnag
`notify`. Nothing escaped, no process died, and the console event exists only
because that call happened. Crashlytics files every one of them under its own name (`FlutterError`), so the
issue title names the reporter's caller, not a thrower.

## Contents

When to use · Recognise it · The observation · Capture it · Match it · Device path · What it is not

## When to use

Read this in step 1 when the target's innermost frame is a reporter call rather than app code, and in
step 3 when you plan the test. A fatal report, an ANR, and a framework error that escaped keep the normal rules.

## Recognise it

The target is a recorded event when:

- the frames look like `Reporter.recordError` → app function → app caller, and the console's blame frame is
  the app function that called the reporter;
- the message is an app label — a `String` the app passed (`checkout_failed`), a constant, or an
  exception's `toString` — not a framework assertion;
- the console type is the transport's own naming: `FlutterError` for the Crashlytics Flutter plugin on iOS
  and Android, the recorded class or a bare message for Sentry;
- the kind is `non_fatal` (a `fatal: true` recording has the same shape: it is the app saying it died).

A recorded report may add a reason: the Crashlytics Flutter plugin appends `. Error thrown <reason>.` to the
message when `reason:` was passed. Compare the message as the app wrote it.

`recordFlutterError` is the exception: there the app forwards `FlutterError.onError`, the error really
escaped a build or layout, and R6 already matches its type. Such an event keeps the normal rules.

`crash.json` keeps the reported type and message as the console shows them; `analysis.json` says the event
is a recorded event and names the reporter.

## The observation

The observation is the payload the app handed to the reporter: the message, the frames of the real stack,
the `fatal` flag, and the reporter symbol that was called. `observed.json` writes it with
`kind: "recorded"` and a `reporter` string; the frames start at the reporter call, so the first app frame is
the function that recorded.

The type is the transport's, not the app's: the same transport names every recorded error the same way. It
matches by transport and carries no other signal.

## Capture it

Drive the real code to the recording call with the reported input, and capture at the transport boundary:
the Firebase platform interface, the Sentry client, the channel the plugin uses. Fake only that boundary —
the native SDK or the network — and leave the app's code and its real stack in place.

- Do not call the reporter yourself, do not build the message yourself, and do not throw an exception to
  imitate the report: the payload is then test-supplied (R1 by analogy) and the verdict is at most
  `PARTIAL`.
- Do not mock the code that decides to record: the retry, validation or state logic that reaches the
  reporter must run for real.
- The captured frames are the evidence of the place; keep the whole stack, not only the top frame.
- A test that passes is expected: the app does not throw. The run's output must show the captured payload,
  and the reader turns it into `observed.json`.

## Match it

R16 applies: the message and the reporter's app frame decide, and R14 sets the level — `call-path` when two
or more app frames match in order, `blame-frame` when only the recording function's frame matches. Another
message at the same place is at most `PARTIAL`. A type-only match is not evidence, because the transport
assigns the type.

## Device path

A recorded event has no `.ips` and no native crash line to read. On a device the evidence is the payload
the SDK kept: the log line beside the report, the queue entry, or the console event after an upload. Never
launch an app that reports to production without the user's yes. When the trigger cannot be staged on a
device (a transient state, a revoked permission), the code path is the only route, and the report says
so.

## What it is not

- Not a process crash: the app kept running. The report states that no user-visible failure is implied.
- Not weakened evidence: the recording call, its stack and its message are the app's own code, and they
  place the report as precisely as a throw does.
- Not a reason to skip the device path in general: only an event whose trigger cannot be staged is left to
  the code path.

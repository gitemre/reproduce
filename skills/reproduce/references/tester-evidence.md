# Tester evidence

How a tester with a physical device and no host tools captures evidence the reader can use. Use this with
[tester-manual.md](tester-manual.md). The tester drives; the agent reads the files and never claims to have
driven the device.

## Contents

Android · iPhone · The test project · What to send · Timestamps and build · Privacy · Limits

## Android

- **Screen recording.** Quick Settings → Screen recorder (the name varies by OEM). Record the whole
  attempt, including the app launch and the crash. Keep the microphone off.
- **Screenshots.** The crash dialog, the app version/build, the OS version and the device model.
- **Bug report.** Settings → System → Developer options → Bug report. If Developer options is hidden, open
  Settings → About phone and tap Build number seven times, then retry. Some OEMs name it "Feedback" or
  "Error report". The zip contains `bugreport-*.txt` with logcat and dumpsys; send the zip or the logcat
  portion.
- **The app's own export.** If the app has a debug menu, "send feedback" or a log export, use it; it is
  usually easier than a bug report.
- **The test project.** If the app reports to a test Crashlytics or Sentry project, the new event is the
  best evidence. Note the time, build and device; the agent fetches it.

## iPhone

- **Screen recording.** Control Center → Screen Recording; microphone off. The recording shows the app
  closing or the error state.
- **Screenshots.** The error state, the app version/build (App Store page or the app's About), the iOS
  version and the model.
- **Analytics Data.** Settings → Privacy & Security → Analytics & Improvements → Analytics Data. Find the
  app's `.ips` file (the date and time are in the name). "Share with App Developers" must be on; if the
  file is absent, the app did not share it. Send the `.ips`; do not rename it.
- **TestFlight feedback.** TestFlight → the app → Send Beta Feedback; include what happened and the
  screenshots. The developer sees it in App Store Connect.
- **The test project.** If the app reports to a test Sentry or Crashlytics project, the new event is the
  best evidence; note the time and build.

A physical iPhone cannot run `logcat`, and `Console.app` needs a Mac. Do not promise those.

## The test project

The strongest no-tool loop: the app is built with a **test** Crashlytics or Sentry project, the tester
reproduces, and the agent fetches the new event by time, build and device. The tester only needs the build
and the steps; no adb, Xcode or API token on the tester's machine.

This requires a test build. A production-reporting build needs the user's explicit yes before the tester
launches it, and the event may contain real user data; redact it.

## What to send

One folder or zip:

- `replay.mp4` (or the platform's screen recording);
- `crash.png`, `build.png`, `os.png`;
- `logcat.txt`, `bugreport-*.zip` or `crash.ips`;
- the test-project event time and build, if used;
- a short note with the exact input, start/end time and any variant.

Name the files; a folder of `IMG_1234` files is hard to place.

## Timestamps and build

Record the start and end time of the attempt, the app version/build, the OS version and the device model.
The time is how the reader finds the event in logcat, Analytics Data or the test project. A screenshot of
the build and OS is better than a typed value.

## Privacy

Ask for the crash screen only. No full device backup, passwords, cookies, tokens, personal messages or
photos. Redact names, emails and ids that are not needed to place the crash. The tester signs in on the
device; never ask for the password in chat.

## Limits

A video can show that the app failed, but it may not carry an exception type or a frame. A crash log,
`.ips` or test-project event can. The reader writes `observed.json` with `evidence: supplied`; the referee
decides, and a video alone may be `PARTIAL` or `NO_VERDICT`. The report says `driver: tester`.

# Android device path (raw adb)

The model chooses the commands. This page is the platform vocabulary: emulator, install, isolation, UI tree,
logs and video. No Python driver is required.

## Build and boot

The SDK tools are `$ANDROID_HOME`'s `emulator`, `platform-tools/adb` and
`cmdline-tools/latest/bin/avdmanager`; `avdmanager` needs a JDK (Android Studio's JBR is its
`Contents/jbr/Contents/Home`). Pick an installed image with `sdkmanager --list_installed`, matching the
crash's API level.

```bash
avdmanager create avd -n reproduce-<id> -k 'system-images;android-<api>;google_apis;arm64-v8a' -d pixel_7
emulator -avd reproduce-<id> -read-only -no-snapshot-save -no-boot-anim -no-audio -port 5580 &
adb -s emulator-5580 wait-for-device
adb -s emulator-5580 shell getprop sys.boot_completed     # wait for 1
adb -s emulator-5580 install -r -t <app.apk>
```

Disable animations and rotation for stable taps:

```bash
adb -s emulator-5580 shell settings put system accelerometer_rotation 0
adb -s emulator-5580 shell settings put system user_rotation 0
adb -s emulator-5580 shell settings put global window_animation_scale 0
adb -s emulator-5580 shell settings put global transition_animation_scale 0
adb -s emulator-5580 shell settings put global animator_duration_scale 0
```

Set locale with `setprop persist.sys.locale <tag>` and `setprop ctl.restart zygote`, then wait for
`sys.boot_completed` again. Set timezone with `setprop persist.sys.timezone <zone>`.

## Isolate before launch

Cut the network while `adb` still works:

```bash
adb -s emulator-5580 shell settings put global airplane_mode_on 1
adb -s emulator-5580 shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true
adb -s emulator-5580 shell svc wifi disable
adb -s emulator-5580 shell svc data disable
```

Check that a host is unreachable (`adb shell ping -c1 <host>`) before installing or launching. The emulator's
`10.0.2.2` is the host, not production; a reporting SDK still sees no network.

## Read the screen

```bash
adb -s emulator-5580 shell uiautomator dump /sdcard/ui.xml
adb -s emulator-5580 exec-out cat /sdcard/ui.xml > ui-01.xml
```

Read the XML. Choose a node by `text`/`content-desc` and its `bounds="[x1,y1][x2,y2]"`; tap the centre:

```bash
adb -s emulator-5580 shell input tap 540 492
adb -s emulator-5580 shell input text 'Bursa'
adb -s emulator-5580 shell input keyevent 4       # Back
```

`input text` is ASCII; for Turkish characters tap the on-screen keys or use the app's sample data. A dump
during a splash animation may return `ERROR: null root node`; wait for the activity and retry. Re-dump after
every navigation; do not reuse bounds from the previous screen.

Other useful commands: `am start -W -n <pkg>/.MainActivity`, `monkey -p <pkg> -c
android.intent.category.LAUNCHER 1`, `am force-stop <pkg>`, `screencap -p /sdcard/shot.png` and
`input swipe x1 y1 x2 y2 300`.

## Evidence

Start logcat and the recording before the trigger:

```bash
adb -s emulator-5580 logcat -c
adb -s emulator-5580 logcat -v threadtime > logcat.txt &
adb -s emulator-5580 shell screenrecord --time-limit 180 /sdcard/replay.mp4 &
```

After the crash:

```bash
adb -s emulator-5580 shell pkill -INT screenrecord
adb -s emulator-5580 pull /sdcard/replay.mp4 replay.mp4
adb -s emulator-5580 exec-out screencap -p > crashed.png
```

Keep `ui-*.xml`, `logcat.txt`, `replay.mp4`, screenshots and the app's queued Sentry/Crashlytics events. The
referee reads `logcat.txt` for the fatal exception and frames; never edit it.

## Non-fatals

If the app catches the error and reports it to Sentry/Crashlytics, read its queue under the app's data
directory (`adb shell run-as <pkg>` or `adb root` on a debug image) or the app's own log line. A caught error
is evidence too; do not turn it into a fatal claim.

## When it fails

- `uiautomator dump` returns no tree: wait for the foreground activity, retry; if the app is not focused,
  launch it again.
- The tap does nothing: re-dump; the screen may have moved, or a system dialog is on top.
- The app reports to production: stop; do not continue on a device that is not isolated.
- No emulator or image: stop; the user installs it. Never fake a device.

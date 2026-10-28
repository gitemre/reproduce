# Code path

## When to use

Read this in step 0 (probe the project) and again in step 2 (choose the code and the test location).
The probe reads the checkout; it never builds it, installs anything or writes to the app. Write
`project.yaml` in the run folder with the six fields from [schemas.md](schemas.md#projectyaml).

## Detect the project

Start at the app repository root and use the first match:

1. **Flutter**: `pubspec.yaml` with `sdk: flutter`, next to `android/` or `ios/`.
2. **React Native**: `package.json` depends on `react-native`, next to `android/` or `ios/`.
3. **Gradle**: `settings.gradle` or `settings.gradle.kts`, at the root or in `android/`.
4. **Xcode**: an `*.xcworkspace` or `*.xcodeproj` outside `Pods/`.
5. **SwiftPM app**: `Package.swift` with an iOS platform and an app `Info.plist`
   (`CFBundlePackageType` is `APPL`).

No match: stop. There is no app repository here; that is the tester path (v2), not a v1
reproduction. If the root has no app but exactly one folder one or two levels down does, that folder
is the app; run its commands there.

## App id

- **Android**: the app module's `applicationId`; else its `namespace`.
- **Xcode**: the application target's `PRODUCT_BUNDLE_IDENTIFIER` in `project.pbxproj`, never a test,
  extension or widget target. If the project does not declare it, read `CFBundleIdentifier` from the
  app's `Info.plist`.
- **SwiftPM**: `CFBundleIdentifier` in the app `Info.plist` next to `Package.swift`.
- **Flutter**: the Android `applicationId` or iOS bundle id when the platform shells declare one;
  else the `name:` in `pubspec.yaml`.
- **React Native**: the Android `applicationId`, else the iOS bundle id, else the `name` in
  `package.json`.

A build file wins over a folder name. Never invent an app id for the report.

## Modules

`modules` lists the build's own modules or targets, app one first:

- **Gradle**: the included modules (`include(":app", ":core")` in `settings.gradle(.kts)`), as folder
  names: `app`, `core`.
- **Xcode**: the app scheme and its unit-test target.
- **SwiftPM**: the targets in `Package.swift`, e.g. `ShopIOS`, `ShopIOSTests`.
- **Flutter**: the Dart package name.
- **React Native**: the npm package name plus `android` and `ios`.

Extra modules may be listed; never omit the app module or a module whose code the stack needs.

## Test sources

- **Gradle Android unit tests**: the app module's `src/test/java` or `src/test/kotlin`; a debug-only source
  set `src/testDebug/...` also counts. `src/androidTest` needs a device and is not a v1 unit test.
- **Xcode**: a unit-test target in `project.pbxproj` (`com.apple.product-type.bundle.unit-test`) with
  sources under `Tests/` or `<App>Tests/`.
- **SwiftPM**: a `.testTarget` in `Package.swift`, sources under `Tests/`.
- **Flutter**: `test/` with at least one `*_test.dart` file.
- **React Native**: `__tests__/` or `test/`, with `*.test.js` / `*.spec.js` files inside.

`testable: true` only when at least one such test file exists and the test command is known.
Otherwise write `testable: false` and leave `test_command` empty: step 0 is done with
`testable: false`, and step 3 stops there with `NO_VERDICT` and a guide. Do not create a test source
set or a test target.

## Test command

One command, run from the app root:

- **Gradle**: `./gradlew :app:testDebugUnitTest`, with the module path from `settings.gradle(.kts)`.
  Product flavors rename the task: `:app:test<Flavor>DebugUnitTest`; confirm with
  `./gradlew :app:tasks --all`. Use `gradle` when the build has no wrapper. When the Gradle root is
  `android/` (React Native), run `cd android && ./gradlew :app:testDebugUnitTest`.
- **Xcode**: `xcodebuild test -workspace <workspace> -scheme <scheme> -destination 'platform=iOS
  Simulator,name=iPhone 16'`, or `-project <project>` when there is no workspace. Take the scheme
  from the shared schemes or `xcodebuild -list`. The simulator is only a test destination.
- **SwiftPM**: `swift test`. When the tests only build for iOS, use the package scheme with
  `xcodebuild test` and record that command instead.
- **Flutter**: `flutter test`; add one file to run only it: `flutter test test/cart_test.dart`.
- **React Native**: `npm test -- --runInBand`; or `npx jest --runInBand <file>`.

Do not add a test runner or a dependency to make the command work.

## Toolchain

Record the versions that are actually declared or installed; leave `toolchain` empty when unknown:

- **Gradle**: the wrapper version from `gradle/wrapper/gradle-wrapper.properties`, the Android
  Gradle plugin version from the build files, and the JDK from `org.gradle.java.home`,
  `sourceCompatibility`/`targetCompatibility`, or `java -version` when Java is installed. Example:
  `Gradle 8.9, JDK 17`.
- **Xcode / SwiftPM**: `xcodebuild -version` and `swift --version`; the Swift tools version from the
  first line of `Package.swift`.
- **Flutter**: `flutter --version`, an FVM pin (`.fvmrc` or `.fvm/fvm_config.json`), or an exact
  `environment: flutter:` in `pubspec.yaml`; when none pins a version, record the declared Dart SDK
  constraint, e.g. `Dart SDK ^3.12.2`.
- **React Native**: `node --version` and the Jest version from `package.json`, e.g.
  `Node >=20, Jest 29.7`.

Never install, upgrade or switch a toolchain without the user's yes.

## Test-only build changes

Production is off limits: never change production code, dependencies, production build configuration
or signing. Writing a test file in an existing test source set is not a build edit and needs no extra
permission. When the target does not discover new files itself (an Xcode unit-test target), adding the
file needs the user's explicit yes, recorded in `progress.md` and `report.md`.

If the target does not discover new files itself (an Xcode unit-test target), the minimal
`project.pbxproj` membership edit is the only build change allowed: add the one test file to the
existing test target, touch no production target, and record the edit. No yes: write `NO_VERDICT` and
a guide instead.

Creating a new test target or test source set is not part of v1: write `NO_VERDICT` and a guide. So is
an app with no test setup. Never add `src/main` files, edit a production target, change a dependency
block or re-sign the app.

## Running the test

Step 3 writes the test in the source set above, calling the real code with the reported input and
letting the exception escape. Run the command once, capture stdout and stderr to `raw/test.log`, and
copy any JUnit XML or `.ips` report under `raw/`. Record the test path, the command and `started_at` in
`attempts/NN/manifest.json`. Do not catch the exception, and do not mock the crashing function.

## Failure modes

- No app repository: tester path (v2), not a v1 run.
- No unit-test sources: `testable: false`; step 3 stops with `NO_VERDICT` and a guide.
- Xcode needs a project membership edit without the user's yes: `NO_VERDICT` and a guide.
- Several app modules or flavor dimensions: name the exact task from the build; ask when the command
  is still ambiguous.
- A required tool is missing: stop and ask the user to install it; never install it yourself.
- The stack ends in framework or generated code, or the app code is not in this checkout: stop at
  step 2; do not invent a different crash.

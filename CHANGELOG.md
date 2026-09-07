# Changelog

## 0.4.0
- Adopt Flutter's UIScene lifecycle on iOS. The plugin previously received deep links only through `UIApplicationDelegate` forwarding (`application:continueUserActivity:restorationHandler:` and `application:openURL:options:`). On recent Flutter versions this logs "Plugin FlutterUlinkSdkPlugin uses deprecated application lifecycle events", and on apps that adopt the UIScene lifecycle those callbacks are no longer delivered — so universal links and custom URL schemes would stop reaching the plugin.
  - The plugin now also conforms to `FlutterSceneLifeCycleDelegate`, registers via `registrar.addSceneDelegate(_:)` alongside `addApplicationDelegate(_:)`, and implements the scene equivalents of the application-delegate deep-link callbacks. Registering both keeps deep linking working on migrated and non-migrated apps.
    - Warm start (app already running): `scene(_:continue:)` for universal links and `scene(_:openURLContexts:)` for custom URL schemes, mirroring `application:continueUserActivity:` / `application:openURL:`.
    - Cold start (app launched by the link): a launch URL is delivered only in the scene's connection options, not re-delivered to the warm-start callbacks, so `scene(_:willConnectTo:options:)` drains `connectionOptions.userActivities` and `.urlContexts`. This preserves the launch-path deep link that the `UIApplicationDelegate` path covered and that 0.3.9 hardened against a cold-start crash.
  - This requires the scene-lifecycle plugin APIs added in Flutter 3.38.0, so the minimum constraints are raised to `flutter: ">=3.38.0"` and `sdk: ^3.10.0`. Apps on older Flutter are unaffected (they neither emit the warning nor expose the scene APIs) and can stay on 0.3.9.
  - Android is unaffected.

## 0.3.9
- Raise the pinned native iOS SDK to `ULinkSDK` 1.2.2, which fixes a crash when a deep link arrives before the SDK finishes initializing.
  - `ULink.shared` called `fatalError` when the SDK was not yet initialized, and iOS delivers the launch URL during a cold start before an async `initialize()` completes. A host that handled the URL through `shared` was killed on exactly the launch path deep links exist for.
  - 1.2.2 adds a static `ULink.handleIncomingURL(_:)` that buffers a URL arriving before initialization and replays it once initialization finishes, plus `ULink.isInitialized`. Hosts that reach the SDK through this plugin are unaffected either way; the bump matters for apps that also call the native SDK directly.
  - Unlike the 0.3.7 bump, the previous constraint did not block the new version: `~> 1.2.0` already resolves to `>= 1.2.0, < 1.3.0`. Raising the floor to `~> 1.2.2` stops a lockfile holding a host on 1.2.0 or 1.2.1 and missing the fix.
- Correct the Swift Package Manager comment, which still described the pin as `~> 1.1.1` after it had moved twice.
- Android is unaffected and its pin is unchanged.

## 0.3.8
- Fix an Android build failure on AGP 9 for apps that opt out of built-in Kotlin. The plugin decided whether to apply the Kotlin Gradle Plugin from the AGP major version, assuming AGP 9 always registers the `kotlin` extension via built-in Kotlin. An app that sets `android.builtInKotlin=false` in `android/gradle.properties` gets neither: the version check skips KGP, AGP registers nothing, and evaluating the plugin fails with `Could not find method kotlin() ... on project ':flutter_ulink_sdk'`. The plugin now checks for the extension itself and applies KGP only when it is absent. No change for apps on AGP 8, or on AGP 9 with built-in Kotlin left enabled.

## 0.3.7
- Bump the pinned native iOS SDK to `ULinkSDK` 1.2.0. Android is unaffected and its pin is unchanged.
  - Deep links are no longer lost on iOS when they arrive while the SDK is still starting up. A host launched by a universal link hands the link to the SDK moments after initialization begins, and link resolution rejected anything arriving before bootstrap finished — the error was swallowed into a log line, so the launch link was dropped silently.
  - A bootstrap that failed at cold start now always reaches a terminal state, so later links fail fast instead of waiting for a completion that never comes.
  - Note: the CocoaPods constraint was `~> 1.1.1`, which resolves to `>= 1.1.1, < 1.2.0` — iOS hosts could not pick up 1.2.0 until this bump.

## 0.3.6
- Bump pinned native Android SDK to `ly.ulink:ulink-sdk:1.2.0`. iOS is unaffected and its pin is unchanged.
  - Deep links are no longer lost when they arrive while the SDK is still starting up. A link that reached the SDK before bootstrap finished was rejected outright, and because the intent had already been marked as handled, nothing retried it — so cold starts launched by tapping a link, the most common case, dropped the link. Measured on a device: the intent was processed 0.9s after process start and bootstrap completed 2.2s later, with the listener never firing.
  - The same wait now applies to the deferred-link check, which is a once-per-install call — losing it to the startup race lost the install's attribution permanently.
  - A failure while the SDK was setting up could leave bootstrap in a non-terminal state, parking every later deep link for the life of the process.
  - Ending the SDK no longer reports its own shutdown as a deep-link failure, and no longer silently stops delivering entries to the log stream.
  - Disposing the SDK now actually ends the active session; the request was previously cancelled before it was ever sent.
  - Re-initialising after disposing now returns a working instance instead of the disposed one, whose background work silently did nothing.

## 0.3.5
- Bump pinned native Android SDK to `ly.ulink:ulink-sdk:1.1.4`, picking up three releases of Android-only fixes (1.1.2, 1.1.3, 1.1.4). iOS is unaffected and its pin is unchanged.
  - Dynamic links are no longer emitted twice when the app is already installed (1.1.2).
  - The deferred-match endpoint now honours the configured `baseUrl` instead of always calling `https://api.ulink.ly`; integrators pointing the SDK at a staging or self-hosted API were silently sending device fingerprints to production (1.1.3).
  - The "retry bootstrap on next foreground" recovery is now reachable. A failed bootstrap marks itself completed, and the retry was keyed off that flag, so a single transient network error at cold start left the SDK degraded for the whole process lifetime — no sessions, no deferred links (1.1.3).
  - Transient pre-send network failures (DNS resolution, connect, no route) are retried with exponential backoff instead of failing permanently on the first attempt. Failures that may already have reached the server, such as read timeouts, are deliberately not retried so sessions and installations cannot be duplicated (1.1.4).
  - The deferred-link check is no longer lost when the cold-start bootstrap fails: it is re-attempted once bootstrap recovers, serialized so overlapping foregrounds cannot consume two deferred clicks, and retried until the request actually completes (1.1.4).

## 0.3.4
- Bump pinned native Android SDK to `ly.ulink:ulink-sdk:1.1.1`, which fixes a client-version telemetry mismatch — the 1.1.0 artifact was sending `X-ULink-Client-Version: 1.0.11` on all backend calls (bootstrap, sessions/start, sessions/end, resolve, deferred match). Version header now reports the correct `1.1.1`. iOS was unaffected (already correct in 0.3.3).

## 0.3.3
- Bump pinned native iOS SDK to `ULinkSDK ~> 1.1.1`, which fixes iOS-only loss of appended query parameters during link resolution. On iOS the deep link was sent to `/sdk/resolve` with `&`/`=` left unencoded, so the server saw only the first appended parameter (e.g. `?app=poc&screen=product&id=123` resolved to just `{app: poc}`); every parameter after the first was dropped. Android was unaffected. Requires rebuilding the iOS app against the updated pod/SwiftPM dependency.

## 0.3.2
- Migrate the Android plugin to Flutter's Built-in Kotlin model: the plugin no longer applies the Kotlin Gradle Plugin (KGP) via its own buildscript classpath. KGP is now applied conditionally only on AGP < 9 (`apply plugin: "kotlin-android"`); on AGP 9+ Flutter's built-in Kotlin is used. This removes `flutter_ulink_sdk` from the "plugins that apply KGP" build warning and keeps it building on future Flutter releases. See https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
- Replace the deprecated `kotlinOptions { jvmTarget }` block with the `kotlin { compilerOptions { jvmTarget } }` DSL.
- Drop the unused `kotlinx-serialization` Kotlin compiler plugin. The plugin used no `@Serializable` types; only the `kotlinx-serialization-json` runtime API is used, which remains a dependency. No behavior change.

## 0.3.1
- Add Swift Package Manager support for the iOS plugin. The plugin now ships an `ios/flutter_ulink_sdk/Package.swift` alongside the existing CocoaPods podspec, so apps that have enabled Flutter's Swift Package Manager integration no longer warn that `flutter_ulink_sdk` lacks SPM support. CocoaPods consumers are unaffected — both build systems share the same source under `ios/flutter_ulink_sdk/Sources/`.

## 0.3.0
- Add optional `externalId` to `ULinkParameters` for idempotent link creation. Set a deterministic key (e.g. `share:user:123:post:456`) and repeat calls return the existing link instead of creating a duplicate. See https://docs.ulink.ly/create-links/idempotent-link-creation
- Forward `externalId` end-to-end through the Kotlin and Swift native bridges
- Bump pinned native SDKs to ULinkSDK ~> 1.1.0 (iOS) and ly.ulink:ulink-sdk:1.1.0 (Android)

## 0.2.19
- Bump Android SDK dependency to 1.0.11 — fixes Android main-thread freeze during `ULink.initialize()` on cold start with slow or unstable networks (#8). The native `initialize()` no longer wraps `setup()` in `runBlocking`; concurrent callers now serialize via a suspend-safe `Mutex` instead of a JVM monitor.

## 0.2.18
- Fix `ULinkParameters.name` being silently dropped by the Android and iOS bridges — link names now reach `/sdk/links` and appear correctly in the dashboard (#7)

## 0.2.17
- Fix Android deep link not processed when app is brought to foreground before SDK initialization completes
- Simplify release workflow: version must be set in pubspec.yaml before tagging

## 0.2.13
- Bump Android SDK dependency to 1.0.10 — fixes app crash when bootstrap fails due to DNS resolution errors (network failures are now non-fatal)

## 0.2.12
- Fix iOS deep link handling: replace broken method swizzling with Flutter's `addApplicationDelegate` API
- Fix EventChannel listener ordering: set up listeners before calling native `initialize` so logs emitted during SDK init are captured
- Add `debugPrint` bridge for native SDK logs so they appear in `flutter run` console
- Fix debug overlay overflow for long log messages
- Bump iOS SDK dependency to 1.0.8 (adds log replay buffer)

## 0.2.11
- Fix dart format CI issue from 0.2.10 release

## 0.2.10
- Fix platform channel threading violation: EventChannel messages now always dispatched on the main/platform thread (Android & iOS)
- Fix `onDetachedFromEngine` missing cleanup for log and reinstall event channels (Android)
- Fix `dispose()` not recreating coroutine scope, causing silent failures on re-initialization (Android)
- Add `sendError` to Android StreamHandler for parity with iOS
- Add `@Volatile` annotation to Android event sink for JVM memory visibility
- Add event channel tests for all 4 streams (logs, dynamic links, unified links, reinstall detection)

## 0.2.9
- Fix social media preview tags not being saved when creating links from iOS (key name mismatch in iOS Flutter plugin bridge)

## 0.2.8
- Bump iOS SDK dependency from 1.0.3 to 1.0.7

## 0.2.7
- Bump Android SDK dependency from 1.0.5 to 1.0.9 to fix compilation errors for reinstall detection APIs (`onReinstallDetected`, `getInstallationInfo`, `isReinstall`)

## 0.2.6
- Add optional `name` parameter to `ULinkParameters` for setting human-readable link names in the dashboard
- Supported in both `ULinkParameters.dynamic()` and `ULinkParameters.unified()` factory constructors

## 0.2.5
- Add GitHub Actions CI/CD workflows
- Automated pub.dev publishing with OIDC authentication
- Add CONTRIBUTING.md with release process documentation
- Fix README initialization code examples
- Add reinstall detection support (`getInstallationInfo()`, `isReinstall()`, `onReinstallDetected`)

## 0.2.4
- Bump version for new release
- Add ULinkInstallationInfo model support

## 0.2.3
- Add `ULinkDebugOverlay` widget for displaying SDK logs in a floating panel
- Add `onLog` stream for real-time SDK debug log access
- Add `ULinkLogEntry` model for structured log entries
- Debug overlay auto-hides in release mode (use `showInRelease: true` to override)
- Reference Android SDK 1.0.5 with full log streaming support

## 0.2.2
- reference Android SDK 1.0.5 and re-export shared models
- include latest Android manifest fixes

## 0.2.1
- pumped version for new release

## 0.2.0
- Change this package to be using native SDKS instead of InHouse implementation
- Updated dependencies to latest versions

## 0.1.14
- Added domain parameter to ULinkParameters factory constructors
## 0.1.13

- Updated factory constructors in `ULinkParameters`:
  - `ULinkParameters.dynamic(...)`: removed `metadata` parameter (use `socialMediaTags` for OG tags; other custom data should go in `parameters`).
  - `ULinkParameters.unified(...)`: now only accepts platform URLs and optional `socialMediaTags` (removed `parameters` and `metadata`).
- Note: If you previously passed `parameters`/`metadata` to `unified(...)`, migrate to dynamic links.

## 0.1.12

- fixes and improvements

## 0.1.11

- fixes and improvements

## 0.1.10

- version pump

## 0.1.9

- Enhanced security
- Some chores to enhance code quality and maintainability

## 0.1.8

- Add support for more configurations in ULinkConfig
- Widened some dependencies to allow for more flexibility in versions

## 0.1.7

- Chores to enhance code quality and maintainability

## 0.1.6

- Chores to enhance code quality and maintainability


## 0.1.5

- Chores to enhance code quality and maintainability

## 0.1.4

- Fixed issue with unified links and added getInitialLink method

## 0.1.3

- Changed dependecies

## 0.1.2

- changed package_info to package_info_plus

## 0.1.1

### Improvements

- Removed deepLink Field: Removed unused `deepLink` field from `ULinkParameters` class and all related documentation
- Factory Methods: Added `ULinkParameters.dynamic()` and `ULinkParameters.unified()` factory constructors for cleaner API
  - Improved type safety and developer experience
  - Better IDE support with parameter validation
  - More intuitive API for creating different link types

- Path Structure Update: Updated all examples and documentation to use slug on root path instead of `/d/slug` format
  - Updated link resolution examples to use direct slug paths
  - Simplified URL structure across all documentation
  - Updated test files to reflect new path format

### Documentation

- Updated README.md with factory method examples and benefits
- Updated UNIFIED_LINKS.md to use new factory constructors
- Added comprehensive documentation for factory method usage
- Updated all code examples to demonstrate cleaner API patterns

### Breaking Changes

- Removed `deepLink` field from `ULinkParameters` (was unused)
- Updated URL path structure from `/d/slug` to `/slug` format

## 0.1.0

### ✨ New Features

* **Metadata Support**: Added dedicated `metadata` field for social media data separation
  - Social media parameters (Open Graph, Twitter) are now automatically moved to a separate `metadata` field
  - Added `metadata` parameter to `ULinkParameters` for explicit social media data
  - Added `metadata` field to `ULinkResolvedData` for parsing API responses
  - Automatic detection and separation of social media parameters from regular parameters
  - Support for additional social media platforms (Twitter, OpenGraph extended properties)

### 🔧 Improvements

* **Better Data Organization**: Clear separation between business/tracking parameters and social media metadata
* **Backward Compatibility**: Existing code continues to work without modifications
* **Enhanced Social Media Tags**: Extended `SocialMediaTags` class now populates metadata instead of parameters
* **Auto-Migration**: Social media parameters in the `parameters` field are automatically moved to `metadata`

### 📚 Documentation

* Added comprehensive examples showing metadata usage patterns
* Added unit tests for metadata functionality
* Added demo script showing JSON structure changes
* Updated examples to demonstrate new metadata features

### 🗂️ Breaking Changes

* None - all changes are backward compatible

## 0.0.3

### Fixes

* Refactor ULink dynamic link handling;
* Remove redundant checks for dynamic links

## 0.0.2

* Added resolveLink method to retrieve original data from dynamic links
* Added ULinkResolvedData model for handling resolved link data
* Added automatic resolution of ULink format links (slug on root path) in link listeners
* Added comprehensive documentation for link resolution
* Added example for resolving links in example/test/link_resolve_test.dart

## 0.0.1

* Initial development release

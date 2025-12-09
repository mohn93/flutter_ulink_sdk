import 'dart:async';

import 'flutter_ulink_sdk_platform_interface.dart';
import 'models/models.dart';

export 'models/models.dart';
export 'widgets/ulink_debug_overlay.dart';

/// Flutter ULink Bridge SDK
///
/// This SDK provides a bridge between Flutter and the native ULink SDKs
/// for Android and iOS, enabling deep linking, session management, and
/// link creation/resolution capabilities.
class ULink {
  static ULink? _instance;

  /// Singleton instance of the SDK
  static ULink get instance {
    _instance ??= ULink._();
    return _instance!;
  }

  ULink._();

  /// Initializes the ULink SDK with the provided configuration
  ///
  /// [config] - Configuration object containing API key and other settings
  Future<void> initialize(ULinkConfig config) async {
    await FlutterUlinkSdkPlatform.instance.initialize(config);
  }

  /// Checks for deferred deep links on first launch
  Future<void> checkDeferredLink() async {
    try {
      // Delegate to native SDKs for consistent fingerprinting and matching logic
      await FlutterUlinkSdkPlatform.instance.checkDeferredLink();
    } catch (e) {
      print('ULink: Error checking deferred link: $e');
    }
  }

  /// Creates a new ULink with the specified parameters
  ///
  /// [parameters] - Link parameters including type, URLs, and metadata
  /// Returns a ULinkResponse containing success status, URL, error, and data
  Future<ULinkResponse> createLink(ULinkParameters parameters) {
    return FlutterUlinkSdkPlatform.instance.createLink(parameters);
  }

  /// Resolves a ULink URL to extract its data
  ///
  /// [url] - The ULink URL to resolve
  /// Returns a ULinkResponse containing success status, URL, error, and resolved data
  Future<ULinkResponse> resolveLink(String url) {
    return FlutterUlinkSdkPlatform.instance.resolveLink(url);
  }

  /// Ends the current session
  Future<void> endSession() {
    return FlutterUlinkSdkPlatform.instance.endSession();
  }

  /// Gets the current session ID
  ///
  /// Returns the session ID if a session is active, null otherwise
  Future<String?> getCurrentSessionId() {
    return FlutterUlinkSdkPlatform.instance.getCurrentSessionId();
  }

  /// Checks if there is an active session
  ///
  /// Returns true if a session is active, false otherwise
  Future<bool> hasActiveSession() {
    return FlutterUlinkSdkPlatform.instance.hasActiveSession();
  }

  /// Gets the current session state
  ///
  /// Returns the current session state
  Future<SessionState> getSessionState() {
    return FlutterUlinkSdkPlatform.instance.getSessionState();
  }

  /// Checks if a session is currently being initialized
  ///
  /// Returns true if session initialization is in progress, false otherwise
  Future<bool> get isSessionInitializing async {
    final state = await getSessionState();
    return state == SessionState.initializing;
  }

  /// Process a URI and resolve ULink data by querying the server
  ///
  /// This method is used by external components to process URIs without triggering streams.
  /// Returns null if the URI cannot be resolved or is not a ULink.
  ///
  /// [uri] - The URI to process
  /// Returns the resolved ULink data or null
  Future<ULinkResolvedData?> processULinkUri(Uri uri) async {
    final response = await resolveLink(uri.toString());
    if (response.success && response.data != null) {
      return ULinkResolvedData.fromJson(response.data!);
    }
    return null;
  }

  /// Sets the initial URI for the app launch
  ///
  /// [uri] - The initial URI to set
  Future<void> setInitialUri(String uri) {
    return FlutterUlinkSdkPlatform.instance.setInitialUri(uri);
  }

  /// Gets the initial URI that launched the app
  ///
  /// Returns the initial URI or null if not available
  Future<Uri?> getInitialUri() async {
    final uriString = await FlutterUlinkSdkPlatform.instance.getInitialUri();
    if (uriString != null && uriString.isNotEmpty) {
      try {
        return Uri.parse(uriString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Gets the initial deep link data that launched the app
  ///
  /// Returns the initial deep link data or null if not available
  Future<ULinkResolvedData?> getInitialDeepLink() {
    return FlutterUlinkSdkPlatform.instance.getInitialDeepLink();
  }

  /// Gets the last link data that was processed
  ///
  /// Returns the last link data or null if not available
  Future<ULinkResolvedData?> getLastLinkData() {
    return FlutterUlinkSdkPlatform.instance.getLastLinkData();
  }

  /// Gets the installation ID for this app installation
  ///
  /// Returns the installation ID or null if not available
  Future<String?> getInstallationId() {
    return FlutterUlinkSdkPlatform.instance.getInstallationId();
  }

  /// Gets the current installation info including reinstall detection data.
  ///
  /// If this is a reinstall, the returned object will have isReinstall=true
  /// and previousInstallationId will contain the ID of the previous installation.
  ///
  /// Returns ULinkInstallationInfo or null if bootstrap hasn't completed
  Future<ULinkInstallationInfo?> getInstallationInfo() {
    return FlutterUlinkSdkPlatform.instance.getInstallationInfo();
  }

  /// Checks if the current installation is a reinstall.
  ///
  /// Returns true if this installation was detected as a reinstall
  Future<bool> isReinstall() {
    return FlutterUlinkSdkPlatform.instance.isReinstall();
  }

  /// Disposes of the SDK and cleans up resources
  Future<void> dispose() {
    return FlutterUlinkSdkPlatform.instance.dispose();
  }

  /// Stream of dynamic link events
  ///
  /// Listen to this stream to receive dynamic link data when links are opened
  Stream<ULinkResolvedData> get onDynamicLink {
    return FlutterUlinkSdkPlatform.instance.onDynamicLink;
  }

  /// Alias for onDynamicLink (backward compatibility with flutter_ulink_sdk)
  ///
  /// This provides the same API as flutter_ulink_sdk for easier migration
  Stream<ULinkResolvedData> get onLink => onDynamicLink;

  /// Stream of unified link events
  ///
  /// Listen to this stream to receive unified link data when links are opened
  Stream<ULinkResolvedData> get onUnifiedLink {
    return FlutterUlinkSdkPlatform.instance.onUnifiedLink;
  }

  /// Stream of SDK log entries for debugging
  ///
  /// Listen to this stream to receive log messages from the native SDK.
  /// Only emits when debug mode is enabled in ULinkConfig.
  Stream<ULinkLogEntry> get onLog {
    return FlutterUlinkSdkPlatform.instance.onLog;
  }

  /// Stream of reinstall detection events.
  ///
  /// Listen to this stream to receive notifications when a reinstall is detected
  /// during bootstrap. The emitted ULinkInstallationInfo contains details about
  /// the reinstall, including the previous installation ID.
  Stream<ULinkInstallationInfo> get onReinstallDetected {
    return FlutterUlinkSdkPlatform.instance.onReinstallDetected;
  }
}

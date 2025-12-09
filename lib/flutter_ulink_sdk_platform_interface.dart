import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_ulink_sdk_method_channel.dart';
import 'models/models.dart';

abstract class FlutterUlinkSdkPlatform extends PlatformInterface {
  /// Constructs a FlutterUlinkSdkPlatform.
  FlutterUlinkSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterUlinkSdkPlatform _instance =
      MethodChannelFlutterUlinkSdk();

  /// The default instance of [FlutterUlinkSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterUlinkSdk].
  static FlutterUlinkSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterUlinkSdkPlatform] when
  /// they register themselves.
  static set instance(FlutterUlinkSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Core SDK methods
  Future<void> initialize(ULinkConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<ULinkResponse> createLink(ULinkParameters parameters) {
    throw UnimplementedError('createLink() has not been implemented.');
  }

  Future<ULinkResponse> resolveLink(String url) {
    throw UnimplementedError('resolveLink() has not been implemented.');
  }

  // Session management
  Future<void> endSession() {
    throw UnimplementedError('endSession() has not been implemented.');
  }

  Future<String?> getCurrentSessionId() {
    throw UnimplementedError('getCurrentSessionId() has not been implemented.');
  }

  Future<bool> hasActiveSession() {
    throw UnimplementedError('hasActiveSession() has not been implemented.');
  }

  Future<SessionState> getSessionState() {
    throw UnimplementedError('getSessionState() has not been implemented.');
  }

  // Deep link handling
  Future<void> setInitialUri(String uri) {
    throw UnimplementedError('setInitialUri() has not been implemented.');
  }

  Future<String?> getInitialUri() {
    throw UnimplementedError('getInitialUri() has not been implemented.');
  }

  Future<ULinkResolvedData?> getInitialDeepLink() {
    throw UnimplementedError('getInitialDeepLink() has not been implemented.');
  }

  Future<ULinkResolvedData?> getLastLinkData() {
    throw UnimplementedError('getLastLinkData() has not been implemented.');
  }

  // Installation tracking
  Future<String?> getInstallationId() {
    throw UnimplementedError('getInstallationId() has not been implemented.');
  }

  /// Gets the current installation info including reinstall detection data.
  ///
  /// If this is a reinstall, the returned object will have isReinstall=true
  /// and previousInstallationId will contain the ID of the previous installation.
  Future<ULinkInstallationInfo?> getInstallationInfo() {
    throw UnimplementedError('getInstallationInfo() has not been implemented.');
  }

  /// Checks if the current installation is a reinstall.
  Future<bool> isReinstall() {
    throw UnimplementedError('isReinstall() has not been implemented.');
  }

  // Deferred Deep Linking
  Future<void> checkDeferredLink() {
    throw UnimplementedError('checkDeferredLink() has not been implemented.');
  }

  // Cleanup
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  // Stream handlers
  Stream<ULinkResolvedData> get dynamicLinkStream {
    throw UnimplementedError('dynamicLinkStream has not been implemented.');
  }

  Stream<ULinkResolvedData> get unifiedLinkStream {
    throw UnimplementedError('unifiedLinkStream has not been implemented.');
  }

  Stream<ULinkResolvedData> get onDynamicLink {
    throw UnimplementedError('onDynamicLink has not been implemented.');
  }

  Stream<ULinkResolvedData> get onUnifiedLink {
    throw UnimplementedError('onUnifiedLink has not been implemented.');
  }

  /// Stream of log entries for debugging
  Stream<ULinkLogEntry> get onLog {
    throw UnimplementedError('onLog has not been implemented.');
  }

  /// Stream of reinstall detection events.
  /// Emits ULinkInstallationInfo when a reinstall is detected during bootstrap.
  Stream<ULinkInstallationInfo> get onReinstallDetected {
    throw UnimplementedError('onReinstallDetected has not been implemented.');
  }
}

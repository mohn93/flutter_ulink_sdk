import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/models/models.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Test utilities and helper methods for ULink Bridge SDK testing
class ULinkTestUtilities {
  /// Mock ULink configuration for testing
  static ULinkConfig get mockConfig => ULinkConfig(
    apiKey: 'test_api_key_123',
    baseUrl: 'https://test-api.ulink.io',
    debug: true,
    enableDeepLinkIntegration: true,
    enableAnalytics: false,
    enableCrashReporting: false,
    timeout: 5000,
    retryCount: 2,
    metadata: {'test': 'true', 'environment': 'testing'},
  );

  /// Mock ULink parameters for dynamic links
  static ULinkParameters get mockDynamicParameters => ULinkParameters.dynamic(
    domain: 'example.com',
    slug: 'test-dynamic-link',
    iosFallbackUrl: 'https://apps.apple.com/app/test',
    androidFallbackUrl:
        'https://play.google.com/store/apps/details?id=com.test',
    fallbackUrl: 'https://test.com/fallback',
    parameters: {'utm_source': 'test', 'utm_campaign': 'testing'},
    socialMediaTags: SocialMediaTags(
      ogTitle: 'Test Dynamic Link',
      ogDescription: 'This is a test dynamic link for testing purposes',
      ogImage: 'https://test.com/image.png',
    ),
  );

  /// Mock ULink parameters for unified links
  static ULinkParameters get mockUnifiedParameters => ULinkParameters.unified(
    domain: 'example.com',
    slug: 'test-unified-link',
    iosUrl: 'https://apps.apple.com/app/test',
    androidUrl: 'https://play.google.com/store/apps/details?id=com.test',
    fallbackUrl: 'https://test.com/fallback',
    parameters: {'utm_source': 'test', 'utm_medium': 'unified'},
    socialMediaTags: SocialMediaTags(
      ogTitle: 'Test Unified Link',
      ogDescription: 'This is a test unified link for testing purposes',
      ogImage: 'https://test.com/unified-image.png',
    ),
  );

  /// Mock resolved data for testing
  static ULinkResolvedData get mockResolvedData => ULinkResolvedData(
    slug: 'test-resolved-link',
    iosFallbackUrl: 'https://apps.apple.com/app/test',
    androidFallbackUrl:
        'https://play.google.com/store/apps/details?id=com.test',
    fallbackUrl: 'https://test.com/fallback',
    parameters: {'utm_source': 'resolved', 'utm_campaign': 'test'},
    socialMediaTags: SocialMediaTags(
      ogTitle: 'Resolved Test Link',
      ogDescription: 'This is a resolved test link',
      ogImage: 'https://test.com/resolved-image.png',
    ),
    metadata: {'resolved': 'true'},
    linkType: ULinkType.dynamic,
    rawData: {'raw_test': 'data'},
  );

  /// Generate test URLs for different scenarios
  static List<String> get testUrls => [
    'https://test.ulink.ly/abc123',
    'https://test.ulink.ly/xyz789?param=value',
    'https://custom.domain.com/link/test',
    'ulink://test.app/deep/link?data=test',
    'https://test.com/share?ulink=abc123',
  ];

  /// Generate test session IDs
  static List<String> get testSessionIds => [
    'session_123456789',
    'test_session_abc',
    'mock_session_xyz',
    'debug_session_001',
  ];

  /// Generate test installation IDs
  static List<String> get testInstallationIds => [
    'install_123456789',
    'test_install_abc',
    'mock_install_xyz',
    'debug_install_001',
  ];

  /// Create a test configuration with custom parameters
  static ULinkConfig createTestConfig({
    String? apiKey,
    String? baseUrl,
    bool? debug,
    bool? enableDeepLinkIntegration,
    bool? enableAnalytics,
    bool? enableCrashReporting,
    int? timeout,
    int? retryCount,
    Map<String, String>? metadata,
  }) {
    return ULinkConfig(
      apiKey: apiKey ?? 'test_api_key',
      baseUrl: baseUrl ?? 'https://test-api.ulink.io',
      debug: debug ?? true,
      enableDeepLinkIntegration: enableDeepLinkIntegration ?? true,
      enableAnalytics: enableAnalytics ?? false,
      enableCrashReporting: enableCrashReporting ?? false,
      timeout: timeout ?? 5000,
      retryCount: retryCount ?? 2,
      metadata: metadata ?? {'test': 'true'},
    );
  }

  /// Create test parameters with custom values
  static ULinkParameters createTestParameters({
    String? type,
    String? slug,
    String? iosUrl,
    String? androidUrl,
    String? iosFallbackUrl,
    String? androidFallbackUrl,
    String? fallbackUrl,
    Map<String, dynamic>? parameters,
    SocialMediaTags? socialMediaTags,
    Map<String, dynamic>? metadata,
  }) {
    if (type == 'unified') {
      return ULinkParameters.unified(
        domain: 'example.com',
        slug: slug ?? 'test-slug',
        iosUrl: iosUrl ?? 'https://apps.apple.com/app/test',
        androidUrl:
            androidUrl ??
            'https://play.google.com/store/apps/details?id=com.test',
        fallbackUrl: fallbackUrl ?? 'https://test.com/fallback',
        parameters: parameters ?? {'test': 'true'},
        socialMediaTags:
            socialMediaTags ??
            SocialMediaTags(
              ogTitle: 'Test Link',
              ogDescription: 'Test description',
              ogImage: 'https://test.com/image.png',
            ),
      );
    } else {
      return ULinkParameters.dynamic(
        domain: 'example.com',
        slug: slug ?? 'test-slug',
        iosFallbackUrl: iosFallbackUrl ?? 'https://apps.apple.com/app/test',
        androidFallbackUrl:
            androidFallbackUrl ??
            'https://play.google.com/store/apps/details?id=com.test',
        fallbackUrl: fallbackUrl ?? 'https://test.com/fallback',
        parameters: parameters ?? {'test': 'true'},
        socialMediaTags:
            socialMediaTags ??
            SocialMediaTags(
              ogTitle: 'Test Link',
              ogDescription: 'Test description',
              ogImage: 'https://test.com/image.png',
            ),
      );
    }
  }

  /// Create test resolved data with custom values
  static ULinkResolvedData createTestResolvedData({
    String? slug,
    String? iosFallbackUrl,
    String? androidFallbackUrl,
    String? fallbackUrl,
    Map<String, dynamic>? parameters,
    SocialMediaTags? socialMediaTags,
    Map<String, dynamic>? metadata,
    ULinkType? linkType,
    Map<String, dynamic>? rawData,
  }) {
    return ULinkResolvedData(
      slug: slug ?? 'test-resolved',
      iosFallbackUrl: iosFallbackUrl ?? 'https://apps.apple.com/app/test',
      androidFallbackUrl:
          androidFallbackUrl ??
          'https://play.google.com/store/apps/details?id=com.test',
      fallbackUrl: fallbackUrl ?? 'https://test.com/fallback',
      parameters: parameters ?? {'resolved': 'true'},
      socialMediaTags:
          socialMediaTags ??
          SocialMediaTags(
            ogTitle: 'Resolved Link',
            ogDescription: 'Resolved description',
            ogImage: 'https://test.com/resolved.png',
          ),
      metadata: metadata ?? {'resolved_meta': 'true'},
      linkType: linkType ?? ULinkType.dynamic,
      rawData: rawData ?? {'raw': 'test_data'},
    );
  }

  /// Verify that a ULinkConfig has expected values
  static void verifyConfig(
    ULinkConfig config, {
    String? expectedApiKey,
    String? expectedBaseUrl,
    bool? expectedDebug,
    bool? expectedDeepLinkIntegration,
    bool? expectedAnalytics,
    bool? expectedCrashReporting,
    int? expectedTimeout,
    int? expectedRetryCount,
  }) {
    if (expectedApiKey != null) {
      expect(config.apiKey, expectedApiKey, reason: 'API key should match');
    }
    if (expectedBaseUrl != null) {
      expect(config.baseUrl, expectedBaseUrl, reason: 'Base URL should match');
    }
    if (expectedDebug != null) {
      expect(config.debug, expectedDebug, reason: 'Debug flag should match');
    }
    if (expectedDeepLinkIntegration != null) {
      expect(
        config.enableDeepLinkIntegration,
        expectedDeepLinkIntegration,
        reason: 'Deep link integration flag should match',
      );
    }
    if (expectedAnalytics != null) {
      expect(
        config.enableAnalytics,
        expectedAnalytics,
        reason: 'Analytics flag should match',
      );
    }
    if (expectedCrashReporting != null) {
      expect(
        config.enableCrashReporting,
        expectedCrashReporting,
        reason: 'Crash reporting flag should match',
      );
    }
    if (expectedTimeout != null) {
      expect(config.timeout, expectedTimeout, reason: 'Timeout should match');
    }
    if (expectedRetryCount != null) {
      expect(
        config.retryCount,
        expectedRetryCount,
        reason: 'Retry count should match',
      );
    }
  }

  /// Verify that ULinkParameters have expected values
  static void verifyParameters(
    ULinkParameters parameters, {
    String? expectedType,
    String? expectedSlug,
    String? expectedIosUrl,
    String? expectedAndroidUrl,
    String? expectedFallbackUrl,
    Map<String, dynamic>? expectedParameters,
    SocialMediaTags? expectedSocialMediaTags,
  }) {
    if (expectedType != null) {
      expect(parameters.type, expectedType, reason: 'Type should match');
    }
    if (expectedSlug != null) {
      expect(parameters.slug, expectedSlug, reason: 'Slug should match');
    }
    if (expectedIosUrl != null) {
      expect(parameters.iosUrl, expectedIosUrl, reason: 'iOS URL should match');
    }
    if (expectedAndroidUrl != null) {
      expect(
        parameters.androidUrl,
        expectedAndroidUrl,
        reason: 'Android URL should match',
      );
    }
    if (expectedFallbackUrl != null) {
      expect(
        parameters.fallbackUrl,
        expectedFallbackUrl,
        reason: 'Fallback URL should match',
      );
    }
    if (expectedParameters != null) {
      expect(
        parameters.parameters,
        expectedParameters,
        reason: 'Parameters should match',
      );
    }
    if (expectedSocialMediaTags != null) {
      expect(
        parameters.socialMediaTags,
        expectedSocialMediaTags,
        reason: 'Social media tags should match',
      );
    }
  }

  /// Verify that ULinkResolvedData has expected values
  static void verifyResolvedData(
    ULinkResolvedData resolvedData, {
    String? expectedSlug,
    String? expectedIosFallbackUrl,
    String? expectedAndroidFallbackUrl,
    String? expectedFallbackUrl,
    Map<String, dynamic>? expectedParameters,
    ULinkType? expectedLinkType,
  }) {
    if (expectedSlug != null) {
      expect(resolvedData.slug, expectedSlug, reason: 'Slug should match');
    }
    if (expectedIosFallbackUrl != null) {
      expect(
        resolvedData.iosFallbackUrl,
        expectedIosFallbackUrl,
        reason: 'iOS fallback URL should match',
      );
    }
    if (expectedAndroidFallbackUrl != null) {
      expect(
        resolvedData.androidFallbackUrl,
        expectedAndroidFallbackUrl,
        reason: 'Android fallback URL should match',
      );
    }
    if (expectedFallbackUrl != null) {
      expect(
        resolvedData.fallbackUrl,
        expectedFallbackUrl,
        reason: 'Fallback URL should match',
      );
    }
    if (expectedParameters != null) {
      expect(
        resolvedData.parameters,
        expectedParameters,
        reason: 'Parameters should match',
      );
    }
    if (expectedLinkType != null) {
      expect(
        resolvedData.linkType,
        expectedLinkType,
        reason: 'Link type should match',
      );
    }
  }

  /// Test helper to verify URL format
  static void verifyUrlFormat(String url, {bool shouldBeHttps = true}) {
    expect(url, isNotEmpty, reason: 'URL should not be empty');
    if (shouldBeHttps) {
      expect(url, startsWith('https://'), reason: 'URL should use HTTPS');
    }
    expect(Uri.tryParse(url), isNotNull, reason: 'URL should be valid');
  }

  /// Test helper to verify session ID format
  static void verifySessionIdFormat(String sessionId) {
    expect(sessionId, isNotEmpty, reason: 'Session ID should not be empty');
    expect(
      sessionId.length,
      greaterThan(5),
      reason: 'Session ID should be meaningful length',
    );
  }

  /// Test helper to verify installation ID format
  static void verifyInstallationIdFormat(String installationId) {
    expect(
      installationId,
      isNotEmpty,
      reason: 'Installation ID should not be empty',
    );
    expect(
      installationId.length,
      greaterThan(5),
      reason: 'Installation ID should be meaningful length',
    );
  }
}

/// Enhanced mock platform for comprehensive testing
class EnhancedMockFlutterUlinkSdkPlatform
    with MockPlatformInterfaceMixin
    implements FlutterUlinkSdkPlatform {
  bool _isInitialized = false;
  String? _currentSessionId;
  SessionState _sessionState = SessionState.idle;
  ULinkResolvedData? _lastLinkData;
  String? _initialUri;
  final String _installationId = 'test_installation_123';
  final List<String> _createdLinks = [];
  final List<ULinkResolvedData> _resolvedLinks = [];

  // Test configuration
  bool shouldThrowErrors = false;
  Duration? simulatedDelay;
  Map<String, dynamic> customResponses = {};

  // Getters for test verification
  bool get isInitialized => _isInitialized;
  List<String> get createdLinks => List.unmodifiable(_createdLinks);
  List<ULinkResolvedData> get resolvedLinks =>
      List.unmodifiable(_resolvedLinks);

  @override
  Future<void> initialize(ULinkConfig config) async {
    await _simulateDelay();
    if (shouldThrowErrors) {
      throw Exception('Mock initialization error');
    }
    _isInitialized = true;
  }

  @override
  Future<ULinkResponse> createLink(ULinkParameters parameters) async {
    await _simulateDelay();
    if (shouldThrowErrors) {
      throw Exception('Mock create link error');
    }
    if (!_isInitialized) {
      throw Exception('ULink not initialized');
    }

    final url =
        customResponses['createLink'] as String? ??
        'https://test.ulink.ly/${parameters.slug ?? 'generated'}';
    _createdLinks.add(url);
    return ULinkResponse.success(url, {'slug': parameters.slug});
  }

  @override
  Future<ULinkResponse> resolveLink(String url) async {
    await _simulateDelay();
    if (shouldThrowErrors) {
      throw Exception('Mock resolve link error');
    }
    if (!_isInitialized) {
      throw Exception('ULink not initialized');
    }

    final resolvedData =
        customResponses['resolveLink'] as ULinkResolvedData? ??
        ULinkTestUtilities.mockResolvedData;
    if (resolvedData != null) {
      _resolvedLinks.add(resolvedData);
      _lastLinkData = resolvedData;
      return ULinkResponse.success(url, resolvedData.rawData);
    }
    return ULinkResponse.error('Link not found');
  }

  @override
  Future<void> endSession() async {
    await _simulateDelay();
    if (shouldThrowErrors) {
      throw Exception('Mock end session error');
    }
    if (!_isInitialized) {
      throw Exception('ULink not initialized');
    }

    _currentSessionId = null;
    _sessionState = SessionState.idle;
  }

  @override
  Future<String?> getCurrentSessionId() async {
    await _simulateDelay();
    if (!_isInitialized) {
      throw Exception('ULink not initialized');
    }
    return _currentSessionId;
  }

  @override
  Future<bool> hasActiveSession() async {
    await _simulateDelay();
    if (!_isInitialized) {
      throw Exception('ULink not initialized');
    }
    return _currentSessionId != null && _sessionState == SessionState.active;
  }

  @override
  Future<SessionState> getSessionState() async {
    await _simulateDelay();
    if (!_isInitialized) {
      throw Exception('ULink not initialized');
    }
    return _sessionState;
  }

  @override
  Future<void> setInitialUri(String uri) async {
    await _simulateDelay();
    if (!_isInitialized) {
      throw Exception('ULink not initialized');
    }
    _initialUri = uri;
  }

  @override
  Future<String?> getInitialUri() async {
    await _simulateDelay();
    if (!_isInitialized) {
      throw Exception('ULink not initialized');
    }
    return _initialUri;
  }

  @override
  Future<ULinkResolvedData?> getInitialDeepLink() async {
    await _simulateDelay();
    if (!_isInitialized) {
      throw Exception('ULink not initialized');
    }
    if (_initialUri != null) {
      final response = await resolveLink(_initialUri!);
      if (response.success && response.data != null) {
        return ULinkResolvedData.fromJson(response.data!);
      }
    }
    return null;
  }

  @override
  Future<ULinkResolvedData?> getLastLinkData() async {
    await _simulateDelay();
    if (!_isInitialized) {
      throw Exception('ULink not initialized');
    }
    return _lastLinkData;
  }

  @override
  Future<String?> getInstallationId() async {
    await _simulateDelay();
    if (!_isInitialized) {
      throw Exception('ULink not initialized');
    }
    return _installationId;
  }

  @override
  Future<void> dispose() async {
    await _simulateDelay();
    _isInitialized = false;
    _currentSessionId = null;
    _sessionState = SessionState.idle;
    _lastLinkData = null;
    _initialUri = null;
    _createdLinks.clear();
    _resolvedLinks.clear();
  }

  @override
  Stream<ULinkResolvedData> get onDynamicLink => Stream.empty();

  @override
  Stream<ULinkResolvedData> get onUnifiedLink => Stream.empty();

  @override
  Stream<ULinkResolvedData> get dynamicLinkStream => Stream.empty();

  @override
  Stream<ULinkResolvedData> get unifiedLinkStream => Stream.empty();

  // Test helper methods
  void reset() {
    _isInitialized = false;
    _currentSessionId = null;
    _sessionState = SessionState.idle;
    _lastLinkData = null;
    _initialUri = null;
    _createdLinks.clear();
    _resolvedLinks.clear();
    shouldThrowErrors = false;
    simulatedDelay = null;
    customResponses.clear();
  }

  void setCustomResponse(String method, dynamic response) {
    customResponses[method] = response;
  }

  Future<void> _simulateDelay() async {
    if (simulatedDelay != null) {
      await Future.delayed(simulatedDelay!);
    }
  }
}

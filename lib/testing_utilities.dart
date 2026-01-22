import 'package:flutter/foundation.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

/// Testing utilities for the ULink Bridge SDK.
///
/// This class provides helper methods and utilities for testing ULink
/// functionality in your Flutter applications.
class ULinkTestingUtilities {
  /// Whether debug mode is enabled for testing utilities.
  static bool debugMode = false;

  /// Creates a mock ULinkResolvedData for testing
  static ULinkResolvedData createMockResolvedData({
    String? slug = 'test-slug',
    String? iosFallbackUrl = 'https://apps.apple.com/app/test',
    String? androidFallbackUrl =
        'https://play.google.com/store/apps/details?id=com.test',
    String? fallbackUrl = 'https://test.com',
    Map<String, dynamic>? parameters = const {'param1': 'value1'},
    SocialMediaTags? socialMediaTags,
    Map<String, dynamic>? metadata = const {'meta1': 'value1'},
    ULinkType linkType = ULinkType.dynamic,
    Map<String, dynamic>? rawData,
  }) {
    return ULinkResolvedData(
      slug: slug ?? 'test-slug',
      iosFallbackUrl: iosFallbackUrl,
      androidFallbackUrl: androidFallbackUrl,
      fallbackUrl: fallbackUrl,
      parameters: parameters,
      socialMediaTags: socialMediaTags,
      metadata: metadata,
      linkType: linkType,
      rawData: rawData ?? {},
    );
  }

  /// Creates a mock ULinkConfig for testing
  static ULinkConfig createMockConfig({
    String apiKey = 'test-api-key',
    String baseUrl = 'https://api.test.com',
    bool debug = true,
    bool persistLastLinkData = false,
    Duration? lastLinkTimeToLive,
    bool clearLastLinkOnRead = true,
    bool redactAllParametersInLastLink = false,
    List<String> redactedParameterKeysInLastLink = const [],
    bool enableDeepLinkIntegration = true,
    bool enableAnalytics = false,
    bool enableCrashReporting = false,
    int timeout = 5000,
    int retryCount = 1,
    Map<String, dynamic>? metadata,
  }) {
    return ULinkConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      debug: debug,
      persistLastLinkData: persistLastLinkData,
      lastLinkTimeToLive: lastLinkTimeToLive,
      clearLastLinkOnRead: clearLastLinkOnRead,
      redactAllParametersInLastLink: redactAllParametersInLastLink,
      redactedParameterKeysInLastLink: redactedParameterKeysInLastLink,
      enableDeepLinkIntegration: enableDeepLinkIntegration,
      enableAnalytics: enableAnalytics,
      enableCrashReporting: enableCrashReporting,
      timeout: timeout,
      retryCount: retryCount,
      metadata: metadata,
    );
  }

  /// Creates a mock ULinkParameters for testing
  static ULinkParameters createMockParameters({
    String type = 'dynamic',
    String domain = 'test.com',
    String? slug = 'test-slug',
    String? iosUrl,
    String? androidUrl,
    String? iosFallbackUrl = 'https://apps.apple.com/app/test',
    String? androidFallbackUrl =
        'https://play.google.com/store/apps/details?id=com.test',
    String? fallbackUrl = 'https://test.com',
    Map<String, dynamic>? parameters = const {'param1': 'value1'},
    SocialMediaTags? socialMediaTags,
    Map<String, dynamic>? metadata,
  }) {
    return ULinkParameters(
      domain: domain,
      type: type,
      slug: slug,
      iosUrl: iosUrl,
      androidUrl: androidUrl,
      iosFallbackUrl: iosFallbackUrl,
      androidFallbackUrl: androidFallbackUrl,
      fallbackUrl: fallbackUrl,
      parameters: parameters,
      socialMediaTags: socialMediaTags,
      metadata: metadata,
    );
  }

  /// Creates a mock SocialMediaTags for testing
  static SocialMediaTags createMockSocialMediaTags({
    String? ogTitle = 'Test Title',
    String? ogDescription = 'Test Description',
    String? ogImage = 'https://test.com/image.jpg',
  }) {
    return SocialMediaTags(
      ogTitle: ogTitle,
      ogDescription: ogDescription,
      ogImage: ogImage,
    );
  }

  /// Simulates a deep link event for testing.
  ///
  /// This method can be used to test deep link handling without
  /// actually opening a deep link.
  ///
  /// [url] - The deep link URL to simulate
  /// [resolvedData] - Optional resolved data to return
  static Future<ULinkResolvedData?> simulateDeepLink(
    String url, {
    ULinkResolvedData? resolvedData,
  }) async {
    _log('Simulating deep link: $url');

    if (resolvedData != null) {
      _log('Returning provided resolved data');
      return resolvedData;
    }

    // Create mock resolved data based on URL
    final uri = Uri.parse(url);
    final slug = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;

    return createMockResolvedData(
      slug: slug ?? 'unknown-slug',
      parameters: uri.queryParameters,
      fallbackUrl: url,
    );
  }

  /// Tests the link listener functionality.
  ///
  /// This method simulates the testListener functionality from the old SDK.
  ///
  /// [testUrl] - The URL to test with
  static Future<bool> testLinkListener(String testUrl) async {
    try {
      _log('Testing link listener with URL: $testUrl');

      // Process the URI to get resolved data
      final uri = Uri.parse(testUrl);
      final result = await ULink.instance.processULinkUri(uri);

      if (result != null) {
        _log('Link listener test successful: ${result.slug}');
        return true;
      } else {
        _log('Link listener test failed: no result returned');
        return false;
      }
    } catch (e) {
      _log('Link listener test failed with error: $e');
      return false;
    }
  }

  /// Validates a ULinkConfig object.
  ///
  /// [config] - The config to validate
  /// Returns true if the config is valid, false otherwise
  static bool validateConfig(ULinkConfig config) {
    if (config.apiKey.isEmpty) {
      _log('Config validation failed: API key is empty');
      return false;
    }

    if (config.baseUrl.isEmpty) {
      _log('Config validation failed: Base URL is empty');
      return false;
    }

    try {
      Uri.parse(config.baseUrl);
    } catch (e) {
      _log('Config validation failed: Invalid base URL format');
      return false;
    }

    _log('Config validation successful');
    return true;
  }

  /// Validates ULinkParameters object.
  ///
  /// [parameters] - The parameters to validate
  /// Returns true if the parameters are valid, false otherwise
  static bool validateParameters(ULinkParameters parameters) {
    final json = parameters.toJson();

    // Check required fields based on link type
    if (json['type'] == 'dynamic') {
      if (json['slug'] == null || (json['slug'] as String).isEmpty) {
        _log('Parameters validation failed: Dynamic link requires a slug');
        return false;
      }
    } else if (json['type'] == 'unified') {
      final hasIosUrl =
          json['iosUrl'] != null && (json['iosUrl'] as String).isNotEmpty;
      final hasAndroidUrl =
          json['androidUrl'] != null &&
          (json['androidUrl'] as String).isNotEmpty;
      final hasFallbackUrl =
          json['fallbackUrl'] != null &&
          (json['fallbackUrl'] as String).isNotEmpty;

      if (!hasIosUrl && !hasAndroidUrl && !hasFallbackUrl) {
        _log(
          'Parameters validation failed: Unified link requires at least one URL',
        );
        return false;
      }
    }

    _log('Parameters validation successful');
    return true;
  }

  /// Creates a test session for testing session-related functionality.
  ///
  /// [metadata] - Optional metadata for the test session
  /// Returns the session ID if successful
  static Future<String?> createTestSession({
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _log('Creating test session');

      // Note: Sessions are automatically managed by the SDK lifecycle
      // Just get the current session ID if one exists
      final sessionId = await ULink.instance
          .getCurrentSessionId();

      if (sessionId != null) {
        _log('Active session found: $sessionId');
      } else {
        _log('No active session (sessions are auto-managed by lifecycle)');
      }

      return sessionId;
    } catch (e) {
      _log('Error creating test session: $e');
      return null;
    }
  }

  /// Waits for a session to reach a specific state.
  ///
  /// [targetState] - The target session state to wait for
  /// [timeoutSeconds] - Maximum time to wait in seconds (defaults to 30)
  /// Returns true if the target state is reached, false if timeout
  static Future<bool> waitForSessionState(
    SessionState targetState, {
    int timeoutSeconds = 30,
  }) async {
    _log('Waiting for session state: $targetState');

    final startTime = DateTime.now();
    final timeout = Duration(seconds: timeoutSeconds);

    while (DateTime.now().difference(startTime) < timeout) {
      try {
        final currentState = await ULink.instance
            .getSessionState();

        if (currentState == targetState) {
          _log('Session reached target state: $targetState');
          return true;
        }

        // Wait a bit before checking again
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        _log('Error checking session state: $e');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    _log('Timeout waiting for session state: $targetState');
    return false;
  }

  /// Logs debug messages if debug mode is enabled.
  static void _log(String message) {
    if (debugMode && kDebugMode) {
      debugPrint('[ULinkTestingUtilities] $message');
    }
  }
}

/// Extension on [ULinkTestingUtilities] to provide additional test helpers.
extension ULinkTestingUtilitiesExtension on ULinkTestingUtilities {
  /// Creates a comprehensive test suite for ULink functionality.
  ///
  /// This method runs a series of tests to validate ULink integration.
  ///
  /// [config] - The ULink config to test with
  /// Returns a map of test results
  static Future<Map<String, bool>> runTestSuite(ULinkConfig config) async {
    final results = <String, bool>{};

    ULinkTestingUtilities._log('Running ULink test suite');

    // Test 1: Config validation
    results['config_validation'] = ULinkTestingUtilities.validateConfig(config);

    // Test 2: SDK initialization
    try {
      await ULink.instance.initialize(config);
      results['sdk_initialization'] = true;
      ULinkTestingUtilities._log('SDK initialization test passed');
    } catch (e) {
      results['sdk_initialization'] = false;
      ULinkTestingUtilities._log('SDK initialization test failed: $e');
    }

    // Test 3: Link creation
    try {
      final parameters = ULinkTestingUtilities.createMockParameters();
      final response = await ULink.instance.createLink(
        parameters,
      );
      results['link_creation'] =
          response.success && response.url != null && response.url!.isNotEmpty;
      ULinkTestingUtilities._log(
        'Link creation test: ${results['link_creation'] ?? false ? 'passed' : 'failed'}',
      );
    } catch (e) {
      results['link_creation'] = false;
      ULinkTestingUtilities._log('Link creation test failed: $e');
    }

    // Test 4: Session management
    try {
      final sessionId = await ULinkTestingUtilities.createTestSession();
      results['session_creation'] = sessionId != null;

      if (sessionId != null) {
        final hasActiveSession = await ULink.instance
            .hasActiveSession();
        results['session_active_check'] = hasActiveSession;

        await ULink.instance.endSession();
        results['session_end'] = true;
      } else {
        results['session_active_check'] = false;
        results['session_end'] = false;
      }

      ULinkTestingUtilities._log('Session management tests completed');
    } catch (e) {
      results['session_creation'] = false;
      results['session_active_check'] = false;
      results['session_end'] = false;
      ULinkTestingUtilities._log('Session management tests failed: $e');
    }

    // Test 5: Installation ID
    try {
      final installationId = await ULink.instance
          .getInstallationId();
      results['installation_id'] = installationId?.isNotEmpty ?? false;
      ULinkTestingUtilities._log(
        'Installation ID test: ${(results['installation_id'] == true) ? 'passed' : 'failed'}',
      );
    } catch (e) {
      results['installation_id'] = false;
      ULinkTestingUtilities._log('Installation ID test failed: $e');
    }

    final passedTests = results.values.where((result) => result).length;
    final totalTests = results.length;

    ULinkTestingUtilities._log(
      'Test suite completed: $passedTests/$totalTests tests passed',
    );

    return results;
  }
}

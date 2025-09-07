import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

/// A simple script to test the link creation functionality
/// Run this with: dart example/test/link_creation_script.dart
void main() async {
  debugPrint('Starting ULink SDK test script...');

  // Initialize the SDK
  debugPrint('Initializing ULink SDK...');
  final ulink = await ULink.initialize(
    config: ULinkConfig(
      apiKey: 'ulk_839405e4d92e04109829a3d0fafc24b78f6aef0d062a38cb',
      baseUrl: 'http://localhost:3000',
      debug: true,
    ),
  );

  debugPrint('ULink SDK initialized successfully.');

  try {
    // Test 1: Basic link creation
    debugPrint('\nTest 1: Creating a basic link...');
    var stopwatch = Stopwatch()..start();
    debugPrint('🔗 Starting basic link creation...');

    var response = await ulink.createLink(
      ULinkParameters(
        slug: 'script-test-basic',
        iosFallbackUrl: 'myapp://product/123',
        androidFallbackUrl: 'myapp://product/123',
        fallbackUrl: 'https://myapp.com/product/123',
      ),
    );

    stopwatch.stop();
    _debugPrintResponseWithTiming(
        'Basic link', response, stopwatch.elapsedMilliseconds);

    // Test 2: Link with social media tags
    debugPrint('\nTest 2: Creating a link with social media tags...');
    stopwatch = Stopwatch()..start();
    debugPrint('🔗 Starting link creation with social media tags...');

    response = await ulink.createLink(
      ULinkParameters(
        slug: 'script-test-social',
        iosFallbackUrl: 'myapp://product/456',
        androidFallbackUrl: 'myapp://product/456',
        fallbackUrl: 'https://myapp.com/product/456',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Script Test Product',
          ogDescription: 'Testing social media tags from script',
          ogImage: 'https://example.com/script-test-image.jpg',
        ),
      ),
    );

    stopwatch.stop();
    _debugPrintResponseWithTiming(
        'Social media tags link', response, stopwatch.elapsedMilliseconds);

    // Test 3: Link with parameters including social media tags
    debugPrint(
        '\nTest 3: Creating a link with parameters including social media tags...');
    stopwatch = Stopwatch()..start();
    debugPrint(
        '🔗 Starting link creation with parameters including social media tags...');

    response = await ulink.createLink(
      ULinkParameters(
        slug: 'script-test-params',
        iosFallbackUrl: 'myapp://product/789',
        androidFallbackUrl: 'myapp://product/789',
        fallbackUrl: 'https://myapp.com/product/789',
        parameters: {
          'utm_source': 'script_test',
          'campaign': 'script_test_campaign',
          'ogTitle': 'Parameters Title from Script',
          'ogDescription': 'Testing og parameters from script',
          'ogImage': 'https://example.com/script-params-image.jpg',
        },
      ),
    );

    stopwatch.stop();
    _debugPrintResponseWithTiming('Parameters with social media tags', response,
        stopwatch.elapsedMilliseconds);

    // Test 4: Link with both social media tags and parameters
    debugPrint(
        '\nTest 4: Creating a link with both social media tags and parameters...');
    stopwatch = Stopwatch()..start();
    debugPrint(
        '🔗 Starting link creation with both social media tags and parameters...');

    response = await ulink.createLink(
      ULinkParameters(
        slug: 'script-test-combined',
        iosFallbackUrl: 'myapp://product/101112',
        androidFallbackUrl: 'myapp://product/101112',
        fallbackUrl: 'https://myapp.com/product/101112',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Combined Script Test',
          ogDescription: 'Testing combined approach from script',
          ogImage: 'https://example.com/script-combined-image.jpg',
        ),
        parameters: {
          'utm_source': 'script_combined_test',
          'campaign': 'script_combined_campaign',
          'custom_param': 'script_test_value',
        },
      ),
    );

    stopwatch.stop();
    _debugPrintResponseWithTiming(
        'Combined approach', response, stopwatch.elapsedMilliseconds);

    debugPrint('\nAll tests completed successfully!');
  } catch (e) {
    debugPrint('\nError during testing: $e');
  }

  // Exit the script
  exit(0);
}

/// Helper function to debugPrint response details with timing information
void _debugPrintResponseWithTiming(
    String testName, ULinkResponse response, int durationMs) {
  debugPrint('$testName test result:');
  debugPrint('  Success: ${response.success}');
  debugPrint('  Duration: ${durationMs}ms');
  debugPrint(
      '  Performance: ${durationMs < 1000 ? 'Fast' : durationMs < 3000 ? 'Moderate' : 'Slow'}');

  if (response.success) {
    debugPrint('  ✅ URL: ${response.url}');
    debugPrint('  📊 Data: ${response.data}');
  } else {
    debugPrint('  ❌ Error: ${response.error}');
  }

  // Add performance emojis for visual feedback
  if (durationMs < 1000) {
    debugPrint('  🚀 Great performance!');
  } else if (durationMs < 3000) {
    debugPrint('  ⚡ Good performance');
  } else {
    debugPrint('  🐌 Slow performance - check network connection');
  }
}

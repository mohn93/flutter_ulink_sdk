import 'package:flutter/material.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:flutter_ulink_sdk_example/config/env.dart';
import 'dart:async';

/// A test for the ULink SDK with dynamic link resolution
/// This test verifies that the updated SDK correctly handles the new API endpoints
/// Run with: flutter run -t example/test/resolve_test.dart
void main() async {
  debugPrint('Starting ULink SDK dynamic link resolution test...');

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the SDK using example app's environment configuration
  debugPrint('Initializing ULink SDK...');
  final ulink = await ULink.initialize(
    config: ULinkConfig(
      apiKey: Environment.apiKey,
      baseUrl: Environment.baseUrl,
      debug: true,
    ),
  );
  debugPrint(
      'ULink SDK initialized successfully. Using base URL: ${ulink.config.baseUrl}');

  // Set up a listener for link events
  final completer = Completer<ULinkResolvedData>();
  final subscription = ulink.onLink.listen((ULinkResolvedData data) {
    debugPrint('Link received in listener: ${data.rawData}');
    if (!completer.isCompleted) {
      completer.complete(data);
    }
  });

  // Generate a timestamp for unique test slugs
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  try {
    // Test 1: Create a test link
    debugPrint('\nTest 1: Creating a test link...');
    final createResponse = await ulink.createLink(
      ULinkParameters(
        slug: 'resolve-api-test-$timestamp',
        iosFallbackUrl: 'myapp://product/123',
        androidFallbackUrl: 'myapp://product/123',
        fallbackUrl: 'https://myapp.com/product/123',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Test Link for Resolve API',
          ogDescription:
              'This link is created to test the updated resolve API endpoint',
          ogImage: 'https://example.com/test-image.jpg',
        ),
        parameters: {
          'utm_source': 'test',
          'utm_medium': 'sdk',
          'utm_campaign': 'resolve_api_test',
          'testParam': 'testValue',
        },
      ),
    );

    if (!createResponse.success) {
      debugPrint('Error creating test link: ${createResponse.error}');
      return;
    }

    final createdUrl = createResponse.url;
    debugPrint('Created test link: $createdUrl');

    // Test 1: Resolve using the full URL with the updated endpoint
    debugPrint(
        '\nTest 1: Resolving link using the full URL with updated endpoint...');
    debugPrint('Using endpoint: /sdk/resolve?url=...');
    var resolveResponse = await ulink.resolveLink(createdUrl!);
    _debugPrintResolveResponse('Full URL resolution', resolveResponse);


    // Test 3: Use the testListener method to simulate a link click
    debugPrint('\nTest 3: Testing link listener...');
    await ulink.testListener(createdUrl);

    // Wait for the listener to receive the link
    debugPrint('Waiting for link handler to process the link...');
    final receivedData = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('Timeout waiting for link handler');
        return ULinkResolvedData(
          rawData: {'error': 'Timeout waiting for link handler'},
        );
      },
    );

    debugPrint('\nLink handler received data:');
    _debugPrintResolvedData(receivedData);

    debugPrint('\nAll tests completed!');
  } catch (e) {
    debugPrint('\nError during testing: $e');
  } finally {
    // Clean up
    subscription.cancel();
  }
}

/// Helper function to debugPrint resolve response details
void _debugPrintResolveResponse(String testName, ULinkResponse response) {
  debugPrint('$testName test result:');
  debugPrint('  Success: ${response.success}');

  if (response.success) {
    debugPrint('  Resolved URL: ${response.url}');

    if (response.data != null) {
      debugPrint('  Link Details:');

      // debugPrint fallback URLs
      if (response.data!.containsKey('iosFallbackUrl')) {
        debugPrint('    iOS Fallback URL: ${response.data!['iosFallbackUrl']}');
      }

      if (response.data!.containsKey('androidFallbackUrl')) {
        debugPrint(
            '    Android Fallback URL: ${response.data!['androidFallbackUrl']}');
      }

      if (response.data!.containsKey('fallbackUrl')) {
        debugPrint('    Fallback URL: ${response.data!['fallbackUrl']}');
      }

      // debugPrint slug information
      if (response.data!.containsKey('slug')) {
        debugPrint('    Slug: ${response.data!['slug']}');
      }

      if (response.data!.containsKey('id')) {
        debugPrint('    ID: ${response.data!['id']}');
      }

      // debugPrint parameters if they exist
      if (response.data!.containsKey('parameters')) {
        final params = response.data!['parameters'];
        if (params != null) {
          debugPrint('    Parameters:');
          if (params is Map) {
            final Map<String, dynamic> paramsMap =
                params as Map<String, dynamic>;
            paramsMap.forEach((key, value) {
              debugPrint('      $key: $value');
            });
          }
        }
      }

      // debugPrint all other fields for debugging
      debugPrint('    All response data:');
      response.data!.forEach((key, value) {
        if (key != 'parameters') {
          debugPrint('      $key: $value');
        }
      });
    }
  } else {
    debugPrint('  Error: ${response.error}');
  }
}

/// Helper function to debugPrint resolved data details
void _debugPrintResolvedData(ULinkResolvedData data) {
  debugPrint('  Resolved Data Details:');
  debugPrint('    Slug: ${data.slug}');
  debugPrint('    Fallback URL: ${data.fallbackUrl}');
  debugPrint('    iOS Fallback URL: ${data.iosFallbackUrl}');
  debugPrint('    Android Fallback URL: ${data.androidFallbackUrl}');

  if (data.parameters != null) {
    debugPrint('    Parameters:');
    data.parameters!.forEach((key, value) {
      debugPrint('      $key: $value');
    });
  }

  debugPrint('    Raw Data:');
  data.rawData.forEach((key, value) {
    debugPrint('      $key: $value');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:flutter_ulink_sdk_example/config/env.dart';
import 'dart:async';

/// A test for the ULink SDK with dynamic link resolution
/// This test verifies that the updated SDK correctly handles the new API endpoints
/// Run with: flutter run -t example/test/resolve_test.dart
void main() async {
  print('Starting ULink SDK dynamic link resolution test...');

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the SDK using example app's environment configuration
  print('Initializing ULink SDK...');
  final ulink = await ULink.initialize(
    config: ULinkConfig(
      apiKey: Environment.apiKey,
      baseUrl: Environment.baseUrl,
      debug: true,
    ),
  );
  print(
      'ULink SDK initialized successfully. Using base URL: ${ulink.config.baseUrl}');

  // Set up a listener for link events
  final completer = Completer<ULinkResolvedData>();
  final subscription = ulink.onLink.listen((ULinkResolvedData data) {
    print('Link received in listener: ${data.rawData}');
    if (!completer.isCompleted) {
      completer.complete(data);
    }
  });

  // Generate a timestamp for unique test slugs
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  try {
    // Test 1: Create a test link
    print('\nTest 1: Creating a test link...');
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
      print('Error creating test link: ${createResponse.error}');
      return;
    }

    final createdUrl = createResponse.url;
    print('Created test link: $createdUrl');

    // Test 1: Resolve using the full URL with the updated endpoint
    print(
        '\nTest 1: Resolving link using the full URL with updated endpoint...');
    print('Using endpoint: /sdk/resolve?url=...');
    var resolveResponse = await ulink.resolveLink(createdUrl!);
    _printResolveResponse('Full URL resolution', resolveResponse);


    // Test 3: Use the testListener method to simulate a link click
    print('\nTest 3: Testing link listener...');
    await ulink.testListener(createdUrl);

    // Wait for the listener to receive the link
    print('Waiting for link handler to process the link...');
    final receivedData = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('Timeout waiting for link handler');
        return ULinkResolvedData(
          rawData: {'error': 'Timeout waiting for link handler'},
        );
      },
    );

    print('\nLink handler received data:');
    _printResolvedData(receivedData);

    print('\nAll tests completed!');
  } catch (e) {
    print('\nError during testing: $e');
  } finally {
    // Clean up
    subscription.cancel();
  }
}

/// Helper function to print resolve response details
void _printResolveResponse(String testName, ULinkResponse response) {
  print('$testName test result:');
  print('  Success: ${response.success}');

  if (response.success) {
    print('  Resolved URL: ${response.url}');

    if (response.data != null) {
      print('  Link Details:');

      // Print fallback URLs
      if (response.data!.containsKey('iosFallbackUrl')) {
        print('    iOS Fallback URL: ${response.data!['iosFallbackUrl']}');
      }

      if (response.data!.containsKey('androidFallbackUrl')) {
        print(
            '    Android Fallback URL: ${response.data!['androidFallbackUrl']}');
      }

      if (response.data!.containsKey('fallbackUrl')) {
        print('    Fallback URL: ${response.data!['fallbackUrl']}');
      }

      // Print slug information
      if (response.data!.containsKey('slug')) {
        print('    Slug: ${response.data!['slug']}');
      }

      if (response.data!.containsKey('id')) {
        print('    ID: ${response.data!['id']}');
      }

      // Print parameters if they exist
      if (response.data!.containsKey('parameters')) {
        final params = response.data!['parameters'];
        if (params != null) {
          print('    Parameters:');
          if (params is Map) {
            final Map<String, dynamic> paramsMap =
                params as Map<String, dynamic>;
            paramsMap.forEach((key, value) {
              print('      $key: $value');
            });
          }
        }
      }

      // Print all other fields for debugging
      print('    All response data:');
      response.data!.forEach((key, value) {
        if (key != 'parameters') {
          print('      $key: $value');
        }
      });
    }
  } else {
    print('  Error: ${response.error}');
  }
}

/// Helper function to print resolved data details
void _printResolvedData(ULinkResolvedData data) {
  print('  Resolved Data Details:');
  print('    Slug: ${data.slug}');
  print('    Fallback URL: ${data.fallbackUrl}');
  print('    iOS Fallback URL: ${data.iosFallbackUrl}');
  print('    Android Fallback URL: ${data.androidFallbackUrl}');

  if (data.parameters != null) {
    print('    Parameters:');
    data.parameters!.forEach((key, value) {
      print('      $key: $value');
    });
  }

  print('    Raw Data:');
  data.rawData.forEach((key, value) {
    print('      $key: $value');
  });
}

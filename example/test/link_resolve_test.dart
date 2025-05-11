import 'package:flutter/material.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

/// A test for the ULink SDK link resolution functionality
/// Run with: dart example/test/link_resolve_test.dart
void main() async {
  print('Starting ULink SDK link resolution test...');

  await WidgetsFlutterBinding.ensureInitialized();
  // Initialize the SDK
  print('Initializing ULink SDK...');
  final ulink = await ULink.initialize(
    config: ULinkConfig(
      apiKey: 'ulk_839405e4d92e04109829a3d0fafc24b78f6aef0d062a38cb',
      baseUrl: 'http://localhost:3000',
      debug: true,
    ),
  );
  print('ULink SDK initialized successfully.');

  // Generate a timestamp to make slugs unique
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  try {
    // First, create a link to test with
    print('\nStep 1: Creating a test link...');
    final createResponse = await ulink.createLink(
      ULinkParameters(
        slug: 'resolve-test-$timestamp',
        iosFallbackUrl: 'myapp://product/123',
        androidFallbackUrl: 'myapp://product/123',
        fallbackUrl: 'https://myapp.com/product/123',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Test Link for Resolution',
          ogDescription:
              'This link is created to test the resolution functionality',
          ogImage: 'https://example.com/test-image.jpg',
        ),
        parameters: {
          'utm_source': 'test',
          'utm_medium': 'sdk',
          'utm_campaign': 'resolution_test',
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

    // Test 1: Resolve using the full URL
    print('\nTest 1: Resolving link using the full URL...');
    var resolveResponse = await ulink.resolveLink(createdUrl!);
    _printResolveResponse('Full URL resolution', resolveResponse);

    // Test 2: Resolve using just the slug
    print('\nTest 2: Resolving link using just the slug...');
    final slug = 'resolve-test-$timestamp';
    resolveResponse = await ulink.resolveLink(slug);
    _printResolveResponse('Slug resolution', resolveResponse);

    // Test 3: Resolve a non-existent link
    print('\nTest 3: Resolving a non-existent link...');
    resolveResponse =
        await ulink.resolveLink('non-existent-slug-${timestamp + 1000}');
    _printResolveResponse('Non-existent link resolution', resolveResponse);

    print('\nAll tests completed!');
  } catch (e) {
    print('\nError during testing: $e');
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
    }
  } else {
    print('  Error: ${response.error}');
  }
}

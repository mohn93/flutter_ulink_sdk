import 'package:flutter/material.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

/// A test for the ULink SDK link resolution functionality
/// Run with: dart example/test/link_resolve_test.dart
void main() async {
  debugPrint('Starting ULink SDK link resolution test...');

  WidgetsFlutterBinding.ensureInitialized();
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

  // Generate a timestamp to make slugs unique
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  try {
    // First, create a link to test with
    debugPrint('\nStep 1: Creating a test link...');
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
      debugPrint('Error creating test link: ${createResponse.error}');
      return;
    }

    final createdUrl = createResponse.url;
    debugPrint('Created test link: $createdUrl');

    // Test 1: Resolve using the full URL
    debugPrint('\nTest 1: Resolving link using the full URL...');
    var resolveResponse = await ulink.resolveLink(createdUrl!);
    _debugPrintResolveResponse('Full URL resolution', resolveResponse);

    // Test 2: Resolve using just the slug
    debugPrint('\nTest 2: Resolving link using just the slug...');
    final slug = 'resolve-test-$timestamp';
    resolveResponse = await ulink.resolveLink(slug);
    _debugPrintResolveResponse('Slug resolution', resolveResponse);

    // Test 3: Resolve a non-existent link
    debugPrint('\nTest 3: Resolving a non-existent link...');
    resolveResponse =
        await ulink.resolveLink('non-existent-slug-${timestamp + 1000}');
    _debugPrintResolveResponse('Non-existent link resolution', resolveResponse);

    debugPrint('\nAll tests completed!');
  } catch (e) {
    debugPrint('\nError during testing: $e');
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
    }
  } else {
    debugPrint('  Error: ${response.error}');
  }
}

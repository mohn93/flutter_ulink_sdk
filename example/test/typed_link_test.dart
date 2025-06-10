import 'package:flutter/material.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

/// A strongly typed test for the ULink SDK
/// Run with: dart example/test/typed_link_test.dart
void main() async {
  print('Starting strongly typed ULink SDK test...');
  WidgetsFlutterBinding.ensureInitialized();
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
    // Test 1: Basic link creation with social media tags
    print('\nTest 1: Creating a basic link with social media tags...');
    var response = await ulink.createLink(
      ULinkParameters(
        slug: 'typed-basic-$timestamp',
        iosFallbackUrl: 'myapp://product/123',
        androidFallbackUrl: 'myapp://product/123',
        fallbackUrl: 'https://myapp.com/product/123',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Basic Link Title',
          ogDescription: 'Basic link description for social sharing',
          ogImage: 'https://example.com/basic-image.jpg',
        ),
      ),
    );

    _printResponse('Basic link with social media tags', response);

    // Test 2: Link with detailed social media tags and additional parameters
    print(
        '\nTest 2: Creating a link with detailed social media tags and additional parameters...');
    response = await ulink.createLink(
      ULinkParameters(
        slug: 'typed-detailed-$timestamp',
        iosFallbackUrl: 'myapp://product/456',
        androidFallbackUrl: 'myapp://product/456',
        fallbackUrl: 'https://myapp.com/product/456',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Amazing Product You Must See!',
          ogDescription:
              'This is a detailed description of our amazing product with all features explained.',
          ogImage: 'https://example.com/high-quality-image.jpg',
        ),
        parameters: {
          'ogSiteName': 'My Awesome App',
          'ogType': 'product',
        },
      ),
    );

    _printResponse('Detailed social media tags', response);

    // Test 3: Link with social media tags and UTM parameters
    print(
        '\nTest 3: Creating a link with social media tags and UTM parameters...');
    response = await ulink.createLink(
      ULinkParameters(
        slug: 'typed-utm-$timestamp',
        iosFallbackUrl: 'myapp://product/789',
        androidFallbackUrl: 'myapp://product/789',
        fallbackUrl: 'https://myapp.com/product/789',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Summer Sale - 50% Off!',
          ogDescription:
              'Get our amazing products at half price during our summer sale event!',
          ogImage: 'https://example.com/summer-sale-banner.jpg',
        ),
        parameters: {
          'utm_source': 'social_share',
          'utm_medium': 'app',
          'utm_campaign': 'summer_promotion',
          'utm_content': 'product_page',
          'utm_term': 'discount',
        },
      ),
    );

    _printResponse('Social media tags with UTM parameters', response);

    // Test 4: Link with minimal required parameters
    print('\nTest 4: Creating a link with minimal required parameters...');
    response = await ulink.createLink(
      ULinkParameters(
        slug: 'typed-minimal-$timestamp',
        fallbackUrl: 'https://myapp.com/fallback',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Simple Share',
          ogDescription: 'Testing minimal parameters with social media tags',
          ogImage: 'https://example.com/simple-image.jpg',
        ),
      ),
    );

    _printResponse('Minimal parameters', response);

    print('\nAll tests completed successfully!');
  } catch (e) {
    print('\nError during testing: $e');
  }
}

/// Helper function to print response details
void _printResponse(String testName, ULinkResponse response) {
  print('$testName test result:');
  print('  Success: ${response.success}');

  if (response.success) {
    print('  URL: ${response.url}');

    // Print social media parameters if they exist
    if (response.data != null && response.data!.containsKey('parameters')) {
      final params = response.data!['parameters'];
      if (params != null) {
        print('  Social Media Parameters:');
        if (params is Map) {
          final Map<String, dynamic> paramsMap = params as Map<String, dynamic>;
          paramsMap.forEach((key, value) {
            if (key.startsWith('og')) {
              print('    $key: $value');
            }
          });
        }
      }
    }

    print('  Raw data: ${response.data}');
  } else {
    print('  Error: ${response.error}');
  }
}

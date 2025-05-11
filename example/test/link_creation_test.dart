import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

void main() {
  late ULink ulink;

  setUpAll(() async {
    // Initialize the SDK before running tests
    ulink = await ULink.initialize(
      config: ULinkConfig(
        apiKey: 'ulk_839405e4d92e04109829a3d0fafc24b78f6aef0d062a38cb',
        baseUrl: 'http://localhost:3000',
        debug: true,
      ),
    );
  });

  group('Link Creation Tests', () {
    test('Create link with basic parameters', () async {
      final response = await ulink.createLink(
        ULinkParameters(
          // slug: 'test-basic-link',

          iosFallbackUrl: 'myapp://product/123',
          androidFallbackUrl: 'myapp://product/123',
          fallbackUrl: 'https://myapp.com/product/123',
        ),
      );

      // Print the response for debugging
      print('Basic link response: ${response.data}');

      // Verify the response
      expect(response.success, isTrue);
      expect(response.url, isNotNull);
      expect(response.url, isNotEmpty);
    });

    test('Create link with social media tags using SocialMediaTags class',
        () async {
      final response = await ulink.createLink(
        ULinkParameters(
          slug: 'test-social-tags',
          iosFallbackUrl: 'myapp://product/456',
          androidFallbackUrl: 'myapp://product/456',
          fallbackUrl: 'https://myapp.com/product/456',
          socialMediaTags: SocialMediaTags(
            ogTitle: 'Test Product Title',
            ogDescription: 'This is a test product description',
            ogImage: 'https://example.com/test-image.jpg',
          ),
        ),
      );

      // Print the response for debugging
      print('Social media tags response: ${response.data}');

      // Verify the response
      expect(response.success, isTrue);
      expect(response.url, isNotNull);
      expect(response.url, isNotEmpty);
    });

    test('Create link with social media tags in parameters', () async {
      final response = await ulink.createLink(
        ULinkParameters(
          slug: 'test-params-tags',
          iosFallbackUrl: 'myapp://product/789',
          androidFallbackUrl: 'myapp://product/789',
          fallbackUrl: 'https://myapp.com/product/789',
          parameters: {
            'utm_source': 'test',
            'campaign': 'unit_test',
            'ogTitle': 'Parameters Title Test',
            'ogDescription': 'Testing description in parameters',
            'ogImage': 'https://example.com/params-test-image.jpg',
          },
        ),
      );

      // Print the response for debugging
      print('Parameters tags response: ${response.data}');

      // Verify the response
      expect(response.success, isTrue);
      expect(response.url, isNotNull);
      expect(response.url, isNotEmpty);
    });

    test('Create link with both social media tags and parameters', () async {
      final response = await ulink.createLink(
        ULinkParameters(
          slug: 'test-combined',
          iosFallbackUrl: 'myapp://product/101112',
          androidFallbackUrl: 'myapp://product/101112',
          fallbackUrl: 'https://myapp.com/product/101112',
          socialMediaTags: SocialMediaTags(
            ogTitle: 'Combined Test Title',
            ogDescription: 'Testing combined approach',
            ogImage: 'https://example.com/combined-test-image.jpg',
          ),
          parameters: {
            'utm_source': 'combined_test',
            'campaign': 'unit_test_combined',
            'custom_param': 'test_value',
          },
        ),
      );

      // Print the response for debugging
      print('Combined approach response: ${response.data}');

      // Verify the response
      expect(response.success, isTrue);
      expect(response.url, isNotNull);
      expect(response.url, isNotEmpty);
    });
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

void main() {
  late ULink ulink;

  setUpAll(() async {
    // Initialize Flutter binding for tests
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize the SDK before running tests
    ulink = await ULink.initialize(
      config: ULinkConfig(
        apiKey: 'ulk_839405e4d92e04109829a3d0fafc24b78f6aef0d062a38cb',
        baseUrl: 'http://localhost:3000',
        debug: true,
      ),
    );
  });

  group('Metadata Tests', () {
    test('Create link with metadata field for social media data', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final response = await ulink.createLink(
        ULinkParameters(
          slug: 'test-metadata-$timestamp',
          iosFallbackUrl: 'myapp://product/123',
          androidFallbackUrl: 'myapp://product/123',
          fallbackUrl: 'https://myapp.com/product/123',
          parameters: {
            'utm_source': 'test',
            'campaign': 'metadata_test',
            'customParam': 'value123',
          },
          metadata: {
            'ogTitle': 'Test Product with Metadata',
            'ogDescription':
                'This uses the new metadata field for social media',
            'ogImage': 'https://example.com/metadata-image.jpg',
            'ogSiteName': 'Test App',
            'ogType': 'product',
          },
        ),
      );

      // debugPrint the response for debugging
      debugPrint('Metadata test response: ${response.data}');

      // Verify the response
      expect(response.success, isTrue);
      expect(response.url, isNotNull);
      expect(response.url, isNotEmpty);

      // Verify that metadata is separated from parameters in the response
      if (response.data != null) {
        expect(response.data!.containsKey('metadata'), isTrue);
        expect(response.data!.containsKey('parameters'), isTrue);

        final metadata = response.data!['metadata'];
        final parameters = response.data!['parameters'];

        // Check that social media data is in metadata
        expect(metadata['ogTitle'], 'Test Product with Metadata');
        expect(metadata['ogDescription'],
            'This uses the new metadata field for social media');
        expect(metadata['ogImage'], 'https://example.com/metadata-image.jpg');

        // Check that non-social media data is in parameters
        expect(parameters['utm_source'], 'test');
        expect(parameters['campaign'], 'metadata_test');
        expect(parameters['customParam'], 'value123');

        // Verify that social media data is NOT in parameters
        expect(parameters.containsKey('ogTitle'), isFalse);
        expect(parameters.containsKey('ogDescription'), isFalse);
        expect(parameters.containsKey('ogImage'), isFalse);
      }
    });

    test(
        'Create link with social media parameters in parameters field (should move to metadata)',
        () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final response = await ulink.createLink(
        ULinkParameters(
          slug: 'test-params-social-$timestamp',
          iosFallbackUrl: 'myapp://product/456',
          androidFallbackUrl: 'myapp://product/456',
          fallbackUrl: 'https://myapp.com/product/456',
          parameters: {
            'utm_source': 'test',
            'campaign': 'social_in_params_test',
            'ogTitle': 'Social Media Title in Parameters',
            'ogDescription': 'This should be moved to metadata',
            'ogImage': 'https://example.com/params-social-image.jpg',
            'customParam': 'value456',
          },
        ),
      );

      // debugPrint the response for debugging
      debugPrint('Social in parameters test response: ${response.data}');

      // Verify the response
      expect(response.success, isTrue);
      expect(response.url, isNotNull);
      expect(response.url, isNotEmpty);

      // Verify that social media parameters were moved to metadata
      if (response.data != null) {
        expect(response.data!.containsKey('metadata'), isTrue);
        expect(response.data!.containsKey('parameters'), isTrue);

        final metadata = response.data!['metadata'];
        final parameters = response.data!['parameters'];

        // Check that social media data is in metadata
        expect(metadata['ogTitle'], 'Social Media Title in Parameters');
        expect(metadata['ogDescription'], 'This should be moved to metadata');
        expect(
            metadata['ogImage'], 'https://example.com/params-social-image.jpg');

        // Check that non-social media data is in parameters
        expect(parameters['utm_source'], 'test');
        expect(parameters['campaign'], 'social_in_params_test');
        expect(parameters['customParam'], 'value456');

        // Verify that social media data is NOT in parameters
        expect(parameters.containsKey('ogTitle'), isFalse);
        expect(parameters.containsKey('ogDescription'), isFalse);
        expect(parameters.containsKey('ogImage'), isFalse);
      }
    });

    test('Create link with both SocialMediaTags and metadata', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final response = await ulink.createLink(
        ULinkParameters(
          slug: 'test-combined-metadata-$timestamp',
          iosFallbackUrl: 'myapp://product/789',
          androidFallbackUrl: 'myapp://product/789',
          fallbackUrl: 'https://myapp.com/product/789',
          socialMediaTags: SocialMediaTags(
            ogTitle: 'Title from SocialMediaTags',
            ogDescription: 'Description from SocialMediaTags',
            ogImage: 'https://example.com/social-tags-image.jpg',
          ),
          metadata: {
            'ogSiteName': 'Test App from Metadata',
            'ogType': 'product',
            'twitterCard': 'summary_large_image',
          },
          parameters: {
            'utm_source': 'combined_test',
            'campaign': 'metadata_and_social_tags',
          },
        ),
      );

      // debugPrint the response for debugging
      debugPrint('Combined metadata test response: ${response.data}');

      // Verify the response
      expect(response.success, isTrue);
      expect(response.url, isNotNull);
      expect(response.url, isNotEmpty);

      // Verify that all metadata is properly combined
      if (response.data != null) {
        expect(response.data!.containsKey('metadata'), isTrue);
        expect(response.data!.containsKey('parameters'), isTrue);

        final metadata = response.data!['metadata'];
        final parameters = response.data!['parameters'];

        // Check that social media tags data is in metadata
        expect(metadata['ogTitle'], 'Title from SocialMediaTags');
        expect(metadata['ogDescription'], 'Description from SocialMediaTags');
        expect(
            metadata['ogImage'], 'https://example.com/social-tags-image.jpg');

        // Check that explicit metadata is also in metadata
        expect(metadata['ogSiteName'], 'Test App from Metadata');
        expect(metadata['ogType'], 'product');
        expect(metadata['twitterCard'], 'summary_large_image');

        // Check that non-social media data is in parameters
        expect(parameters['utm_source'], 'combined_test');
        expect(parameters['campaign'], 'metadata_and_social_tags');
      }
    });
  });
}

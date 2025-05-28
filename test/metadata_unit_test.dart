import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

void main() {
  group('Metadata Unit Tests', () {
    test('ULinkParameters.toJson() separates social media data into metadata',
        () {
      final parameters = ULinkParameters(
        slug: 'test-slug',
        iosFallbackUrl: 'myapp://product/123',
        androidFallbackUrl: 'myapp://product/123',
        fallbackUrl: 'https://myapp.com/product/123',
        parameters: {
          'utm_source': 'test',
          'campaign': 'metadata_test',
          'customParam': 'value123',
          'ogTitle': 'Title in Parameters',
          'ogDescription': 'Description in Parameters',
          'ogImage': 'https://example.com/image.jpg',
        },
        metadata: {
          'ogSiteName': 'Test App',
          'ogType': 'product',
          'twitterCard': 'summary_large_image',
        },
      );

      final json = parameters.toJson();

      // Verify that the JSON has separate parameters and metadata fields
      expect(json.containsKey('parameters'), isTrue);
      expect(json.containsKey('metadata'), isTrue);

      final params = json['parameters'] as Map<String, dynamic>;
      final metadata = json['metadata'] as Map<String, dynamic>;

      // Verify that non-social media parameters are in parameters
      expect(params['utm_source'], 'test');
      expect(params['campaign'], 'metadata_test');
      expect(params['customParam'], 'value123');

      // Verify that social media parameters from parameters map are moved to metadata
      expect(metadata['ogTitle'], 'Title in Parameters');
      expect(metadata['ogDescription'], 'Description in Parameters');
      expect(metadata['ogImage'], 'https://example.com/image.jpg');

      // Verify that explicit metadata is in metadata
      expect(metadata['ogSiteName'], 'Test App');
      expect(metadata['ogType'], 'product');
      expect(metadata['twitterCard'], 'summary_large_image');

      // Verify that social media data is NOT in parameters
      expect(params.containsKey('ogTitle'), isFalse);
      expect(params.containsKey('ogDescription'), isFalse);
      expect(params.containsKey('ogImage'), isFalse);
      expect(params.containsKey('ogSiteName'), isFalse);
      expect(params.containsKey('ogType'), isFalse);
    });

    test('ULinkParameters.toJson() handles SocialMediaTags', () {
      final parameters = ULinkParameters(
        slug: 'test-social-tags',
        fallbackUrl: 'https://myapp.com/fallback',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Title from SocialMediaTags',
          ogDescription: 'Description from SocialMediaTags',
          ogImage: 'https://example.com/social-image.jpg',
        ),
        parameters: {
          'utm_source': 'social_test',
          'campaign': 'social_tags_test',
        },
      );

      final json = parameters.toJson();

      // Verify that the JSON has separate parameters and metadata fields
      expect(json.containsKey('parameters'), isTrue);
      expect(json.containsKey('metadata'), isTrue);

      final params = json['parameters'] as Map<String, dynamic>;
      final metadata = json['metadata'] as Map<String, dynamic>;

      // Verify that regular parameters are in parameters
      expect(params['utm_source'], 'social_test');
      expect(params['campaign'], 'social_tags_test');

      // Verify that social media tags are in metadata
      expect(metadata['ogTitle'], 'Title from SocialMediaTags');
      expect(metadata['ogDescription'], 'Description from SocialMediaTags');
      expect(metadata['ogImage'], 'https://example.com/social-image.jpg');

      // Verify that social media data is NOT in parameters
      expect(params.containsKey('ogTitle'), isFalse);
      expect(params.containsKey('ogDescription'), isFalse);
      expect(params.containsKey('ogImage'), isFalse);
    });

    test('ULinkParameters.toJson() handles only non-social media parameters',
        () {
      final parameters = ULinkParameters(
        slug: 'test-regular-params',
        fallbackUrl: 'https://myapp.com/fallback',
        parameters: {
          'utm_source': 'regular_test',
          'campaign': 'regular_params_test',
          'customParam': 'regularValue',
        },
      );

      final json = parameters.toJson();

      // Verify that parameters field exists but metadata field doesn't (empty)
      expect(json.containsKey('parameters'), isTrue);
      expect(json.containsKey('metadata'), isFalse);

      final params = json['parameters'] as Map<String, dynamic>;

      // Verify that all parameters are in parameters
      expect(params['utm_source'], 'regular_test');
      expect(params['campaign'], 'regular_params_test');
      expect(params['customParam'], 'regularValue');
    });

    test('ULinkParameters.toJson() handles only social media data', () {
      final parameters = ULinkParameters(
        slug: 'test-only-social',
        fallbackUrl: 'https://myapp.com/fallback',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Only Social Title',
          ogDescription: 'Only Social Description',
        ),
        metadata: {
          'ogSiteName': 'Only Social App',
        },
      );

      final json = parameters.toJson();

      // Verify that metadata field exists but parameters field doesn't (empty)
      expect(json.containsKey('metadata'), isTrue);
      expect(json.containsKey('parameters'), isFalse);

      final metadata = json['metadata'] as Map<String, dynamic>;

      // Verify that all social media data is in metadata
      expect(metadata['ogTitle'], 'Only Social Title');
      expect(metadata['ogDescription'], 'Only Social Description');
      expect(metadata['ogSiteName'], 'Only Social App');
    });

    test('ULinkResolvedData.fromJson() parses metadata correctly', () {
      final jsonData = {
        'slug': 'test-resolve-slug',
        'iosFallbackUrl': 'myapp://ios/123',
        'androidFallbackUrl': 'myapp://android/123',
        'fallbackUrl': 'https://myapp.com/fallback',
        'parameters': {
          'utm_source': 'resolve_test',
          'campaign': 'resolve_test_campaign',
        },
        'metadata': {
          'ogTitle': 'Resolved Title',
          'ogDescription': 'Resolved Description',
          'ogImage': 'https://example.com/resolved-image.jpg',
          'ogSiteName': 'Resolved App',
        },
      };

      final resolvedData = ULinkResolvedData.fromJson(jsonData);

      // Verify basic data
      expect(resolvedData.slug, 'test-resolve-slug');
      expect(resolvedData.iosFallbackUrl, 'myapp://ios/123');
      expect(resolvedData.androidFallbackUrl, 'myapp://android/123');
      expect(resolvedData.fallbackUrl, 'https://myapp.com/fallback');

      // Verify parameters
      expect(resolvedData.parameters!['utm_source'], 'resolve_test');
      expect(resolvedData.parameters!['campaign'], 'resolve_test_campaign');

      // Verify metadata
      expect(resolvedData.metadata!['ogTitle'], 'Resolved Title');
      expect(resolvedData.metadata!['ogDescription'], 'Resolved Description');
      expect(resolvedData.metadata!['ogImage'],
          'https://example.com/resolved-image.jpg');
      expect(resolvedData.metadata!['ogSiteName'], 'Resolved App');

      // Verify social media tags are extracted from metadata
      expect(resolvedData.socialMediaTags, isNotNull);
      expect(resolvedData.socialMediaTags!.ogTitle, 'Resolved Title');
      expect(
          resolvedData.socialMediaTags!.ogDescription, 'Resolved Description');
      expect(resolvedData.socialMediaTags!.ogImage,
          'https://example.com/resolved-image.jpg');
    });

    test(
        'ULinkResolvedData.fromJson() falls back to parameters for backward compatibility',
        () {
      final jsonData = {
        'slug': 'test-backward-compat',
        'fallbackUrl': 'https://myapp.com/fallback',
        'parameters': {
          'utm_source': 'backward_test',
          'ogTitle': 'Title in Parameters',
          'ogDescription': 'Description in Parameters',
          'ogImage': 'https://example.com/params-image.jpg',
        },
      };

      final resolvedData = ULinkResolvedData.fromJson(jsonData);

      // Verify basic data
      expect(resolvedData.slug, 'test-backward-compat');
      expect(resolvedData.fallbackUrl, 'https://myapp.com/fallback');

      // Verify parameters contain all data (backward compatibility)
      expect(resolvedData.parameters!['utm_source'], 'backward_test');
      expect(resolvedData.parameters!['ogTitle'], 'Title in Parameters');

      // Verify metadata is null (no separate metadata field)
      expect(resolvedData.metadata, isNull);

      // Verify social media tags are still extracted from parameters
      expect(resolvedData.socialMediaTags, isNotNull);
      expect(resolvedData.socialMediaTags!.ogTitle, 'Title in Parameters');
      expect(resolvedData.socialMediaTags!.ogDescription,
          'Description in Parameters');
      expect(resolvedData.socialMediaTags!.ogImage,
          'https://example.com/params-image.jpg');
    });
  });
}

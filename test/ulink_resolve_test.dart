import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ULink SDK Resolve Tests with Updated API', () {
    late http.Client mockClient;
    late ULink ulink;

    TestWidgetsFlutterBinding.ensureInitialized();
    // Sample dynamic link data that matches the new API format
    final mockDynamicLinkData = {
      'id': 'link-123',
      'slug': 'test-slug',
      'projectId': 'project-123',
      'iosFallbackUrl': 'myapp://ios/123',
      'androidFallbackUrl': 'myapp://android/123',
      'fallbackUrl': 'https://myapp.com/fallback',
      'parameters': {
        'utm_source': 'test',
        'ogTitle': 'Test Product',
        'ogDescription': 'This is a test product'
      },
      'createdAt': '2023-08-01T12:00:00Z',
      'updatedAt': '2023-08-01T12:00:00Z',
      'clickCount': 10
    };

    setUp(() async {
      // Create a mock HTTP client using http's MockClient
      mockClient = MockClient((http.Request request) async {
        // Check if this is a resolve request with the correct endpoint format
        if (request.url.path.contains('/sdk/resolve')) {
          return http.Response(
            json.encode(mockDynamicLinkData),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        // Default response for other requests
        return http.Response('{"error": "Unexpected request"}', 404);
      });

      // Initialize the ULink SDK with the mock client
      ulink = ULink.forTesting(
        config: ULinkConfig(
          apiKey: 'test_api_key',
          debug: true,
        ),
        httpClient: mockClient,
      );
    });

    test('resolveLink correctly handles new API response format', () async {
      // Test resolving a link
      final response = await ulink.resolveLink('https://ulink.ly/test-slug');

      // Verify the response was successful
      expect(response.success, true);
      expect(response.url, 'https://myapp.com/fallback');

      // Verify the data in the response matches what we expect
      expect(response.data!['slug'], 'test-slug');
      expect(response.data!['fallbackUrl'], 'https://myapp.com/fallback');
      expect(response.data!['iosFallbackUrl'], 'myapp://ios/123');
      expect(response.data!['androidFallbackUrl'], 'myapp://android/123');

      // Verify that parameters are correctly included
      expect(response.data!['parameters'], isA<Map>());
      expect(response.data!['parameters']['utm_source'], 'test');
      expect(response.data!['parameters']['ogTitle'], 'Test Product');
    });

    test('ULinkResolvedData.fromJson correctly parses new API response', () {
      // Test parsing the response data
      final resolvedData = ULinkResolvedData.fromJson(mockDynamicLinkData);

      // Verify the parsed data matches what we expect
      expect(resolvedData.slug, 'test-slug');
      expect(resolvedData.fallbackUrl, 'https://myapp.com/fallback');
      expect(resolvedData.iosFallbackUrl, 'myapp://ios/123');
      expect(resolvedData.androidFallbackUrl, 'myapp://android/123');

      // Verify that parameters are correctly included
      expect(resolvedData.parameters, isA<Map>());
      expect(resolvedData.parameters!['utm_source'], 'test');

      // Verify that social media tags are correctly parsed
      expect(resolvedData.socialMediaTags, isNotNull);
      expect(resolvedData.socialMediaTags!.ogTitle, 'Test Product');
      expect(resolvedData.socialMediaTags!.ogDescription,
          'This is a test product');
    });
  });
}

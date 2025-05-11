import 'dart:convert';
import 'package:http/http.dart' as http;

/// A simple script to test the link creation API directly
/// Run with: dart example/test/simple_link_test.dart
void main() async {
  print('Starting simple ULink API test...');

  const String apiKey = 'ulk_839405e4d92e04109829a3d0fafc24b78f6aef0d062a38cb';
  const String baseUrl = 'http://localhost:3000';

  // Generate a timestamp to make slugs unique
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  // Test 1: Basic link creation with social media params
  await testLinkCreation(
    apiKey: apiKey,
    baseUrl: baseUrl,
    testName: 'Basic Link with Social Media',
    payload: {
      'slug': 'test-basic-link-$timestamp',
      'iosFallbackUrl': 'myapp://product/123',
      'androidFallbackUrl': 'myapp://product/123',
      'fallbackUrl': 'https://myapp.com/product/123',
      'parameters': {
        'ogTitle': 'Basic Link Title',
        'ogDescription': 'Basic link description for social sharing',
        'ogImage': 'https://example.com/basic-image.jpg',
      },
    },
  );

  // Test 2: Link with detailed social media tags
  await testLinkCreation(
    apiKey: apiKey,
    baseUrl: baseUrl,
    testName: 'Detailed Social Media Tags',
    payload: {
      'slug': 'test-social-tags-$timestamp',
      'iosFallbackUrl': 'myapp://product/456',
      'androidFallbackUrl': 'myapp://product/456',
      'fallbackUrl': 'https://myapp.com/product/456',
      'parameters': {
        'ogTitle': 'Amazing Product You Must See!',
        'ogDescription':
            'This is a detailed description of our amazing product with all features explained.',
        'ogImage': 'https://example.com/high-quality-image.jpg',
        'ogSiteName': 'My Awesome App',
        'ogType': 'product',
      },
    },
  );

  // Test 3: Link with social media tags and UTM parameters
  await testLinkCreation(
    apiKey: apiKey,
    baseUrl: baseUrl,
    testName: 'Social Media Tags with UTM Parameters',
    payload: {
      'slug': 'test-params-link-$timestamp',
      'iosFallbackUrl': 'myapp://product/789',
      'androidFallbackUrl': 'myapp://product/789',
      'fallbackUrl': 'https://myapp.com/product/789',
      'parameters': {
        'utm_source': 'social_share',
        'utm_medium': 'app',
        'utm_campaign': 'summer_promotion',
        'utm_content': 'product_page',
        'utm_term': 'discount',
        'ogTitle': 'Summer Sale - 50% Off!',
        'ogDescription':
            'Get our amazing products at half price during our summer sale event!',
        'ogImage': 'https://example.com/summer-sale-banner.jpg',
      },
    },
  );

  // Test 4: Link with minimal required parameters but still with social media tags
  await testLinkCreation(
    apiKey: apiKey,
    baseUrl: baseUrl,
    testName: 'Minimal Parameters with Social Media',
    payload: {
      'slug': 'test-minimal-$timestamp',
      'fallbackUrl': 'https://myapp.com/fallback',
      'parameters': {
        'ogTitle': 'Simple Share',
        'ogDescription': 'Testing minimal parameters with social media tags',
        'ogImage': 'https://example.com/simple-image.jpg',
      },
    },
  );

  print('\nAll tests completed!');
}

/// Test link creation with the given payload
Future<void> testLinkCreation({
  required String apiKey,
  required String baseUrl,
  required String testName,
  required Map<String, dynamic> payload,
}) async {
  print('\nTest: $testName');
  print('Payload: ${jsonEncode(payload)}');

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/sdk/links'),
      headers: {
        'Content-Type': 'application/json',
        'X-App-Key': apiKey,
      },
      body: jsonEncode(payload),
    );

    print('Status code: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      print('Success! Response: ${jsonEncode(responseData)}');

      // Print social media parameters if they exist
      if (responseData.containsKey('parameters')) {
        final params = responseData['parameters'];
        if (params != null) {
          print('Social Media Parameters:');
          if (params is Map) {
            final Map<String, dynamic> paramsMap =
                params as Map<String, dynamic>;
            paramsMap.forEach((key, value) {
              if (key.startsWith('og')) {
                print('  $key: $value');
              }
            });
          }
        }
      }

      if (responseData.containsKey('url')) {
        print('Generated URL: ${responseData['url']}');
      } else if (responseData.containsKey('shortUrl')) {
        print('Generated URL: ${responseData['shortUrl']}');
      }
    } else {
      print('Error: ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}

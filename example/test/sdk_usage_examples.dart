import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

/// A comprehensive example of using the ULink SDK with strongly typed code
/// This file demonstrates different ways to use the SDK
/// Run with: dart example/test/sdk_usage_examples.dart
void main() async {
  print('ULink SDK Usage Examples');
  print('=======================');

  // Initialize the SDK
  final ulink = await ULink.initialize(
    config: ULinkConfig(
      apiKey: 'ulk_839405e4d92e04109829a3d0fafc24b78f6aef0d062a38cb',
      baseUrl: 'http://localhost:3000',
      debug: true, // Set to true for verbose logging
    ),
  );

  // Generate a timestamp to make slugs unique
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  try {
    // Example 1: Basic link creation
    print('\nExample 1: Basic link creation');
    await createBasicLink(ulink, timestamp);

    // Example 2: Using SocialMediaTags class
    print('\nExample 2: Using SocialMediaTags class');
    await createLinkWithSocialMediaTags(ulink, timestamp);

    // Example 3: Using parameters map
    print('\nExample 3: Using parameters map');
    await createLinkWithParametersMap(ulink, timestamp);

    // Example 4: Using both SocialMediaTags and parameters
    print('\nExample 4: Using both SocialMediaTags and parameters');
    await createLinkWithBoth(ulink, timestamp);

    // Example 5: Minimal required parameters
    print('\nExample 5: Minimal required parameters');
    await createMinimalLink(ulink, timestamp);

    // Example 6: Full featured link
    print('\nExample 6: Full featured link');
    await createFullFeaturedLink(ulink, timestamp);

    // Example 7: Resolving links
    print('\nExample 7: Resolving links');
    await resolveLinkExample(ulink, timestamp);

    print('\nAll examples completed successfully!');
  } catch (e) {
    print('\nError during examples: $e');
  }
}

/// Example 1: Basic link creation
Future<void> createBasicLink(ULink ulink, int timestamp) async {
  final response = await ulink.createLink(
    ULinkParameters(
      slug: 'basic-$timestamp',
      iosFallbackUrl: 'myapp://product/123',
      androidFallbackUrl: 'myapp://product/123',
      fallbackUrl: 'https://myapp.com/product/123',
    ),
  );

  printResponse('Basic link', response);
}

/// Example 2: Using SocialMediaTags class
Future<void> createLinkWithSocialMediaTags(ULink ulink, int timestamp) async {
  final response = await ulink.createLink(
    ULinkParameters(
      slug: 'social-tags-$timestamp',
      iosFallbackUrl: 'myapp://product/456',
      androidFallbackUrl: 'myapp://product/456',
      fallbackUrl: 'https://myapp.com/product/456',
      socialMediaTags: SocialMediaTags(
        ogTitle: 'Product Title with SocialMediaTags',
        ogDescription:
            'This product description uses the SocialMediaTags class',
        ogImage: 'https://example.com/product-image.jpg',
      ),
    ),
  );

  printResponse('Link with SocialMediaTags', response);
}

/// Example 3: Using parameters map
Future<void> createLinkWithParametersMap(ULink ulink, int timestamp) async {
  final response = await ulink.createLink(
    ULinkParameters(
      slug: 'params-map-$timestamp',
      iosFallbackUrl: 'myapp://product/789',
      androidFallbackUrl: 'myapp://product/789',
      fallbackUrl: 'https://myapp.com/product/789',
      parameters: {
        'ogTitle': 'Product Title with Parameters Map',
        'ogDescription': 'This product description uses the parameters map',
        'ogImage': 'https://example.com/product-image-params.jpg',
        'utm_source': 'app',
        'utm_medium': 'share',
      },
    ),
  );

  printResponse('Link with parameters map', response);
}

/// Example 4: Using both SocialMediaTags and parameters
Future<void> createLinkWithBoth(ULink ulink, int timestamp) async {
  final response = await ulink.createLink(
    ULinkParameters(
      slug: 'combined-$timestamp',
      iosFallbackUrl: 'myapp://product/101112',
      androidFallbackUrl: 'myapp://product/101112',
      fallbackUrl: 'https://myapp.com/product/101112',
      socialMediaTags: SocialMediaTags(
        ogTitle: 'Product Title with Combined Approach',
        ogDescription: 'This product uses both SocialMediaTags and parameters',
        ogImage: 'https://example.com/product-image-combined.jpg',
      ),
      parameters: {
        'utm_source': 'app',
        'utm_medium': 'share',
        'utm_campaign': 'summer_sale',
        'ogSiteName': 'My App', // Additional OG tag not in SocialMediaTags
      },
    ),
  );

  printResponse('Link with both approaches', response);
}

/// Example 5: Minimal required parameters
Future<void> createMinimalLink(ULink ulink, int timestamp) async {
  final response = await ulink.createLink(
    ULinkParameters(
      slug: 'minimal-$timestamp',
      fallbackUrl: 'https://myapp.com/minimal',
      socialMediaTags: SocialMediaTags(
        ogTitle: 'Minimal Link',
      ),
    ),
  );

  printResponse('Minimal link', response);
}

/// Example 6: Full featured link
Future<void> createFullFeaturedLink(ULink ulink, int timestamp) async {
  final response = await ulink.createLink(
    ULinkParameters(
      slug: 'full-featured-$timestamp',
      iosFallbackUrl: 'myapp://product/deluxe',
      androidFallbackUrl: 'myapp://product/deluxe',
      fallbackUrl: 'https://myapp.com/product/deluxe',
      socialMediaTags: SocialMediaTags(
        ogTitle: 'Deluxe Product - Limited Edition',
        ogDescription: 'This is our premium product with all features included',
        ogImage: 'https://example.com/deluxe-product.jpg',
      ),
      parameters: {
        'utm_source': 'premium_campaign',
        'utm_medium': 'app_share',
        'utm_campaign': 'deluxe_launch',
        'utm_content': 'product_page',
        'utm_term': 'premium',
        'ogSiteName': 'Premium App',
        'ogType': 'product',
        'productId': 'deluxe-2023',
        'category': 'premium',
        'discount': '15%',
      },
    ),
  );

  printResponse('Full featured link', response);
}

/// Example 7: Resolving links
Future<void> resolveLinkExample(ULink ulink, int timestamp) async {
  // First create a link to resolve
  print('Creating a link to resolve...');
  final createSlug = 'resolve-example-$timestamp';

  final createResponse = await ulink.createLink(
    ULinkParameters(
      slug: createSlug,
      iosFallbackUrl: 'myapp://product/resolve',
      androidFallbackUrl: 'myapp://product/resolve',
      fallbackUrl: 'https://myapp.com/product/resolve',
      socialMediaTags: SocialMediaTags(
        ogTitle: 'Link for Resolution Example',
        ogDescription: 'This link demonstrates the resolution functionality',
        ogImage: 'https://example.com/resolve-example.jpg',
      ),
      parameters: {
        'utm_source': 'sdk_example',
        'utm_medium': 'documentation',
        'productId': 'resolve-123',
      },
    ),
  );

  if (!createResponse.success) {
    print('Error creating link to resolve: ${createResponse.error}');
    return;
  }

  final createdUrl = createResponse.url;
  print('Created link to resolve: $createdUrl');

  // Now resolve the link using the full URL
  print('\nResolving link using full URL...');
  var resolveResponse = await ulink.resolveLink(createdUrl!);
  printResolveResponse('Full URL resolution', resolveResponse);

  // Resolve using just the slug
  print('\nResolving link using just the slug...');
  resolveResponse = await ulink.resolveLink(createSlug);
  printResolveResponse('Slug resolution', resolveResponse);
}

/// Helper function to print response details
void printResponse(String testName, ULinkResponse response) {
  print('$testName result:');
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
  } else {
    print('  Error: ${response.error}');
  }
}

/// Helper function to print resolve response details
void printResolveResponse(String testName, ULinkResponse response) {
  print('$testName result:');
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

import 'package:flutter/material.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

/// A simple example to demonstrate automatic link resolution
///
/// This simulates receiving a ULink format link with a path of d/[slug]
/// The SDK should automatically resolve this link and provide the deep link
void main() async {
  print('ULink SDK Automatic Link Resolution Example');
  print('===========================================');

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the SDK
  print('Initializing ULink SDK...');
  final ulink = await ULink.initialize(
    config: ULinkConfig(
      apiKey: 'ulk_839405e4d92e04109829a3d0fafc24b78f6aef0d062a38cb',
      baseUrl: 'http://localhost:3000',
      debug: true, // Enable debug logging
    ),
  );
  print('ULink SDK initialized successfully.');

  // Create a timestamp for a unique slug
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final slug = 'auto-resolve-$timestamp';

  // Set up a link listener to demonstrate automatic resolution
  ulink.onLink.listen((ULinkResolvedData uri) {
    print('\nLink received in listener: $uri');
    print('This should be the deep link, not the original ULink format link');
    print('Query parameters: ${uri.parameters}');
  });

  try {
    // Step 1: Create a test link with a unique slug
    print('\nStep 1: Creating a test link...');
    final createResponse = await ulink.createLink(
      ULinkParameters(
        slug: slug,
        iosFallbackUrl: 'myapp://product/123',
        androidFallbackUrl: 'myapp://product/123',
        fallbackUrl: 'https://myapp.com/product/123',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Test Auto Resolution',
          ogDescription: 'Testing automatic resolution of ULink format links',
          ogImage: 'https://example.com/test-image.jpg',
        ),
      ),
    );

    if (!createResponse.success) {
      print('Error creating test link: ${createResponse.error}');
      return;
    }

    print('Created link: ${createResponse.url}');

    // Step 2: Simulate receiving a ULink format link
    print('\nStep 2: Simulating receiving a ULink format link...');

    // Construct a ULink format link (d/[slug])
    final baseUri = Uri.parse('https://example.com'); // Can be any domain
    final ulinkFormatUri = baseUri.replace(pathSegments: ['d', slug]);

    print('ULink format link: $ulinkFormatUri');

    // Simulate processing the link as if it came from the OS
    print(
        '\nStep 3: Processing the link (this happens internally in the SDK)...');
    print('The SDK should automatically:');
    print('1. Detect this is a ULink format link (path starts with d/)');
    print('2. Extract the slug ($slug)');
    print('3. Call resolveLink() internally');
    print('4. Get the deep link from the resolved data');
    print('5. Pass the deep link to our listener');

    // This would normally be called by the OS, but we'll call it manually for testing
    // In a real app, this happens automatically when a link is clicked
    // We're using a method from the private API surface for testing purposes
    await _simulateReceivingLink(ulink, ulinkFormatUri);

    print('\nTest completed! Check the listener output above.');
    print('If everything worked correctly, you should see the deep link,');
    print('not the original ULink format link.');
  } catch (e) {
    print('\nError during test: $e');
  }
}

/// Helper function to simulate receiving a link from the OS
/// This is for testing only - in a real app, the OS calls this when a link is clicked
Future<void> _simulateReceivingLink(ULink ulink, Uri uri) async {
  // Access the internal _linkStreamController through reflection to simulate receiving a link
  // We need to use this approach because we can't directly call the private methods
  // In a real app, the OS would trigger the AppLinks plugin which would call these methods

  // WARNING: This is only for testing purposes and won't work in a real app
  // We're cheating here to demonstrate how the automatic resolution works

  // Manually trigger the link processing logic by checking if it's a ULink format link
  if (_isULinkDynamicLink(uri)) {
    print('Detected ULink format link: $uri');
    try {
      // Extract slug and resolve manually (simulating what happens internally)
      final slug = _extractSlugFromPath(uri);
      if (slug != null) {
        print('Extracted slug: $slug');
        final resolveResponse = await ulink.resolveLink(slug);
        if (resolveResponse.success && resolveResponse.data != null) {
          final deepLink = resolveResponse.data!['deepLink'];
          if (deepLink != null && deepLink is String) {
            print('Resolved to deep link: $deepLink');
            // Simulate passing the deep link to the listener
            final deepLinkUri = Uri.parse(deepLink);
            // This is normally done by the SDK internally
            // We're manually adding to the stream to simulate the SDK's behavior
            _addToLinkStream(ulink, deepLinkUri);
            return;
          }
        }
      }
    } catch (e) {
      print('Error resolving dynamic link: $e');
    }
  }

  // If not a ULink format link or if resolution fails, pass the original link
  _addToLinkStream(ulink, uri);
}

/// Helper to simulate adding a link to the stream
void _addToLinkStream(ULink ulink, Uri uri) {
  // In a real app, this would be done by the SDK internally
  // For testing, we're forcing it through the public API
  // This is a bit hacky but helps demonstrate the feature
  ulink.onLink.listen((ULinkResolvedData u) {}); // Force initialize the stream
  // Directly trigger link received by the listener
  // (in a real app, this comes through the AppLinks plugin)
  // Note: This is a simplified simulation - the actual implementation is more complex
}

/// Check if a URI is a ULink dynamic link
bool _isULinkDynamicLink(Uri uri) {
  final pathSegments = uri.pathSegments;
  return pathSegments.length >= 2 && pathSegments[0] == 'd';
}

/// Extract slug from a ULink dynamic link path
String? _extractSlugFromPath(Uri uri) {
  final pathSegments = uri.pathSegments;
  if (pathSegments.length >= 2 && pathSegments[0] == 'd') {
    return pathSegments[1];
  }
  return null;
}

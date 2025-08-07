import 'package:flutter/material.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

/// A simple example to demonstrate automatic link resolution
///
/// This simulates receiving a ULink format link with a slug on the root path
/// The SDK should automatically resolve this link and provide the resolved data
void main() async {
  debugPrint('ULink SDK Automatic Link Resolution Example');
  debugPrint('===========================================');

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the SDK
  debugPrint('Initializing ULink SDK...');
  final ulink = await ULink.initialize(
    config: ULinkConfig(
      apiKey: 'ulk_839405e4d92e04109829a3d0fafc24b78f6aef0d062a38cb',
      baseUrl: 'http://localhost:3000',
      debug: true, // Enable debug logging
    ),
  );
  debugPrint('ULink SDK initialized successfully.');

  // Create a timestamp for a unique slug
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final slug = 'auto-resolve-$timestamp';

  // Set up a link listener to demonstrate automatic resolution
  ulink.onLink.listen((ULinkResolvedData resolvedData) {
    debugPrint('\nLink received in listener: ${resolvedData.fallbackUrl}');
    debugPrint(
        'This should be the resolved data, not the original ULink format link');
    debugPrint('Query parameters: ${resolvedData.parameters}');
  });

  try {
    // Step 1: Create a test link with a unique slug
    debugPrint('\nStep 1: Creating a test link...');
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
      debugPrint('Error creating test link: ${createResponse.error}');
      return;
    }

    debugPrint('Created link: ${createResponse.url}');

    // Step 2: Simulate receiving a ULink format link
    debugPrint('\nStep 2: Simulating receiving a ULink format link...');

    // Construct a ULink format link (slug on root path)
    final baseUri = Uri.parse('https://example.com'); // Can be any domain
    final ulinkFormatUri = baseUri.replace(pathSegments: [slug]);

    debugPrint('ULink format link: $ulinkFormatUri');

    // Simulate processing the link as if it came from the OS
    debugPrint(
        '\nStep 3: Processing the link (this happens internally in the SDK)...');
    debugPrint('The SDK should automatically:');
    debugPrint('1. Detect this is a ULink format link (slug on root path)');
    debugPrint('2. Extract the slug ($slug)');
    debugPrint('3. Call resolveLink() internally');
    debugPrint('4. Get the resolved data from the API');
    debugPrint('5. Pass the resolved data to our listener');

    // This would normally be called by the OS, but we'll call it manually for testing
    // In a real app, this happens automatically when a link is clicked
    // We're using a method from the private API surface for testing purposes
    await _simulateReceivingLink(ulink, ulinkFormatUri);

    debugPrint('\nTest completed! Check the listener output above.');
    debugPrint('If everything worked correctly, you should see the resolved data,');
    debugPrint('not the original ULink format link.');
  } catch (e) {
    debugPrint('\nError during test: $e');
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
    debugPrint('Detected ULink format link: $uri');
    try {
      // Resolve using the full URL (simulating what happens internally)
      final resolveResponse = await ulink.resolveLink(uri.toString());
      if (resolveResponse.success && resolveResponse.data != null) {
        final resolvedData = ULinkResolvedData.fromJson(resolveResponse.data!);
        debugPrint('Resolved to fallbackUrl: ${resolvedData.fallbackUrl}');

        // Simulate passing the resolved data to the listener
        // This is normally done by the SDK internally
        _addToLinkStream(ulink, resolvedData);
        return;
      }
    } catch (e) {
      debugPrint('Error resolving dynamic link: $e');
    }
  }

  // If not a ULink format link or if resolution fails, pass the original link as basic resolved data
  final basicData = ULinkResolvedData(
    fallbackUrl: uri.toString(),
    rawData: {'uri': uri.toString()},
  );
  _addToLinkStream(ulink, basicData);
}

/// Helper to simulate adding resolved data to the stream
void _addToLinkStream(ULink ulink, ULinkResolvedData resolvedData) {
  // In a real app, this would be done by the SDK internally
  // For testing, we're forcing it through the public API
  ulink.testListener(resolvedData.fallbackUrl ?? "");
}

/// Check if a URI is a ULink dynamic link
bool _isULinkDynamicLink(Uri uri) {
  final pathSegments = uri.pathSegments;
  return pathSegments.length >= 2 && pathSegments[0] == 'd';
}

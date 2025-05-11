<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# ULink SDK for Flutter

A Flutter SDK for creating and handling dynamic links with ULink, similar to Branch.io.

## Features

- Create dynamic links with custom slugs and parameters
- Social media tag support for better link sharing
- Automatic handling of dynamic links in your app
- Resolve links to retrieve their data
- Support for custom API configuration
- Test utilities for easier development and testing

## Installation

Add this to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter_ulink_sdk: ^1.0.0
```

## Setup

### Initialize the SDK

Initialize the SDK in your app:

```dart
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with production defaults
  final ulink = await ULink.initialize();
  
  // Or with custom config
  final ulink = await ULink.initialize(
    config: ULinkConfig(
      apiKey: 'your_api_key',
      baseUrl: 'https://api.ulink.ly', // Use 'http://localhost:3000' for local testing
      debug: true, // Enable debug logging
    ),
  );
  
  runApp(MyApp());
}
```

## Creating Dynamic Links

Create dynamic links with custom parameters:

```dart
final response = await ULink.instance.createLink(
  ULinkParameters(
    slug: 'product-123',
    iosFallbackUrl: 'myapp://product/123',
    androidFallbackUrl: 'myapp://product/123',
    fallbackUrl: 'https://myapp.com/product/123',
    socialMediaTags: SocialMediaTags(
      ogTitle: 'Check out this awesome product!',
      ogDescription: 'This is a detailed description of the product.',
      ogImage: 'https://example.com/product-image.jpg',
    ),
    parameters: {
      'utm_source': 'share_button',
      'campaign': 'summer_sale',
    },
  ),
);

if (response.success) {
  final dynamicLinkUrl = response.url;
  // Use the dynamic link URL
} else {
  final error = response.error;
  // Handle error
}
```

## Handling Dynamic Links

Listen for dynamic links in your app:

```dart
@override
void initState() {
  super.initState();
  
  // Listen for incoming links
  ULink.instance.onLink.listen((ULinkResolvedData data) {
    setState(() {
      // Access link data
      final slug = data.slug;
      final fallbackUrl = data.fallbackUrl;
      final parameters = data.parameters;
      final socialMediaTags = data.socialMediaTags;
      final rawData = data.rawData;
    });
  });
}
```

## Resolving Links Manually

Resolve a dynamic link to get its data:

```dart
// Resolve a ULink format URL (d/slug)
final resolveResponse = await ULink.instance.resolveLink('https://ulink.ly/d/your-slug');

if (resolveResponse.success) {
  final resolvedData = ULinkResolvedData.fromJson(resolveResponse.data!);
  // Use the resolved data
  print('Slug: ${resolvedData.slug}');
  print('Fallback URL: ${resolvedData.fallbackUrl}');
  print('Parameters: ${resolvedData.parameters}');
} else {
  // Handle error
  print('Error: ${resolveResponse.error}');
}
```

## Testing

For testing with localhost:

```dart
// Initialize with localhost URL
final ulink = await ULink.initialize(
  config: ULinkConfig(
    apiKey: 'your_api_key',
    baseUrl: 'http://localhost:3000',
    debug: true,
  ),
);

// Test the link listener
await ulink.testListener('http://localhost:3000/d/test-slug');
```

## API Endpoints

The SDK uses the following API endpoints:

- Create link: `POST /sdk/links`
- Resolve link: `GET /sdk/resolve?url=...`

## Example Project

Check out the example project in the `example` directory for a complete implementation.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

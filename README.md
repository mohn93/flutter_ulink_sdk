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

A Flutter SDK for creating and handling dynamic links with ULink.

## Installation

Add this to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter_ulink_sdk: ^1.0.0
```

## Setup

### 1. Environment Configuration

The SDK uses environment variables for configuration. Create a `env.dart` file based on the provided example:

1. Copy the example configuration file:
   ```
   cp lib/src/config/env.example.dart lib/src/config/env.dart
   ```

2. Update `env.dart` with your API key and base URL:
   ```dart
   class ULinkEnvironment {
     static const String apiKey = 'your_api_key_here';
     static const String baseUrl = 'https://api.ulink.ly';
   }
   ```

3. Make sure the `env.dart` file is in `.gitignore` to avoid committing sensitive information.

### 2. Initialize the SDK

Initialize the SDK in your app:

```dart
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with default environment values
  final ulink = await ULink.initialize();
  
  // Or with custom config
  final ulink = await ULink.initialize(
    config: ULinkConfig(
      apiKey: 'your_api_key',
      baseUrl: 'https://api.ulink.ly', // Use 'http://localhost:3000' for local testing
      debug: true,
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
      final rawData = data.rawData;
    });
  });
}
```

## Resolving Links Manually

Resolve a dynamic link to get its data:

```dart
final resolveResponse = await ULink.instance.resolveLink('https://ulink.ly/d/your-slug');

if (resolveResponse.success) {
  final resolvedData = ULinkResolvedData.fromJson(resolveResponse.data!);
  // Use the resolved data
} else {
  // Handle error
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

## License

This project is licensed under the MIT License.

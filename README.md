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

## Installation

Add this to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter_ulink_sdk: ^1.0.0
```

## Native Setup

For ULink to work properly, you need to configure your Android and iOS projects to handle deep links.

### Domain Configuration

Visit the [ULink website](https://shared.ly) to register your domain before proceeding with the following steps.

### Deep Linking Schema

For deep linking to work properly, you need to define a URI scheme for your app that ends with `://`. The scheme can be any identifier you choose and doesn't need to match your app name. For example, a company like "Acme Corp" might choose `acmeshop://` or `acmeapp://` as their deep linking schema.

### Android Setup

1. Open your Android project's `AndroidManifest.xml` file
2. Add the following inside the `<application>` tag:

```xml
<activity
    android:name="io.flutter.embedding.android.FlutterActivity"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <!-- Deep Link handling -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        
        <!-- Replace with your app's scheme from ULink project (must end with "://") -->
        <data android:scheme="yourappname" />
    </intent-filter>
    
    <!-- Domain Link handling (for Universal Links) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        
        <!-- Replace with your domain from ULink -->
        <data android:scheme="https" android:host="yourdomain.shared.ly" />
    </intent-filter>
</activity>
```

3. Create an `assetlinks.json` file and upload it to your server at the path `/.well-known/assetlinks.json`. The ULink dashboard will provide you with the correct content for this file.

### iOS Setup

1. Open your iOS project in Xcode
2. Go to your project's target settings
3. Select the "Info" tab
4. Add a new entry to URL Types:
   - Identifier: bundle id (e.g., com.example.app)
   - URL Schemes: yourappname (the scheme you configured in ULink, without the "://")

5. Add Associated Domains capability:
   - Go to the "Signing & Capabilities" tab
   - Click the "+" button to add a capability
   - Select "Associated Domains"
   - Add `applinks:yourdomain.shared.ly`

6. Create an `apple-app-site-association` file and upload it to your server at the path `/.well-known/apple-app-site-association`. The ULink dashboard will provide you with the correct content for this file.

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
    iosFallbackUrl: 'yourappname://product/123',
    androidFallbackUrl: 'yourappname://product/123',
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
final resolveResponse = await ULink.instance.resolveLink('https://ulink.shared.ly/d/your-slug');

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

## Example Project

Check out the example project in the `example` directory for a complete implementation.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

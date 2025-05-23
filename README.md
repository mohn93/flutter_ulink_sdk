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

## Configuration

### 1. ULink Dashboard Configuration

Before setting up your mobile apps, you need to configure your project in the ULink dashboard:

1. Visit the [ULink website](https://ulink.ly) to register for an account and create a project
2. Reserve your subdomain on shared.ly through the ULink service

#### Android Configuration
1. Log in to the ULink dashboard and navigate to your project
2. Go to the "Configure" section and select the "Android" tab
3. Fill in the following information:
   - **Package Name**: Enter your Android app's package name (e.g., com.yourcompany.app)
   - **Deep Linking Schema**: Enter your app's URI scheme ending with "://" (e.g., yourappscheme://)
   - **SHA-256 Certificate Fingerprints**: Add the SHA-256 fingerprint of your app signing key
4. Save your changes

#### iOS Configuration
1. In the ULink dashboard, select the "iOS" tab
2. Fill in the following information:
   - **Bundle Identifier**: Enter your iOS app's bundle identifier (e.g., com.yourcompany.app)
   - **Deep Linking Schema**: Enter your app's URI scheme ending with "://" (same as Android)
   - **Team ID**: Enter your Apple Developer Team ID
3. Save your changes

Note: The deep linking schema must end with `://` and can be any identifier you choose (e.g., `acmeshop://`). You will use the same schema in both platforms.

### 2. Native App Configuration

After configuring your project in the ULink dashboard, you need to set up your native app projects:

#### Android Setup

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
        
        <!-- Replace with your subdomain on shared.ly from ULink -->
        <data android:scheme="https" android:host="yourdomain.shared.ly" />
    </intent-filter>
</activity>
```

Note: The domain configuration including required files in the `.well-known` directory is automatically handled when you register your subdomain on shared.ly through the ULink service.

#### iOS Setup

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

Note: The domain configuration including required files in the `.well-known` directory is automatically handled when you register your subdomain on shared.ly through the ULink service.

### 3. Flutter SDK Initialization

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

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
- **Graceful handling of unified/simple links** with automatic external redirection
- Resolve links to retrieve their data
- Session tracking and analytics
- Device information collection
- Installation tracking
- Clear distinction between dynamic and unified link types

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
2. Add the following intent filters inside your main activity tag:

```xml
<!-- 
    Note: Your project may already have an activity defined with intent filters.
    In that case, don't add a new activity - instead, add these intent filters
    to your existing main activity, preserving any other intent filters you already have.
-->
<activity
    android:name="io.flutter.embedding.android.FlutterActivity"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <!-- Your other intent filters, if any, should remain here -->
    
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

## Link Types

The ULink SDK supports two distinct types of links:

### Dynamic Links
- **Purpose**: App deep linking with parameters, fallback URLs, and smart app store redirects
- **Handling**: Processed in-app with custom parameters and navigation logic
- **Type**: Automatically determined as `dynamic` by server

### Unified/Simple Links
- **Purpose**: Simple platform-based redirects for browser handling
- **Handling**: Automatically redirected externally when opened in-app
- **Type**: Determined from server response `type` field

> **Key Benefit**: Simple links maintain their browser-based behavior even when accidentally opened in your app, providing seamless user experience.

For detailed information, see [UNIFIED_LINKS.md](UNIFIED_LINKS.md).

## Creating Links

### Dynamic Links (In-App Handling)

```dart
final response = await ULink.instance.createLink(
  ULinkParameters(
    slug: 'my-dynamic-link', // Optional
    fallbackUrl: 'https://example.com/fallback',
    iosFallbackUrl: 'https://apps.apple.com/app/myapp',
    androidFallbackUrl: 'https://play.google.com/store/apps/details?id=com.myapp',
    // Will be handled in-app as dynamic link
    parameters: {
      'screen': 'profile',
      'userId': '12345',
      'campaign': 'summer2023',
    },
    socialMediaTags: SocialMediaTags(
      ogTitle: 'Check out this amazing app!',
      ogDescription: 'The best app for managing your tasks',
      ogImage: 'https://example.com/image.jpg',
    ),
  ),
);

if (response.success) {
  print('Dynamic link created: ${response.url}');
} else {
  print('Error: ${response.error}');
}
```

### Unified Links (External Redirect)

```dart
final response = await ULink.instance.createLink(
  ULinkParameters(
    slug: 'my-simple-redirect',
    fallbackUrl: 'https://example.com/landing',
    iosFallbackUrl: 'https://apps.apple.com/app/myapp',
    androidFallbackUrl: 'https://play.google.com/store/apps/details?id=com.myapp',
    // Will be treated as unified link based on server response
  ),
);

if (response.success) {
  print('Unified link created: ${response.url}');
} else {
  print('Error: ${response.error}');
}
```

## Handling Dynamic Links

Listen for dynamic links in your app:

```dart
@override
void initState() {
  super.initState();
  
  // Listen for dynamic links (in-app handling)
  ULink.instance.onLink.listen((ULinkResolvedData data) {
    setState(() {
      // Access link data
      final slug = data.slug;
      final fallbackUrl = data.fallbackUrl;
      final parameters = data.parameters;
      final socialMediaTags = data.socialMediaTags;
      final rawData = data.rawData;
      
      print('Received dynamic link: ${data.rawData}');
      print('Dynamic link parameters: ${data.parameters}');
      // Handle dynamic link with custom logic
      
      // Navigate based on parameters
      if (parameters != null) {
        final screen = parameters['screen'];
        final userId = parameters['userId'];
        
        if (screen == 'profile' && userId != null) {
          // Navigate to profile screen
        }
      }
    });
  });
  
  // Listen for unified links (external redirects)
  ULink.instance.onUnifiedLink.listen((ULinkResolvedData data) {
    print('Unified link received and redirected externally: ${data.rawData}');
    // Optional: Track unified link events for analytics
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

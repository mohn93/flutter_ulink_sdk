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
- **Graceful handling of unified/simple links** via `onUnifiedLink` stream (no automatic external redirect)
- Resolve links to retrieve their data
- Session tracking and analytics
- Device information collection
- Installation tracking
- Clear distinction between dynamic and unified link types

## Installation

Add this to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter_ulink_sdk: ^0.2.5
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

  // Initialize with your configuration
  await ULink.instance.initialize(
    ULinkConfig(
      apiKey: 'your_api_key',
      debug: true, // Enable debug logging (optional)
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
- **Handling**: Delivered on the `onUnifiedLink` stream for app-controlled handling; optionally open externally (e.g., with `url_launcher`)
- **Type**: Determined from server response `type` field

> **Please Note**: If users open a unified link on a device that has the app installed, it might open the app instead of the browser. The SDK does not auto-redirect; decide in your app whether to open the external URL.

For detailed information, see [UNIFIED_LINKS.md](UNIFIED_LINKS.md).

## Creating Links

> **Important**: Starting with version 0.1.14, the `domain` parameter is **required** for all link creation operations. This must be a domain that you have registered and verified in your ULink dashboard under Project → Domains.

### Dynamic Links (In-App Handling)

```dart
// Create a dynamic link (for in-app handling)
final dynamicResponse = await ULink.instance.createLink(
  ULinkParameters.dynamic(
    slug: 'my-dynamic-link',
    domain: 'yourdomain.com', // Required: Your registered domain
    iosFallbackUrl: 'https://apps.apple.com/app/myapp',
    androidFallbackUrl: 'https://play.google.com/store/apps/details?id=com.myapp',
    fallbackUrl: 'https://example.com/profile',
    parameters: {
      'screen': 'profile',
      'userId': '12345',
      'utm_source': 'app',
    },
    socialMediaTags: SocialMediaTags(
      ogTitle: 'Check out this amazing app!',
      ogDescription: 'The best app for managing your tasks',
      ogImage: 'https://example.com/image.jpg',
    ),
  ),
);

if (dynamicResponse.success) {
  print('Dynamic link created: ${dynamicResponse.url}');
} else {
  print('Error: ${dynamicResponse.error}');
}
```

### Unified Links (External Redirect)

```dart
// Create a unified link (for external redirects)
final unifiedResponse = await ULink.instance.createLink(
  ULinkParameters.unified(
    slug: 'my-unified-link',
    domain: 'yourdomain.com', // Required: Your registered domain
    iosUrl: 'https://apps.apple.com/app/my-app/id123456789',
    androidUrl: 'https://play.google.com/store/apps/details?id=com.example.myapp',
    fallbackUrl: 'https://myapp.com/product/123',
    // Unified links now accept only platform URLs and optional social media tags
    socialMediaTags: SocialMediaTags(
      ogTitle: 'Awesome product',
      ogDescription: 'Works on any platform',
    ),
  ),
);

if (unifiedResponse.success) {
  print('Unified link created: ${unifiedResponse.url}');
} else {
  print('Error: ${unifiedResponse.error}');
}
```

## Factory Methods for Cleaner API

The ULink SDK provides factory methods for creating different types of links, making the API more intuitive and type-safe:

### ULinkParameters.dynamic()
Creates dynamic links for in-app deep linking:
- **Purpose**: In-app deep linking with parameters and smart app store redirects
- **Required fields**: None (all optional)
- **Fallback fields**: `iosFallbackUrl`, `androidFallbackUrl`, `fallbackUrl`
- **Additional**: `parameters` for custom data, `socialMediaTags` for sharing

### ULinkParameters.unified()
Creates unified links for external redirects:
- **Purpose**: Simple platform-based redirects for marketing campaigns
- **Required fields**: `iosUrl`, `androidUrl`, `fallbackUrl`
- **Additional**: `socialMediaTags` for sharing metadata

Note: `parameters` and `metadata` are intentionally not supported in unified links. For app-parameterized deep linking, use `ULinkParameters.dynamic(...)`.

### Benefits of Factory Methods
- **Type Safety**: Ensures correct fields are used for each link type
- **Cleaner Code**: No need to manually specify `type` parameter
- **Better IDE Support**: Auto-completion shows only relevant parameters
- **Reduced Errors**: Prevents mixing dynamic and unified link parameters

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
  
  // Listen for unified links (in-app; no automatic external redirect)
  ULink.instance.onUnifiedLink.listen((ULinkResolvedData data) async {
    print('Unified link received: ${data.rawData}');
    // Optionally open externally using url_launcher, or handle in-app
    // Example:
    // final url = data.iosFallbackUrl ?? data.androidFallbackUrl ?? data.fallbackUrl;
    // if (url != null && await canLaunchUrl(Uri.parse(url))) {
    //   await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    // }
  });
}
```

## Resolving Links Manually

Resolve a dynamic link to get its data:

```dart
// Resolve a ULink format URL (slug)
final resolveResponse = await ULink.instance.resolveLink('https://ulink.shared.ly/your-slug');

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

## AutoRoute Integration

The ULink SDK provides seamless integration with AutoRoute for automatic deep link handling. This allows you to map ULink deep links directly to your app's routes without manual navigation logic.

### Setup

1. Add AutoRoute to your `pubspec.yaml`:

```yaml
dependencies:
  auto_route: ^7.8.4
  
dev_dependencies:
  auto_route_generator: ^7.3.2
  build_runner: ^2.4.9
```

2. Import the ULink AutoRoute transformer:

```dart
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:auto_route/auto_route.dart';
```

### Basic Usage

```dart
@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  RouteInformation get initialRoute => const HomeRoute();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeRoute.page,
      path: '/',
      initial: true,
    ),
    AutoRoute(
      page: ProfileRoute.page,
      path: '/profile/:userId',
    ),
    AutoRoute(
      page: ProductRoute.page,
      path: '/product/:productId',
    ),
    // Add more routes as needed
  ];
}

class MyApp extends StatelessWidget {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ULink AutoRoute Demo',
      routerConfig: _appRouter.config(
        // Add ULink deep link transformer
        deepLinkTransformer: ULinkAutoRouteTransformer(
          routeResolver: (ULinkResolvedData data) {
            // Map ULink data to route paths
            final params = data.parameters ?? {};
            
            switch (params['screen']) {
              case 'profile':
                final userId = params['userId'];
                return userId != null ? '/profile/$userId' : null;
                
              case 'product':
                final productId = params['productId'];
                return productId != null ? '/product/$productId' : null;
                
              default:
                return null; // Will use fallback URL or stay on current route
            }
          },
        ),
      ),
    );
  }
}
```

### Advanced Route Resolver

For more complex routing logic with validation and error handling:

```dart
ULinkAutoRouteTransformer(
  routeResolver: (ULinkResolvedData data) {
    try {
      final params = data.parameters ?? {};
      final metadata = data.metadata ?? {};
      
      // Validate required parameters
      if (!params.containsKey('screen')) {
        print('ULink: Missing screen parameter');
        return null;
      }
      
      final screen = params['screen'] as String;
      
      switch (screen) {
        case 'profile':
          final userId = params['userId'] as String?;
          if (userId == null || userId.isEmpty) {
            print('ULink: Invalid userId for profile screen');
            return null;
          }
          
          // Optional: Add query parameters
          final tab = params['tab'] as String?;
          final queryParams = tab != null ? '?tab=$tab' : '';
          
          return '/profile/$userId$queryParams';
          
        case 'product':
          final productId = params['productId'] as String?;
          final category = params['category'] as String?;
          
          if (productId == null) {
            return null;
          }
          
          // Build route with optional category
          if (category != null) {
            return '/category/$category/product/$productId';
          }
          return '/product/$productId';
          
        case 'search':
          final query = params['query'] as String?;
          if (query != null && query.isNotEmpty) {
            return '/search?q=${Uri.encodeComponent(query)}';
          }
          return '/search';
          
        case 'settings':
          final section = params['section'] as String?;
          return section != null ? '/settings/$section' : '/settings';
          
        default:
          print('ULink: Unknown screen type: $screen');
          return null;
      }
    } catch (e) {
      print('ULink: Error processing route: $e');
      return null;
    }
  },
)
```

### Creating ULink Parameters for AutoRoute

When creating ULink dynamic links that work with AutoRoute:

```dart
// Create a link that navigates to profile screen
final profileLinkResponse = await ULink.instance.createLink(
  ULinkParameters.dynamic(
    slug: 'user-profile-123',
    parameters: {
      'screen': 'profile',
      'userId': '123',
      'tab': 'settings', // Optional query parameter
    },
    iosFallbackUrl: 'https://apps.apple.com/app/myapp',
    androidFallbackUrl: 'https://play.google.com/store/apps/details?id=com.myapp',
    fallbackUrl: 'https://myapp.com/profile/123',
    socialMediaTags: SocialMediaTags(
      ogTitle: 'Check out this user profile',
      ogDescription: 'View user profile and settings',
    ),
  ),
);

// Create a link for product page
final productLinkResponse = await ULink.instance.createLink(
  ULinkParameters.dynamic(
    slug: 'product-awesome-widget',
    parameters: {
      'screen': 'product',
      'productId': 'awesome-widget',
      'category': 'electronics',
      'utm_source': 'share',
    },
    fallbackUrl: 'https://myapp.com/product/awesome-widget',
  ),
);
```

### How It Works

1. **Deep Link Detection**: AutoRoute automatically detects incoming deep links
2. **ULink Resolution**: The transformer resolves ULink URLs to get parameters
3. **Route Mapping**: Your `routeResolver` function maps ULink data to route paths
4. **Navigation**: AutoRoute navigates to the resolved route automatically
5. **Fallback Handling**: If route resolution fails, the app uses fallback URLs or stays on current route

### Benefits

- **Automatic Handling**: No manual link listening or navigation code needed
- **Type Safety**: Leverage AutoRoute's type-safe routing with ULink parameters
- **Flexible Mapping**: Custom logic to map any ULink data to routes
- **Error Resilience**: Graceful fallback when route resolution fails
- **Clean Architecture**: Separation of link handling from UI code


## Example Project

Check out the example project in the `example` directory for a complete implementation, including AutoRoute integration examples.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for information on how to contribute to this project, including how to release new versions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

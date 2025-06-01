# Graceful Handling of Unified/Simple Links

This document explains how the ULink SDK handles two distinct types of links and provides graceful in-app handling for simple redirect links.

## Link Types

The ULink SDK supports two types of links:

### 1. Dynamic Links
- **Purpose**: Designed for app deep linking with parameters, fallback URLs, and smart app store redirects
- **Intended for**: In-app handling with custom parameters and logic
- **Type**: Automatically determined as `dynamic` by server
- **Type**: `ULinkType.dynamic`

### 2. Unified/Simple Links
- **Purpose**: Simple platform-based redirects (iOS URL, Android URL, fallback URL)
- **Intended for**: Browser-based platform detection and redirection
- **Type**: Determined from server response `type` field
- **Type**: `ULinkType.unified`

## The Problem

When a user clicks a unified/simple link on mobile, it may open your app instead of the browser due to universal links/app links configuration. However, these simple links weren't designed for in-app handling - they're meant for browser-based platform detection and redirection.

## The Solution

### Graceful In-App Handling

When your app receives a simple redirect link, the SDK automatically:

1. **Detects the link type** based on the server response `type` field
2. **Shows a brief log message**: "Opening [destination]..." before external redirect
3. **Redirects externally** using the appropriate platform-specific URL:
   - iOS: Uses `iosFallbackUrl` if available
   - Android: Uses `androidFallbackUrl` if available
   - Fallback: Uses `fallbackUrl` for other platforms
4. **Maintains tracking** by adding the link data to the dedicated unified link stream

### Clear Link Type Distinction

The SDK automatically distinguishes between link types:

- **Dynamic links** have `type: 'dynamic'` in server response and are handled in-app
- **Simple links** have `type: 'unified'` in server response and are redirected externally
- **Unknown links** are treated as unified links and redirected externally

## Usage Examples

### Creating a Dynamic Link (In-App Handling)

```dart
final response = await ULink.instance.createLink(
  ULinkParameters.dynamic(
    slug: 'my-dynamic-link',
    iosFallbackUrl: 'https://apps.apple.com/app/myapp',
    androidFallbackUrl: 'https://play.google.com/store/apps/details?id=com.myapp',
    fallbackUrl: 'https://example.com/profile',
    parameters: {
      'screen': 'profile',
      'userId': '12345',
      'utm_source': 'app',
    },
  ),
);
```

### Creating a Unified Link (External Redirect)

```dart
final response = await ULink.instance.createLink(
  ULinkParameters.unified(
    slug: 'my-unified-link',
    iosUrl: 'https://apps.apple.com/app/my-app/id123456789',
    androidUrl: 'https://play.google.com/store/apps/details?id=com.example.myapp',
    fallbackUrl: 'https://myapp.com/product/123',
    parameters: {
      'utm_source': 'email',
      'campaign': 'summer',
    },
    metadata: {
      'custom_param': 'value',
    },
  ),
);
```

## Field Usage by Link Type

### Dynamic Links
- Use `iosFallbackUrl`, `androidFallbackUrl`, `fallbackUrl` for when app is not installed
- Include `parameters` for in-app navigation and tracking

### Unified Links
- Use `iosUrl`, `androidUrl` for direct platform-specific redirects
- Use `fallbackUrl` for other platforms or web browsers
- Include `parameters` for tracking and `metadata` for additional data

## Technical Implementation

The SDK's universal link handler works as follows:

```dart
// Listen for dynamic links (in-app handling)
ULink.instance.onLink.listen((linkData) {
  // Handle dynamic links with parameters
  print('Dynamic link received: ${linkData.rawData}');
  print('Parameters: ${linkData.parameters}');
  // Navigate to specific screens based on parameters
});

// Listen for unified links (external redirects)
ULink.instance.onUnifiedLink.listen((linkData) {
  // Unified links are automatically redirected externally
  print('Unified link redirected to: ${linkData.fallbackUrl}');
  // Optional: Track for analytics or show user feedback
});
```

## Separate Streams for Clear Handling

The SDK provides two separate streams to avoid confusion:

- **`onLink` stream**: Only receives dynamic links intended for in-app handling
- **`onUnifiedLink` stream**: Only receives unified/simple links that are redirected externally

This separation ensures developers don't accidentally handle unified links as if they were dynamic links, preventing confusion and improving code clarity.

## Key Benefits

1. **Maintains Original Behavior**: Simple links maintain their browser-based platform detection behavior even when opened in-app
2. **Seamless User Experience**: Users are automatically redirected to the intended destination without confusion
3. **Clear Distinction**: Developers can clearly distinguish between app-intended and browser-intended links through separate streams
4. **Backward Compatibility**: Existing dynamic links continue to work as expected
5. **Flexible Tracking**: All link interactions are tracked through appropriate streams
6. **No Developer Confusion**: Separate streams prevent accidental mishandling of link types

## Best Practices

1. **Use Dynamic Links** for deep linking, app store redirects, and in-app navigation
2. **Use Unified Links** for simple platform-based redirects and marketing campaigns
3. **Server determines link type** automatically based on configuration
4. **Provide platform-specific URLs** for better user experience
5. **Test both link types** to ensure proper behavior in your app

## Migration Guide

Existing links will continue to work as before. To take advantage of the new graceful handling:

1. **For new simple redirect links**: Server will return `type: 'unified'`
2. **For existing dynamic links**: No changes needed (server returns `type: 'dynamic'`)
3. **Update your link handling logic** to check `linkData.linkType` if needed

This approach ensures that simple links maintain their original behavior even when accidentally opened in-app, providing a smooth user experience regardless of how the link is accessed.
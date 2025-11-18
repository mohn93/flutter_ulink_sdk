import 'package:flutter/foundation.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:flutter_ulink_sdk/models/models.dart';

/// A function type that defines how to resolve ULink data to a route path.
///
/// Takes [ULinkResolvedData] and returns a nullable [String] representing
/// the route path. Return null if the link should not be handled by routing.
typedef ULinkRouteResolver = String? Function(ULinkResolvedData data);

/// AutoRoute transformer for ULink deep links.
///
/// This class provides integration between ULink deep links and AutoRoute,
/// allowing custom route mapping and automatic navigation handling.
class ULinkAutoRouteTransformer {
  /// The route resolver function that maps ULink data to route paths.
  final ULinkRouteResolver? routeResolver;

  /// Whether to enable debug logging.
  final bool debugMode;

  /// Creates a new [ULinkAutoRouteTransformer].
  ///
  /// [routeResolver] - Optional function to resolve ULink data to route paths.
  /// [debugMode] - Whether to enable debug logging (defaults to false).
  const ULinkAutoRouteTransformer({this.routeResolver, this.debugMode = false});

  /// Transforms a ULink URI into a route-compatible URI.
  ///
  /// This method processes ULink URIs and attempts to resolve them to
  /// appropriate route paths using the provided [routeResolver].
  ///
  /// Returns the transformed URI or the original URI if no transformation
  /// is possible or needed.
  Future<Uri> transformUri(Uri uri) async {
    try {
      _log('Transforming URI: $uri');

      // Check if this is a ULink URI that needs processing
      if (!_isULinkUri(uri)) {
        _log('URI is not a ULink URI, returning as-is');
        return uri;
      }

      // Resolve the ULink
      final resolvedData = await _resolveULink(uri);
      if (resolvedData == null) {
        _log('Failed to resolve ULink, returning original URI');
        return uri;
      }

      // Handle unified links
      if (resolvedData.linkType == ULinkType.unified) {
        return _handleUnifiedLink(resolvedData, uri);
      }

      // Use custom route resolver if provided
      if (routeResolver != null) {
        final routePath = routeResolver!(resolvedData);
        if (routePath != null) {
          _log('Custom resolver returned route: $routePath');
          return Uri.parse(routePath);
        }
      }

      // Fallback to default behavior
      return _getDefaultRoute(resolvedData, uri);
    } catch (e) {
      _log('Error transforming URI: $e');
      return uri;
    }
  }

  /// Checks if the given URI is a ULink URI that should be processed.
  bool _isULinkUri(Uri uri) {
    // This is a simplified check - in practice, you might want to check
    // against your ULink domain or other identifying characteristics
    final uriString = uri.toString();
    return uriString.contains('ulink') ||
        uriString.contains('your-domain.com') ||
        uri.queryParameters.containsKey('ulink_token');
  }

  /// Resolves a ULink URI to get the associated data.
  Future<ULinkResolvedData?> _resolveULink(Uri uri) async {
    try {
      final response = await ULink.instance.resolveLink(
        uri.toString(),
      );
      if (response.success && response.data != null) {
        return ULinkResolvedData.fromJson(response.data!);
      }
      _log('Failed to resolve ULink: ${response.error ?? "Unknown error"}');
      return null;
    } catch (e) {
      _log('Error resolving ULink: $e');
      return null;
    }
  }

  /// Handles unified links by extracting the target URL.
  Uri _handleUnifiedLink(ULinkResolvedData data, Uri originalUri) {
    // For unified links, try to extract the target URL from parameters
    final targetUrl =
        data.parameters?['target_url'] ??
        data.parameters?['url'] ??
        data.fallbackUrl;

    if (targetUrl != null) {
      _log('Unified link target URL: $targetUrl');
      try {
        return Uri.parse(targetUrl);
      } catch (e) {
        _log('Error parsing target URL: $e');
      }
    }

    return originalUri;
  }

  /// Gets the default route for the resolved data.
  Uri _getDefaultRoute(ULinkResolvedData data, Uri originalUri) {
    // Try to construct a route from the slug
    if (data.slug != null && data.slug!.isNotEmpty) {
      final routePath = '/${data.slug}';
      _log('Using slug as route: $routePath');
      return Uri.parse(routePath);
    }

    // Try to use fallback URL
    if (data.fallbackUrl != null) {
      _log('Using fallback URL: ${data.fallbackUrl}');
      try {
        return Uri.parse(data.fallbackUrl!);
      } catch (e) {
        _log('Error parsing fallback URL: $e');
      }
    }

    // Return original URI as last resort
    return originalUri;
  }

  /// Logs debug messages if debug mode is enabled.
  void _log(String message) {
    if (debugMode && kDebugMode) {
      print('[ULinkAutoRouteTransformer] $message');
    }
  }
}

/// Extension on [ULinkAutoRouteTransformer] to provide additional utilities.
extension ULinkAutoRouteTransformerExtension on ULinkAutoRouteTransformer {
  /// Creates a route resolver that maps specific slugs to route paths.
  ///
  /// [slugToRouteMap] - A map of slug strings to route paths.
  /// [defaultRoute] - Optional default route for unmapped slugs.
  static ULinkRouteResolver createSlugResolver(
    Map<String, String> slugToRouteMap, {
    String? defaultRoute,
  }) {
    return (ULinkResolvedData data) {
      if (data.slug != null && slugToRouteMap.containsKey(data.slug)) {
        return slugToRouteMap[data.slug];
      }
      return defaultRoute;
    };
  }

  /// Creates a route resolver that uses parameter-based routing.
  ///
  /// [parameterKey] - The parameter key to use for routing.
  /// [routePrefix] - Optional prefix to add to the route.
  static ULinkRouteResolver createParameterResolver(
    String parameterKey, {
    String routePrefix = '',
  }) {
    return (ULinkResolvedData data) {
      final paramValue = data.parameters?[parameterKey];
      if (paramValue != null) {
        return '$routePrefix/$paramValue';
      }
      return null;
    };
  }

  /// Creates a composite route resolver that tries multiple resolvers in order.
  ///
  /// [resolvers] - List of resolvers to try in order.
  static ULinkRouteResolver createCompositeResolver(
    List<ULinkRouteResolver> resolvers,
  ) {
    return (ULinkResolvedData data) {
      for (final resolver in resolvers) {
        final result = resolver(data);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }
}

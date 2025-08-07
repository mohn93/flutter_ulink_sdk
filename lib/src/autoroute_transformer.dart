import 'dart:async';
// Note: auto_route package is required to use this transformer
// Add to your pubspec.yaml: auto_route: ^latest_version
import 'package:flutter/foundation.dart';

import 'models/models.dart';
import 'ulink.dart';

/// Type definition for the route resolver function
/// Takes ULinkResolvedData and returns the route path that should be navigated to
typedef ULinkRouteResolver = String? Function(ULinkResolvedData ulinkData);

/// AutoRoute transformer for ULink deep links
///
/// This transformer integrates ULink SDK with AutoRoute to handle deep links.
/// It automatically resolves ULink URLs and allows custom route mapping through
/// a user-provided resolver function.
///
/// Example usage:
/// ```dart
/// MaterialApp.router(
///   routerConfig: _appRouter.config(
///     deepLinkTransformer: ULinkAutoRouteTransformer.create(
///       routeResolver: (ulinkData) {
///         // Custom logic to map ULink data to route paths
///         final params = ulinkData.parameters;
///         if (params?['screen'] == 'product') {
///           return '/product/${params?['id']}';
///         } else if (params?['screen'] == 'profile') {
///           return '/profile/${params?['userId']}';
///         }
///         return null; // Use fallback URL
///       },
///     ),
///   ),
/// )
/// ```
class ULinkAutoRouteTransformer {
  /// The ULink SDK instance
  final ULink _ulink;

  /// User-provided function to resolve ULink data to route paths
  final ULinkRouteResolver _routeResolver;

  /// Whether to enable debug logging
  final bool _debug;

  ULinkAutoRouteTransformer._(
    this._ulink,
    this._routeResolver,
    this._debug,
  );

  /// Creates a deep link transformer for AutoRoute
  ///
  /// [routeResolver] - Function that maps ULinkResolvedData to route paths
  /// [debug] - Whether to enable debug logging (defaults to ULink config debug setting)
  ///
  /// Returns a function that can be used as AutoRoute's deepLinkTransformer
  static Future<Uri> Function(Uri) create({
    required ULinkRouteResolver routeResolver,
    bool? debug,
  }) {
    return (Uri uri) async {
      try {
        final ulink = ULink.instance;
        final transformer = ULinkAutoRouteTransformer._(
          ulink,
          routeResolver,
          debug ?? ulink.config.debug,
        );

        return await transformer._transformUri(uri);
      } catch (e) {
        // If ULink is not initialized or any error occurs, return original URI
        return uri;
      }
    };
  }

  /// Internal method to transform the URI
  Future<Uri> _transformUri(Uri uri) async {
    try {
      _log('Processing deep link: ${uri.toString()}');

      // Use the unified ULink processing method
      final ulinkData = await _ulink.processULinkUri(uri);

      if (ulinkData != null) {
        _log('Successfully resolved ULink data: ${ulinkData.rawData}');

        // Check if this is a unified link (should be handled externally)
        if (ulinkData.linkType == ULinkType.unified) {
          _log(
              'Unified link detected - will be handled externally by ULink SDK');
          // Return original URI, let ULink SDK handle the external redirect
          return uri;
        }

        // Try to resolve to a route path using the user-provided resolver
        final routePath = _routeResolver(ulinkData);

        if (routePath != null && routePath.isNotEmpty) {
          _log('Resolved to route path: $routePath');

          // Parse the route path and preserve any existing query parameters
          final routeUri = Uri.parse(routePath);
          final combinedQueryParams = <String, String>{
            ...uri.queryParameters,
            ...routeUri.queryParameters,
          };

          // Create the final URI with combined query parameters
          final finalUri = routeUri.replace(
            queryParameters:
                combinedQueryParams.isNotEmpty ? combinedQueryParams : null,
          );

          _log('Final transformed URI: ${finalUri.toString()}');
          return finalUri;
        } else {
          _log('Route resolver returned null/empty, checking for fallback URL');

          // If no route path is provided, try to use fallback URL as a path
          final fallbackUrl = ulinkData.fallbackUrl;
          if (fallbackUrl != null) {
            try {
              final fallbackUri = Uri.parse(fallbackUrl);
              // If fallback URL is a relative path, use it
              if (!fallbackUri.hasScheme) {
                _log('Using fallback URL as route path: $fallbackUrl');
                return Uri.parse(fallbackUrl);
              }
              // If fallback URL is absolute, extract the path
              else if (fallbackUri.path.isNotEmpty && fallbackUri.path != '/') {
                _log('Extracting path from fallback URL: ${fallbackUri.path}');
                return Uri(
                  path: fallbackUri.path,
                  queryParameters: {
                    ...uri.queryParameters,
                    ...fallbackUri.queryParameters,
                  },
                );
              }
            } catch (e) {
              _log('Error parsing fallback URL: $e');
            }
          }
        }
      } else {
        _log('Not a ULink dynamic link, passing through unchanged');
      }

      // Return original URI if no transformation was applied
      return uri;
    } catch (e) {
      _log('Error in ULink transformer: $e');
      // Return original URI on any error
      return uri;
    }
  }

  /// Log debug messages if debug mode is enabled
  void _log(String message) {
    if (_debug) {
      debugPrint('[ULinkAutoRouteTransformer] $message');
    }
  }
}

/// Extension to provide convenient access to ULink parameters in route resolvers
extension ULinkResolvedDataExtension on ULinkResolvedData {
  /// Get a parameter value by key
  T? getParameter<T>(String key) {
    return parameters?[key] as T?;
  }

  /// Get a parameter value by key with a default value
  T getParameterOrDefault<T>(String key, T defaultValue) {
    return parameters?[key] as T? ?? defaultValue;
  }

  /// Check if a parameter exists
  bool hasParameter(String key) {
    return parameters?.containsKey(key) ?? false;
  }

  /// Get all parameter keys
  Iterable<String> get parameterKeys {
    return parameters?.keys ?? <String>[];
  }
}

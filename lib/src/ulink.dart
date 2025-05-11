import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models/models.dart';

/// Main class for the ULink SDK
class ULink {
  static ULink? _instance;

  /// The configuration for the SDK
  final ULinkConfig config;

  /// AppLinks instance for handling deep links
  final AppLinks _appLinks = AppLinks();

  /// HTTP client for API requests
  final http.Client _httpClient;

  /// Stream controller for link events
  final StreamController<ULinkResolvedData> _linkStreamController =
      StreamController<ULinkResolvedData>.broadcast();

  /// Stream of link events
  Stream<ULinkResolvedData> get onLink => _linkStreamController.stream;

  /// Last received link data
  ULinkResolvedData? _lastLinkData;

  /// Installation ID for this app installation
  String? _installationId;

  /// Private constructor
  ULink._({required this.config, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client() {
    _init();
  }

  /// Initialize the SDK
  static Future<ULink> initialize({ULinkConfig? config}) async {
    if (_instance == null) {
      // Use provided config or create default with production settings
      final effectiveConfig = config ??
          ULinkConfig(
            apiKey: 'ulk_default', // This should be overridden by the user
            baseUrl: 'https://api.ulink.ly',
          );

      _instance = ULink._(config: effectiveConfig);
      await _instance!._getInstallationId();
    }
    return _instance!;
  }

  /// Factory constructor for testing with a mock HTTP client
  @visibleForTesting
  factory ULink.forTesting({
    required ULinkConfig config,
    required http.Client httpClient,
  }) {
    return ULink._(
      config: config,
      httpClient: httpClient,
    );
  }

  /// Get the singleton instance
  static ULink get instance {
    if (_instance == null) {
      throw Exception(
          'ULink SDK not initialized. Call ULink.initialize() first.');
    }
    return _instance!;
  }

  /// Initialize the SDK
  void _init() {
    // Listen for app links while the app is in the foreground
    _appLinks.uriLinkStream.listen((Uri uri) async {
      _log('App link received: $uri');

      // Check if this is a ULink dynamic link that needs to be resolved
      if (_isULinkDynamicLink(uri)) {
        _log('Processing ULink dynamic link: $uri');
        try {
          // Resolve the URI to get the dynamic link data
          final resolveResponse = await resolveLink(uri.toString());
          if (resolveResponse.success && resolveResponse.data != null) {
            final resolvedData =
                ULinkResolvedData.fromJson(resolveResponse.data!);
            _lastLinkData = resolvedData;
            _linkStreamController.add(resolvedData);
            return; // Exit after processing
          }
        } catch (e) {
          _log('Error resolving dynamic link: $e');
          // Fall through to default handling if resolution fails
        }
      }

      // Default handling if not a ULink dynamic link or if resolution fails
      // Create a basic resolved data from the URI
      final basicData = ULinkResolvedData(
        fallbackUrl: uri.toString(),
        rawData: {'uri': uri.toString()},
      );
      _lastLinkData = basicData;
      _linkStreamController.add(basicData);
    });

    // Get the initial link if the app was opened with one
    _getInitialLink();
  }

  /// Get the initial link if the app was opened with one
  Future<void> _getInitialLink() async {
    try {
      final Uri? initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        _log('Initial app link: $initialLink');

        // Check if this is a ULink dynamic link that needs to be resolved
        if (_isULinkDynamicLink(initialLink)) {
          _log('Processing initial ULink dynamic link: $initialLink');
          try {
            // Resolve the URI to get the dynamic link data
            final resolveResponse = await resolveLink(initialLink.toString());
            if (resolveResponse.success && resolveResponse.data != null) {
              final resolvedData =
                  ULinkResolvedData.fromJson(resolveResponse.data!);
              _lastLinkData = resolvedData;
              _linkStreamController.add(resolvedData);
              return; // Exit after processing
            }
          } catch (e) {
            _log('Error resolving initial dynamic link: $e');
            // Fall through to default handling if resolution fails
          }
        }

        // Default handling if not a ULink dynamic link or if resolution fails
        // Create a basic resolved data from the URI
        final basicData = ULinkResolvedData(
          fallbackUrl: initialLink.toString(),
          rawData: {'uri': initialLink.toString()},
        );
        _lastLinkData = basicData;
        _linkStreamController.add(basicData);
      }
    } catch (e) {
      _log('Error getting initial app link: $e');
    }
  }

  /// Check if a URI is a ULink dynamic link
  bool _isULinkDynamicLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    return pathSegments.length >= 2 && pathSegments[0] == 'd';
  }

  /// Get the last received link data
  ULinkResolvedData? getLastLinkData() {
    return _lastLinkData;
  }

  /// Create a dynamic link
  Future<ULinkResponse> createLink(ULinkParameters parameters) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('${config.baseUrl}/sdk/links'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Key': config.apiKey,
        },
        body: jsonEncode(parameters.toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ULinkResponse.success(
          responseData['shortUrl'] ?? responseData['url'] ?? '',
          responseData,
        );
      } else {
        return ULinkResponse.error(
          responseData['message'] ??
              'Error creating link: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ULinkResponse.error('Error creating link: $e');
    }
  }

  /// Resolve a dynamic link from a URL
  ///
  /// This method takes a full URL and resolves it to get the dynamic link data
  /// Returns a ULinkResponse with the resolved data or an error
  Future<ULinkResponse> resolveLink(String url) async {
    try {
      _log('Resolving link: $url');

      // Use the correct endpoint: /sdk/resolve
      final Uri requestUri = Uri.parse('${config.baseUrl}/sdk/resolve').replace(
        queryParameters: {'url': url},
      );

      final response = await _httpClient.get(
        requestUri,
        headers: {
          'Content-Type': 'application/json',
          'X-App-Key': config.apiKey,
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Return a successful response with the resolved data
        return ULinkResponse.success(
          responseData['fallbackUrl'] ?? '',
          responseData,
        );
      } else {
        return ULinkResponse.error(
          responseData['message'] ??
              'Error resolving link: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ULinkResponse.error('Error resolving link: $e');
    }
  }

  /// Test the link listener with a custom URL
  Future<void> testListener(String testUrl) async {
    _log('Testing link listener with: $testUrl');

    // Create a test URI
    final uri = Uri.parse(testUrl);

    // Manually process as if it came from an app link
    if (_isULinkDynamicLink(uri)) {
      _log('Processing test ULink dynamic link: $uri');
      try {
        // Resolve the URI to get the dynamic link data
        final resolveResponse = await resolveLink(uri.toString());
        if (resolveResponse.success && resolveResponse.data != null) {
          final resolvedData =
              ULinkResolvedData.fromJson(resolveResponse.data!);
          _lastLinkData = resolvedData;
          _linkStreamController.add(resolvedData);
          _log('Successfully resolved test link: ${resolvedData.rawData}');
          return;
        }
      } catch (e) {
        _log('Error resolving test dynamic link: $e');
      }
    }

    // Default handling
    final basicData = ULinkResolvedData(
      fallbackUrl: uri.toString(),
      rawData: {'uri': uri.toString()},
    );
    _lastLinkData = basicData;
    _linkStreamController.add(basicData);
    _log('Added basic test link data to stream');
  }

  /// Get a unique installation ID
  Future<void> _getInstallationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _installationId = prefs.getString('ulink_installation_id');

      if (_installationId == null) {
        _installationId = const Uuid().v4();
        await prefs.setString('ulink_installation_id', _installationId!);
      }
    } catch (e) {
      _log('Error getting installation ID: $e');
      // Generate a temporary ID if we can't access shared preferences
      _installationId = const Uuid().v4();
    }
  }

  /// Get the installation ID
  String? getInstallationId() {
    return _installationId;
  }

  /// Log a message if debug mode is enabled
  void _log(String message) {
    if (config.debug) {
      debugPrint('ULink: $message');
    }
  }

  /// Dispose the SDK
  void dispose() {
    _linkStreamController.close();
  }
}

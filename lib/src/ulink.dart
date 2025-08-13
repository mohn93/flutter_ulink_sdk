import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'models/models.dart';
import 'utils/device_info.dart';
import 'version.dart';

/// Session states for tracking session lifecycle
enum SessionState {
  idle, // No session operation in progress
  initializing, // Session start request sent, waiting for response
  active, // Session successfully started
  ending, // Session end request sent
  failed, // Session start/end failed
}

/// Main class for the ULink SDK
class ULink with WidgetsBindingObserver {
  static ULink? _instance;

  /// The configuration for the SDK
  final ULinkConfig config;

  /// AppLinks instance for handling deep links
  final AppLinks _appLinks = AppLinks();

  /// HTTP client for API requests
  final http.Client _httpClient;

  /// Stream controller for dynamic link events
  final StreamController<ULinkResolvedData> _linkStreamController =
      StreamController<ULinkResolvedData>.broadcast();

  /// Stream controller for unified link events
  final StreamController<ULinkResolvedData> _unifiedLinkStreamController =
      StreamController<ULinkResolvedData>.broadcast();

  /// Stream of dynamic link events
  Stream<ULinkResolvedData> get onLink => _linkStreamController.stream;

  /// Stream of unified link events (for external redirects)
  Stream<ULinkResolvedData> get onUnifiedLink =>
      _unifiedLinkStreamController.stream;

  /// Last received link data
  ULinkResolvedData? _lastLinkData;

  // Persistence keys for last link data
  static const String _prefsKeyLastLinkData = 'ulink_last_link_data';
  static const String _prefsKeyLastLinkSavedAt = 'ulink_last_link_saved_at';
  static const String _prefsKeyInstallationToken = 'ulink_installation_token';
  static const String _prefsKeyLastInstallTrackAt =
      'ulink_last_install_track_at';
  static const String _prefsKeyLastAppVersion = 'ulink_last_app_version';

  /// Installation ID for this app installation
  String? _installationId;

  /// Installation token issued by backend (JWT)
  String? _installationToken;

  /// SDK-resolved device identifier (best-effort)
  String? _deviceId;

  /// Cached platform string
  late final String _clientPlatform = _detectClientPlatform();

  /// Current active session ID
  String? _currentSessionId;

  /// Session state management
  SessionState _sessionState = SessionState.idle;

  /// Completer to track session initialization
  Completer<void>? _sessionCompleter;

  /// Flag to track if lifecycle observer is registered
  bool _isLifecycleObserverRegistered = false;

  /// Private constructor
  ULink._({required this.config, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client() {
    _init();
  }

  /// Initialize the SDK
  ///
  /// This method initializes the ULink SDK and performs the following actions:
  /// 1. Creates a singleton instance with the provided configuration
  /// 2. Retrieves or generates a unique installation ID
  /// 3. Tracks the installation with the server
  /// 4. Starts a new session
  /// 5. Initializes app links for deep linking
  ///
  /// It should be called when your app starts, typically in your app's
  /// initialization code or in the main widget's initState method.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await ULink.initialize(
  ///     config: ULinkConfig(
  ///       apiKey: 'your_api_key',
  ///       baseUrl: 'https://api.ulink.ly',
  ///       debug: true,
  ///     ),
  ///   );
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<ULink> initialize({ULinkConfig? config}) async {
    if (_instance == null) {
      // Step 1: Create instance with provided config or default settings
      final effectiveConfig = config ??
          ULinkConfig(
            apiKey: 'ulk_default', // This should be overridden by the user
            baseUrl: 'https://api.ulink.ly',
          );

      _instance = ULink._(config: effectiveConfig);

      // Preload any persisted installation token
      await _instance!._loadInstallationToken();

      // Step 2: Get or generate installation ID
      await _instance!._getInstallationId();

      // Step 3-4: Bootstrap (ensure installation and session in one call)
      await _instance!._bootstrap();

      // Step 5: Initialize app links (happens in _init method)
      // Step 6: Register lifecycle observer for automatic session management
      _instance!._registerLifecycleObserver();
      _instance!._log('ULink SDK initialization complete');
    }
    return _instance!;
  }

  /// Bootstrap installation and session via single API call
  Future<void> _bootstrap() async {
    try {
      _log('Bootstrapping installation and session');

      final uri = Uri.parse('${config.baseUrl}/sdk/bootstrap');
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-App-Key': config.apiKey,
          if (_installationToken != null)
            'X-Installation-Token': _installationToken!,
          if (_installationId != null) 'X-Installation-Id': _installationId!,
          if (_deviceId != null) 'X-Device-Id': _deviceId!,
          'X-ULink-Client': 'sdk-flutter',
          'X-ULink-Client-Version': ulinkSdkVersion,
          'X-ULink-Client-Platform': _clientPlatform,
        },
        body: jsonEncode({
          'installationId': _installationId,
          'metadata': {
            'client': {
              'type': 'sdk-flutter',
              'version': ulinkSdkVersion,
              'platform': _clientPlatform,
            }
          }
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Persist token from header or body
        final tokenFromHeader = response.headers['x-installation-token'];
        final tokenFromBody = data['installationToken'] as String?;
        final token = tokenFromHeader ?? tokenFromBody;
        if (token != null && token.isNotEmpty) {
          _installationToken = token;
          await _saveInstallationToken(token);
        }

        // Ensure installation id
        final ensuredInstallationId = data['installationId'] as String?;
        if (ensuredInstallationId != null && ensuredInstallationId.isNotEmpty) {
          _installationId = ensuredInstallationId;
        }

        // Ensure session id and set active state
        final sessionId = data['sessionId'] as String?;
        if (sessionId != null && sessionId.isNotEmpty) {
          _currentSessionId = sessionId;
          _sessionState = SessionState.active;
          _sessionCompleter?.complete();
          _log('Bootstrap ensured session: $sessionId');
        }
      } else {
        _log('Bootstrap failed: ${response.statusCode}');
      }
    } catch (e) {
      _log('Bootstrap error: $e');
    }
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

  /// Register lifecycle observer for automatic session management
  void _registerLifecycleObserver() {
    if (!_isLifecycleObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _isLifecycleObserverRegistered = true;
      _log('Lifecycle observer registered for automatic session management');
    }
  }

  /// Unregister lifecycle observer
  void _unregisterLifecycleObserver() {
    if (_isLifecycleObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _isLifecycleObserverRegistered = false;
      _log('Lifecycle observer unregistered');
    }
  }

  /// Handle app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _log('App lifecycle state changed to: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - start new session if none exists and not already starting
        if (_sessionState == SessionState.idle) {
          _log('App resumed - starting new session');
          _startSession().then((response) {
            if (config.debug) {
              if (response.success) {
                _log('New session started on app resume: $_currentSessionId');
              } else {
                _log(
                    'Failed to start session on app resume: ${response.error}');
              }
            }
          }).catchError((e) {
            _log('Error starting session on app resume: $e');
          });
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App went to background or is being destroyed - end current session
        if (hasActiveSession()) {
          _log('App paused/inactive/detached - ending current session');
          endSession().then((response) {
            if (config.debug) {
              if (response.success) {
                _log('Session ended on app pause/inactive/detached');
              } else {
                _log(
                    'Failed to end session on app pause/inactive/detached: ${response.error}');
              }
            }
          }).catchError((e) {
            _log('Error ending session on app pause/inactive/detached: $e');
          });
        }
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running - optionally end session
        if (hasActiveSession()) {
          _log('App hidden - ending current session');
          endSession().then((response) {
            if (config.debug) {
              if (response.success) {
                _log('Session ended on app hidden');
              } else {
                _log('Failed to end session on app hidden: ${response.error}');
              }
            }
          }).catchError((e) {
            _log('Error ending session on app hidden: $e');
          });
        }
        break;
    }
  }

  /// Initialize the SDK
  void _init() {
    // Load any previously persisted last link data (applies TTL if configured)
    _loadLastLinkData();

    // Initialize device id best-effort
    DeviceInfoHelper.getBasicDeviceInfo().then((info) {
      _deviceId = info['deviceId'] as String?;
    }).catchError((_) {});

    // Listen for app links while the app is in the foreground
    _appLinks.uriLinkStream.listen((Uri uri) async {
      _log('App link received: $uri');
      await _handleUri(uri, context: '');
    });

    // Get the initial link if the app was opened with one
    _getInitialLink();
  }

  /// Flag to track if initial link has been processed
  bool _initialLinkProcessed = false;

  /// Get the initial link if the app was opened with one
  Future<void> _getInitialLink() async {
    if (_initialLinkProcessed) {
      _log('Initial link already processed, skipping');
      return;
    }

    try {
      _log('Checking for initial deep link...');
      final ULinkResolvedData? initialLinkData = await getInitialDeepLink();

      _initialLinkProcessed = true;

      if (initialLinkData != null) {
        _log('Found initial ULink: ${initialLinkData.rawData}');

        // Route to appropriate stream based on link type
        if (initialLinkData.linkType == ULinkType.unified) {
          _log('Initial link is unified - adding to unified stream');
          _lastLinkData = initialLinkData;
          await _saveLastLinkData(initialLinkData);
          _unifiedLinkStreamController.add(initialLinkData);
        } else {
          _log('Initial link is dynamic - adding to dynamic stream');
          _lastLinkData = initialLinkData;
          await _saveLastLinkData(initialLinkData);
          _linkStreamController.add(initialLinkData);
        }
      } else {
        _log('No initial ULink found');
      }
    } catch (e) {
      _log('Error getting initial deep link: $e');
    }
  }

  /// Process a URI and resolve ULink data by querying the server
  /// This unified method is used by both internal link handling and external components
  /// Returns null if the URI cannot be resolved or is not a ULink
  Future<ULinkResolvedData?> processULinkUri(Uri uri) async {
    try {
      _log('Processing URI: ${uri.toString()}');

      // Always try to resolve the URI with the server to determine if it's a ULink
      _log('Querying server to resolve URI...');
      final resolveResponse = await resolveLink(uri.toString());

      if (resolveResponse.success && resolveResponse.data != null) {
        final resolvedData = ULinkResolvedData.fromJson(resolveResponse.data!);
        _log('Successfully resolved ULink data: ${resolvedData.rawData}');
        return resolvedData;
      } else {
        // Differentiate between network errors and non-ULink responses
        if (resolveResponse.error != null) {
          if (resolveResponse.error!.contains('network') ||
              resolveResponse.error!.contains('timeout') ||
              resolveResponse.error!.contains('connection')) {
            _log('Network error while resolving URI: ${resolveResponse.error}');
          } else {
            _log('URI is not a ULink: ${resolveResponse.error}');
          }
        } else {
          _log('Server responded but URI is not a ULink');
        }
      }

      return null;
    } catch (e) {
      _log('Exception while processing ULink URI: $e');
      return null;
    }
  }

  /// Handle resolved ULink data by determining the appropriate action
  /// This unified method handles both dynamic and unified links
  Future<void> _handleResolvedULinkData(ULinkResolvedData resolvedData,
      {String context = ''}) async {
    // Check if this is a simple/unified link that should be handled internally
    if (resolvedData.linkType == ULinkType.unified) {
      _log('Detected ${context}simple/unified link - handling internally');
      await _handleSimpleLinkInApp(resolvedData);
      return;
    }

    // Handle as normal dynamic link
    _lastLinkData = resolvedData;
    await _saveLastLinkData(resolvedData);
    _linkStreamController.add(resolvedData);
  }

  /// Handle a URI by processing it and taking appropriate action
  /// This unified method handles the complete flow for any URI
  Future<void> _handleUri(Uri uri, {String context = ''}) async {
    // Try to process as ULink dynamic link
    final resolvedData = await processULinkUri(uri);

    if (resolvedData != null) {
      await _handleResolvedULinkData(resolvedData, context: context);
      return;
    }

    // If processULinkUri returns null, it means either:
    // 1. Network error occurred while trying to resolve
    // 2. The URI is not a ULink (server responded but it's not a ULink)
    //
    // For now, we'll treat all non-ULink URIs as regular deep links
    // and let the app handle them normally (don't redirect externally)
    _log(
        '${context}URI is not a ULink or failed to resolve - treating as regular deep link');

    // Don't create ULinkResolvedData for non-ULink URIs
    // Just log and let the app handle the URI normally
  }

  /// Handle simple/unified links by calling the listener internally
  Future<void> _handleSimpleLinkInApp(ULinkResolvedData linkData) async {
    try {
      _log('Handling simple/unified link - calling listener internally');

      // Instead of opening externally (which would cause infinite loops),
      // we call the listener internally to handle the unified link
      // This allows the app to process the link without system redirection

      // Add to unified link stream for the app to handle
      _lastLinkData = linkData;
      await _saveLastLinkData(linkData);
      _unifiedLinkStreamController.add(linkData);

      _log('Unified link added to stream for app handling');
    } catch (e) {
      _log('Error handling simple link: $e');
    }
  }

  /// Get the last received link data
  ULinkResolvedData? getLastLinkData() {
    final result = _lastLinkData;
    if (result != null && config.clearLastLinkOnRead) {
      _clearPersistedLastLink();
      _lastLinkData = null;
    }
    return result;
  }

  Future<void> _saveLastLinkData(ULinkResolvedData data) async {
    if (!config.persistLastLinkData) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> sanitized = _sanitizeLastLinkData(data);
      await prefs.setString(_prefsKeyLastLinkData, jsonEncode(sanitized));
      await prefs.setInt(
        _prefsKeyLastLinkSavedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
      _log('Persisted last link data');
    } catch (e) {
      _log('Failed to persist last link data: $e');
    }
  }

  Future<void> _loadLastLinkData() async {
    if (!config.persistLastLinkData) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKeyLastLinkData);
      if (jsonStr == null) return;

      final savedAtMs = prefs.getInt(_prefsKeyLastLinkSavedAt) ?? 0;
      final ttl = config.lastLinkTimeToLive;
      if (ttl != null && ttl.inMilliseconds > 0 && savedAtMs > 0) {
        final ageMs = DateTime.now().millisecondsSinceEpoch - savedAtMs;
        if (ageMs > ttl.inMilliseconds) {
          _clearPersistedLastLink();
          _log('Expired persisted last link data cleared');
          return;
        }
      }

      final Map<String, dynamic> map = jsonDecode(jsonStr);
      _lastLinkData = ULinkResolvedData.fromJson(map);
      _log('Loaded persisted last link data');
    } catch (e) {
      _log('Failed to load persisted last link data: $e');
    }
  }

  void _clearPersistedLastLink() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyLastLinkData);
      await prefs.remove(_prefsKeyLastLinkSavedAt);
    } catch (e) {
      _log('Failed to clear persisted last link data: $e');
    }
  }

  Map<String, dynamic> _sanitizeLastLinkData(ULinkResolvedData data) {
    final dropAll = config.redactAllParametersInLastLink;
    // Start from rawData to preserve all server-provided fields
    final Map<String, dynamic> base = Map<String, dynamic>.from(data.rawData);

    Map<String, dynamic>? redactMap(
      Map<String, dynamic>? src,
      List<String> keys,
    ) {
      if (src == null) return null;
      if (keys.isEmpty) return Map<String, dynamic>.from(src);
      final copy = <String, dynamic>{};
      src.forEach((k, v) {
        if (!keys.contains(k)) copy[k] = v;
      });
      return copy;
    }

    final redactedParams = dropAll
        ? null
        : redactMap(data.parameters, config.redactedParameterKeysInLastLink);
    final redactedMeta = dropAll
        ? null
        : redactMap(data.metadata, config.redactedParameterKeysInLastLink);

    // Rebuild final map ensuring parameters/metadata are applied per redaction
    final result = <String, dynamic>{...base};
    result.remove('parameters');
    result.remove('metadata');
    if (redactedParams != null) result['parameters'] = redactedParams;
    if (redactedMeta != null) result['metadata'] = redactedMeta;

    return result;
  }

  /// Get the initial deep link URI that opened the app (raw URI)
  ///
  /// This method retrieves the raw initial deep link URI if the app was opened with one.
  /// Unlike the stream-based approach, this method returns the URI synchronously
  /// and can be called at any time after SDK initialization.
  ///
  /// This method returns the raw URI without processing it through ULink,
  /// allowing you to handle both ULink and non-ULink deep links.
  ///
  /// Returns null if:
  /// - The app was not opened with a deep link
  /// - An error occurred while retrieving the initial link
  ///
  /// Example:
  /// ```dart
  /// final initialUri = await ULink.instance.getInitialUri();
  /// if (initialUri != null) {
  ///   print('App opened with URI: $initialUri');
  ///   // Handle the URI as needed
  /// }
  /// ```
  Future<Uri?> getInitialUri() async {
    try {
      _log('Getting initial URI...');
      final Uri? initialLink = await _appLinks.getInitialLink();

      if (initialLink != null) {
        _log('Found initial URI: $initialLink');
        return initialLink;
      } else {
        _log('No initial URI found');
        return null;
      }
    } catch (e) {
      _log('Error getting initial URI: $e');
      return null;
    }
  }

  /// Get the initial deep link that opened the app (processed ULink data)
  ///
  /// This method retrieves the initial deep link if the app was opened with one
  /// and processes it through ULink to resolve the data.
  /// Unlike the stream-based approach, this method returns the link synchronously
  /// and can be called at any time after SDK initialization.
  ///
  /// Returns null if:
  /// - The app was not opened with a deep link
  /// - An error occurred while retrieving the initial link
  /// - The initial link is not a ULink
  ///
  /// Example:
  /// ```dart
  /// final initialLink = await ULink.instance.getInitialDeepLink();
  /// if (initialLink != null) {
  ///   // Handle the initial deep link
  ///   print('App opened with: ${initialLink.fallbackUrl}');
  /// }
  /// ```
  Future<ULinkResolvedData?> getInitialDeepLink() async {
    try {
      _log('Getting initial deep link...');
      final Uri? initialLink = await _appLinks.getInitialLink();

      if (initialLink != null) {
        _log('Found initial link: $initialLink');

        // Process the initial link to check if it's a ULink
        final resolvedData = await processULinkUri(initialLink);

        if (resolvedData != null) {
          _log('Initial link is a ULink: ${resolvedData.rawData}');
          return resolvedData;
        } else {
          _log('Initial link is not a ULink');
          return null;
        }
      } else {
        _log('No initial link found');
        return null;
      }
    } catch (e) {
      _log('Error getting initial deep link: $e');
      return null;
    }
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
    // Do not wait for session here; server will auto-start/ensure recent session on resolve
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
          if (_installationToken != null)
            'X-Installation-Token': _installationToken!
          else if (_installationId != null)
            'X-Installation-Id': _installationId!,
          if (_deviceId != null) 'X-Device-Id': _deviceId!,
          'X-ULink-Client': 'sdk-flutter',
          'X-ULink-Client-Version': ulinkSdkVersion,
          'X-ULink-Client-Platform': _clientPlatform,
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Capture updated installation token if provided
        final tokenHeader = response.headers['x-installation-token'];
        if (tokenHeader != null && tokenHeader.isNotEmpty) {
          await _saveInstallationToken(tokenHeader);
        }
        // Use fallbackUrl as the canonical resolved URL as per endpoint contract
        final resolvedUrl = (responseData['fallbackUrl'] as String?) ?? url;
        return ULinkResponse.success(
          resolvedUrl,
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

    // Use the unified handler
    await _handleUri(uri, context: 'test ');
    _log('Successfully processed test link');
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

  // Note: kept for backward compatibility but not used in bootstrap flow
  // ignore: unused_element
  Future<ULinkInstallationResponse> _trackInstallation() async {
    try {
      _log('Tracking installation: $_installationId');

      if (_installationId == null) {
        return ULinkInstallationResponse.error('Installation ID not available');
      }

      // Get device information
      final deviceInfo = await DeviceInfoHelper.getBasicDeviceInfo();

      // Create installation data
      final installation = ULinkInstallation(
        installationId: _installationId!,
        deviceId: deviceInfo['deviceId'],
        deviceModel: deviceInfo['deviceModel'],
        deviceManufacturer: deviceInfo['deviceManufacturer'],
        osName: deviceInfo['osName'],
        osVersion: deviceInfo['osVersion'],
        appVersion: deviceInfo['appVersion'],
        appBuild: deviceInfo['appBuild'],
        language: deviceInfo['language'],
        timezone: deviceInfo['timezone'],
      );

      // Send installation data to server
      final response = await _httpClient.post(
        Uri.parse('${config.baseUrl}/sdk/installations/track'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Key': config.apiKey,
          if (_installationToken != null)
            'X-Installation-Token': _installationToken!,
          'X-ULink-Client': 'sdk-flutter',
          'X-ULink-Client-Version': ulinkSdkVersion,
          'X-ULink-Client-Platform': _clientPlatform,
        },
        body: jsonEncode(installation.toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('Installation tracked successfully');
        final tokenHeader = response.headers['x-installation-token'];
        final jsonToken = (responseData)['installationToken'] as String?;
        final token = tokenHeader ?? jsonToken;
        if (token != null && token.isNotEmpty) {
          await _saveInstallationToken(token);
        }
        // Persist last track time and app version for refresh heuristics
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_prefsKeyLastInstallTrackAt,
              DateTime.now().millisecondsSinceEpoch);
          final packageInfo = await PackageInfo.fromPlatform();
          await prefs.setString(_prefsKeyLastAppVersion, packageInfo.version);
        } catch (_) {}
        return ULinkInstallationResponse.fromJson(responseData);
      } else {
        _log('Error tracking installation: ${response.statusCode}');
        return ULinkInstallationResponse.error(
          responseData['message'] ??
              'Error tracking installation: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log('Error tracking installation: $e');
      return ULinkInstallationResponse.error('Error tracking installation: $e');
    }
  }

  /// Track the installation with the server (public method)
  Future<ULinkInstallationResponse> trackInstallation(
      {Map<String, dynamic>? metadata}) async {
    try {
      _log('Tracking installation with metadata: $_installationId');

      if (_installationId == null) {
        return ULinkInstallationResponse.error('Installation ID not available');
      }

      // Get device information
      final deviceInfo = await DeviceInfoHelper.getBasicDeviceInfo();

      // Create installation data
      final installation = ULinkInstallation(
        installationId: _installationId!,
        deviceId: deviceInfo['deviceId'],
        deviceModel: deviceInfo['deviceModel'],
        deviceManufacturer: deviceInfo['deviceManufacturer'],
        osName: deviceInfo['osName'],
        osVersion: deviceInfo['osVersion'],
        appVersion: deviceInfo['appVersion'],
        appBuild: deviceInfo['appBuild'],
        language: deviceInfo['language'],
        timezone: deviceInfo['timezone'],
        metadata: metadata,
      );

      // Send installation data to server
      final response = await _httpClient.post(
        Uri.parse('${config.baseUrl}/sdk/installations/track'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Key': config.apiKey,
          if (_installationToken != null)
            'X-Installation-Token': _installationToken!,
          'X-ULink-Client': 'sdk-flutter',
          'X-ULink-Client-Version': ulinkSdkVersion,
          'X-ULink-Client-Platform': _clientPlatform,
        },
        body: jsonEncode(installation.toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('Installation tracked successfully');
        final tokenHeader = response.headers['x-installation-token'];
        final jsonToken = (responseData)['installationToken'] as String?;
        final token = tokenHeader ?? jsonToken;
        if (token != null && token.isNotEmpty) {
          await _saveInstallationToken(token);
        }
        // Persist last track time and app version for refresh heuristics
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_prefsKeyLastInstallTrackAt,
              DateTime.now().millisecondsSinceEpoch);
          final packageInfo = await PackageInfo.fromPlatform();
          await prefs.setString(_prefsKeyLastAppVersion, packageInfo.version);
        } catch (_) {}
        return ULinkInstallationResponse.fromJson(responseData);
      } else {
        _log('Error tracking installation: ${response.statusCode}');
        return ULinkInstallationResponse.error(
          responseData['message'] ??
              'Error tracking installation: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log('Error tracking installation: $e');
      return ULinkInstallationResponse.error('Error tracking installation: $e');
    }
  }

  /// Log a message if debug mode is enabled
  void _log(String message) {
    if (config.debug) {
      debugPrint('ULink: $message');
    }
  }

  String _detectClientPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  Future<void> _loadInstallationToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _installationToken = prefs.getString(_prefsKeyInstallationToken);
    } catch (_) {}
  }

  Future<void> _saveInstallationToken(String token) async {
    _installationToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyInstallationToken, token);
    } catch (_) {}
  }

  // Heuristic retained for manual track flows; bootstrap path bypasses this
  // ignore: unused_element
  Future<bool> _shouldTrackInstallation() async {
    try {
      // If we have no token, we should track to mint one
      if (_installationToken == null || _installationToken!.isEmpty) {
        return true;
      }

      // If token has an exp claim and is expired or near-expiry, refresh
      final exp = _parseJwtExp(_installationToken!);
      if (exp != null) {
        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        // Refresh if exp within 7 days
        if (exp - nowSeconds < 7 * 24 * 60 * 60) {
          return true;
        }
      }

      // Refresh on app version change
      final prefs = await SharedPreferences.getInstance();
      final lastVersion = prefs.getString(_prefsKeyLastAppVersion);
      final packageInfo = await PackageInfo.fromPlatform();
      if (lastVersion == null || lastVersion != packageInfo.version) {
        return true;
      }

      // Refresh after 30 days regardless
      final lastTrackMs = prefs.getInt(_prefsKeyLastInstallTrackAt) ?? 0;
      if (lastTrackMs == 0) return true;
      final daysSince = (DateTime.now().millisecondsSinceEpoch - lastTrackMs) /
          (1000 * 60 * 60 * 24);
      if (daysSince >= 30) return true;

      return false;
    } catch (_) {
      return true;
    }
  }

  int? _parseJwtExp(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      var normalized = payload;
      switch (payload.length % 4) {
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }
      final decoded = utf8.decode(base64.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is int) return exp;
      if (exp is String) return int.tryParse(exp);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Starts a new session with the ULink server
  ///
  /// This method is called automatically during initialization
  /// but can also be called manually to start a new session.
  ///
  /// Returns a [ULinkSessionResponse] with the session ID if successful.
  Future<ULinkSessionResponse> _startSession(
      [Map<String, dynamic>? metadata]) async {
    if (_installationId == null) {
      _log('Cannot start session without installation ID');
      return ULinkSessionResponse.error('Installation ID not available');
    }

    // If session is already initializing, wait for it to complete
    if (_sessionState == SessionState.initializing) {
      _log('Session already initializing, waiting for completion...');
      try {
        await _waitForSessionCompletion();
        _log(
            'Existing session initialization completed (ID: $_currentSessionId)');
        return ULinkSessionResponse.success(_currentSessionId!);
      } catch (e) {
        _log(
            'Existing session initialization failed: $e, starting new session');
        // Continue to start a new session if the existing one failed
      }
    }

    // If session is already active, return it
    if (_sessionState == SessionState.active && _currentSessionId != null) {
      _log(
          'Session already active (ID: $_currentSessionId), reusing existing session');
      return ULinkSessionResponse.success(_currentSessionId!);
    }

    try {
      // End any existing session first
      _sessionCompleter = Completer();
      _sessionState = SessionState.initializing;

      if (_currentSessionId != null) {
        await endSession();
      }

      // Collect device information automatically
      final deviceInfo = await DeviceInfoHelper.getCompleteDeviceInfo();
      _log('Collected device info for session: ${deviceInfo.keys.join(", ")}');

      // Extract device information
      final String? networkType = deviceInfo['networkType'] as String?;
      final String? deviceOrientation =
          deviceInfo['deviceOrientation'] as String?;
      final double? batteryLevel = deviceInfo['batteryLevel'] as double?;
      final bool? isCharging = deviceInfo['isCharging'] as bool?;

      // Merge provided metadata with device info
      final Map<String, dynamic> sessionMetadata = {};
      if (metadata != null) {
        sessionMetadata.addAll(metadata);
      }

      // Add basic device info to metadata if not explicitly provided
      if (!sessionMetadata.containsKey('deviceInfo')) {
        // Filter out properties that are already included in the session object
        final Map<String, dynamic> filteredDeviceInfo = Map.from(deviceInfo);
        filteredDeviceInfo.remove('networkType');
        filteredDeviceInfo.remove('deviceOrientation');
        filteredDeviceInfo.remove('batteryLevel');
        filteredDeviceInfo.remove('isCharging');

        if (filteredDeviceInfo.isNotEmpty) {
          sessionMetadata['deviceInfo'] = filteredDeviceInfo;
        }
      }

      // Create session data with all collected parameters
      final ULinkSession sessionData = ULinkSession(
        installationId: _installationId!,
        networkType: networkType,
        deviceOrientation: deviceOrientation,
        batteryLevel: batteryLevel,
        isCharging: isCharging,
        metadata: sessionMetadata.isEmpty ? null : sessionMetadata,
      );

      return await _sendSessionStartRequest(sessionData).then((r) {
        _sessionCompleter?.complete();
        return r;
      });
    } catch (e) {
      _log('Error starting session: $e');
      return ULinkSessionResponse.error('Error starting session: $e');
    }
  }

  /// Helper method to send session start request to the server
  Future<ULinkSessionResponse> _sendSessionStartRequest(
      ULinkSession session) async {
    // Set session state to initializing
    _sessionState = SessionState.initializing;
    _log('Session state changed to: $_sessionState');

    try {
      // Send session data to server
      final response = await _httpClient.post(
        Uri.parse('${config.baseUrl}/sdk/sessions/start'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Key': config.apiKey,
        },
        body: jsonEncode(session.toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('Session started successfully');
        _currentSessionId = responseData['sessionId'];
        _sessionState = SessionState.active;
        _log('Session state changed to: $_sessionState');

        return ULinkSessionResponse.fromJson(responseData);
      } else {
        _log('Error starting session: ${response.statusCode}');
        _sessionState = SessionState.failed;
        _log('Session state changed to: $_sessionState');

        return ULinkSessionResponse.error(
          responseData['message'] ??
              'Error starting session: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log('Error sending session request: $e');
      _sessionState = SessionState.failed;
      _log('Session state changed to: $_sessionState');

      return ULinkSessionResponse.error('Error sending session request: $e');
    }
  }

  // _ensureActiveSession removed; the server ensures/auto-starts session on resolve

  /// Wait for session initialization to complete
  Future<void> _waitForSessionCompletion() async {
    const maxWaitTime = Duration(seconds: 10);
    await _sessionCompleter?.future.timeout(maxWaitTime);
    // After waiting, check if session actually became active
    if (_sessionState != SessionState.active) {
      throw Exception(
          'Session failed to become active (final state: $_sessionState)');
    }
  }

  /// Check if a session is currently being initialized
  bool get isSessionInitializing {
    return _sessionState == SessionState.initializing;
  }

  /// Get current session state
  SessionState get sessionState => _sessionState;

  /// End the current session
  ///
  /// This method ends the active session and reports it to the server.
  /// If no session is active, it returns an error response.
  ///
  /// Returns a [ULinkResponse] indicating success or failure.
  Future<ULinkResponse> endSession() async {
    try {
      final sessionId = _currentSessionId;
      _log('Ending session: $sessionId');

      if (sessionId == null) {
        return ULinkResponse.error('No active session to end');
      }

      // Send end session request to server
      final response = await _httpClient.post(
        Uri.parse('${config.baseUrl}/sdk/sessions/$sessionId/end'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Key': config.apiKey,
        },
      );

      // Clear the session ID immediately to prevent duplicate end requests
      _currentSessionId = null;
      _sessionState = SessionState.idle;
      _log('Session state changed to: $_sessionState');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('Session ended successfully');
        return ULinkResponse.success(
            'Session ended successfully', responseData);
      } else {
        _log('Error ending session: ${response.statusCode}');
        return ULinkResponse.error(
          responseData['message'] ??
              'Error ending session: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Clear the session ID even if there was an error
      _currentSessionId = null;
      _log('Error ending session: $e');
      return ULinkResponse.error('Error ending session: $e');
    }
  }

  /// Get the current session ID
  ///
  /// Returns the ID of the active session, or null if no session is active.
  /// This can be used to check if a session is currently active.
  String? getCurrentSessionId() {
    return _currentSessionId;
  }

  /// Check if a session is currently active
  ///
  /// Returns true if there is an active session, false otherwise.
  bool hasActiveSession() {
    return _currentSessionId != null;
  }

  /// Dispose the SDK
  ///
  /// This method cleans up resources used by the SDK and ends any active session.
  /// It should be called when the app is closing or the SDK is no longer needed.
  void dispose() {
    // Unregister lifecycle observer
    _unregisterLifecycleObserver();

    // End the current session if one exists
    if (_currentSessionId != null) {
      // Use a synchronous try-catch to ensure we don't miss any errors
      try {
        endSession().then((_) {
          _log('Session ended during dispose');
        }).catchError((e) {
          _log('Error ending session during dispose: $e');
        });
      } catch (e) {
        _log('Unexpected error during dispose: $e');
      }
    }

    // Close the stream controllers
    _linkStreamController.close();
    _unifiedLinkStreamController.close();
    _log('SDK disposed');
  }
}

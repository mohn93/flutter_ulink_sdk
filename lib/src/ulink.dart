import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/models.dart';
import 'utils/device_info.dart';

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
  Stream<ULinkResolvedData> get onUnifiedLink => _unifiedLinkStreamController.stream;

  /// Last received link data
  ULinkResolvedData? _lastLinkData;

  /// Installation ID for this app installation
  String? _installationId;
  
  /// Current active session ID
  String? _currentSessionId;

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
      
      // Step 2: Get or generate installation ID
      await _instance!._getInstallationId();
      
      // Step 3: Track installation with the server
      await _instance!._trackInstallation();
      
      // Step 4: Start a new session
      final sessionResponse = await _instance!._startSession();
      if (_instance!.config.debug) {
        if (sessionResponse.success) {
          _instance!._log('Session started with ID: ${_instance!._currentSessionId}');
        } else {
          _instance!._log('Failed to start session: ${sessionResponse.error}');
        }
      }
      
      // Step 5: Initialize app links (happens in _init method)
      // Step 6: Register lifecycle observer for automatic session management
      _instance!._registerLifecycleObserver();
      _instance!._log('ULink SDK initialization complete');
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
        // App came to foreground - start new session if none exists
        if (!hasActiveSession()) {
          _log('App resumed - starting new session');
          _startSession().then((response) {
            if (config.debug) {
              if (response.success) {
                _log('New session started on app resume: $_currentSessionId');
              } else {
                _log('Failed to start session on app resume: ${response.error}');
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
                _log('Failed to end session on app pause/inactive/detached: ${response.error}');
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
    // Listen for app links while the app is in the foreground
    _appLinks.uriLinkStream.listen((Uri uri) async {
      _log('App link received: $uri');

        _log('Processing ULink dynamic link: $uri');
        try {
          // Resolve the URI to get the dynamic link data
          final resolveResponse = await resolveLink(uri.toString());
          if (resolveResponse.success && resolveResponse.data != null) {
            final resolvedData =
                ULinkResolvedData.fromJson(resolveResponse.data!);
            
            // Check if this is a simple/unified link that should be redirected externally
            if (resolvedData.linkType == ULinkType.unified) {
              _log('Detected simple/unified link - handling externally');
              await _handleSimpleLinkInApp(resolvedData);
              // Add to unified link stream for tracking purposes
              _lastLinkData = resolvedData;
              _unifiedLinkStreamController.add(resolvedData);
              return;
            }
            
            // Handle as normal dynamic link
            _lastLinkData = resolvedData;
            _linkStreamController.add(resolvedData);
            return; // Exit after processing
          }
        } catch (e) {
          _log('Error resolving dynamic link: $e');
          // Fall through to default handling if resolution fails
        }

      // Default handling if not a ULink dynamic link or if resolution fails
      // Treat as a unified link that should be redirected externally
      final basicData = ULinkResolvedData(
        fallbackUrl: uri.toString(),
        linkType: ULinkType.unified,
        rawData: {'uri': uri.toString(), 'type': 'unified'},
      );
      
      _log('Treating unknown link as unified link - redirecting externally');
      await _handleSimpleLinkInApp(basicData);
      
      _lastLinkData = basicData;
      _unifiedLinkStreamController.add(basicData);
    });

    // Get the initial link if the app was opened with one
    _getInitialLink();
  }

  /// Get the initial link if the app was opened with one
  Future<void> _getInitialLink() async {
    try {
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _log('Initial app link: $initialLink');

          _log('Processing initial ULink dynamic link: $initialLink');
          try {
            // Resolve the URI to get the dynamic link data
            final resolveResponse = await resolveLink(initialLink.toString());
            if (resolveResponse.success && resolveResponse.data != null) {
              final resolvedData =
                  ULinkResolvedData.fromJson(resolveResponse.data!);
              
              // Check if this is a simple/unified link that should be redirected externally
              if (resolvedData.linkType == ULinkType.unified) {
                _log('Detected initial simple/unified link - handling externally');
                await _handleSimpleLinkInApp(resolvedData);
                // Add to unified link stream for tracking purposes
                _lastLinkData = resolvedData;
                _unifiedLinkStreamController.add(resolvedData);
                return;
              }
              
              // Handle as normal dynamic link
              _lastLinkData = resolvedData;
              _linkStreamController.add(resolvedData);
              return; // Exit after processing
            }
          } catch (e) {
            _log('Error resolving initial dynamic link: $e');
            // Fall through to default handling if resolution fails
          }
        // Default handling if not a ULink dynamic link or if resolution fails
        // Treat as a unified link that should be redirected externally
        final basicData = ULinkResolvedData(
          fallbackUrl: initialLink.toString(),
          linkType: ULinkType.unified,
          rawData: {'uri': initialLink.toString(), 'type': 'unified'},
        );
        
        _log('Treating unknown initial link as unified link - redirecting externally');
        await _handleSimpleLinkInApp(basicData);
        
        _lastLinkData = basicData;
        _unifiedLinkStreamController.add(basicData);
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

  /// Handle simple/unified links by redirecting them externally
  Future<void> _handleSimpleLinkInApp(ULinkResolvedData linkData) async {
    try {
      _log('Handling simple/unified link - redirecting externally');
      
      // Determine the appropriate URL to redirect to based on platform
      String? redirectUrl;
      
      if (Platform.isIOS && linkData.iosFallbackUrl != null) {
        redirectUrl = linkData.iosFallbackUrl;
      } else if (Platform.isAndroid && linkData.androidFallbackUrl != null) {
        redirectUrl = linkData.androidFallbackUrl;
      } else if (linkData.fallbackUrl != null) {
        redirectUrl = linkData.fallbackUrl;
      }
      
      if (redirectUrl != null) {
        _log('Opening external URL: $redirectUrl');
        final uri = Uri.parse(redirectUrl);
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          _log('Cannot launch URL: $redirectUrl');
        }
      } else {
        _log('No appropriate redirect URL found for simple link');
      }
    } catch (e) {
      _log('Error handling simple link: $e');
    }
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
          
          // Check if this is a simple/unified link that should be redirected externally
          if (resolvedData.linkType == ULinkType.unified) {
            _log('Detected test simple/unified link - handling externally');
            await _handleSimpleLinkInApp(resolvedData);
            // Add to unified link stream for tracking purposes
            _lastLinkData = resolvedData;
            _unifiedLinkStreamController.add(resolvedData);
            _log('Successfully handled test simple link externally');
            return;
          }
          
          // Handle as normal dynamic link
          _lastLinkData = resolvedData;
          _linkStreamController.add(resolvedData);
          _log('Successfully resolved test link: ${resolvedData.rawData}');
          return;
        }
      } catch (e) {
        _log('Error resolving test dynamic link: $e');
      }
    }

    // Default handling - treat as unified link
    final basicData = ULinkResolvedData(
      fallbackUrl: uri.toString(),
      linkType: ULinkType.unified,
      rawData: {'uri': uri.toString(), 'type': 'unified'},
    );
    
    _log('Treating test link as unified link - redirecting externally');
    await _handleSimpleLinkInApp(basicData);
    
    _lastLinkData = basicData;
    _unifiedLinkStreamController.add(basicData);
    _log('Added test unified link data to stream');
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
  
  /// Track the installation with the server
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
        },
        body: jsonEncode(installation.toJson()),
      );
      
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('Installation tracked successfully');
        return ULinkInstallationResponse.fromJson(responseData);
      } else {
        _log('Error tracking installation: ${response.statusCode}');
        return ULinkInstallationResponse.error(
          responseData['message'] ?? 'Error tracking installation: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log('Error tracking installation: $e');
      return ULinkInstallationResponse.error('Error tracking installation: $e');
    }
  }
  
  /// Track the installation with the server (public method)
  Future<ULinkInstallationResponse> trackInstallation({Map<String, dynamic>? metadata}) async {
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
        },
        body: jsonEncode(installation.toJson()),
      );
      
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('Installation tracked successfully');
        return ULinkInstallationResponse.fromJson(responseData);
      } else {
        _log('Error tracking installation: ${response.statusCode}');
        return ULinkInstallationResponse.error(
          responseData['message'] ?? 'Error tracking installation: ${response.statusCode}',
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

  /// Starts a new session with the ULink server
  /// 
  /// This method is called automatically during initialization
  /// but can also be called manually to start a new session.
  /// 
  /// Returns a [ULinkSessionResponse] with the session ID if successful.
  Future<ULinkSessionResponse> _startSession([Map<String, dynamic>? metadata]) async {
    if (_installationId == null) {
      _log('Cannot start session without installation ID');
      return ULinkSessionResponse.error('Installation ID not available');
    }
    
    try {
      // End any existing session first
      if (_currentSessionId != null) {
        await endSession();
      }
      
      // Collect device information automatically
      final deviceInfo = await DeviceInfoHelper.getCompleteDeviceInfo();
      _log('Collected device info for session: ${deviceInfo.keys.join(", ")}');
      
      // Extract device information
      final String? networkType = deviceInfo['networkType'] as String?;
      final String? deviceOrientation = deviceInfo['deviceOrientation'] as String?;
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
      
      return await _sendSessionStartRequest(sessionData);
    } catch (e) {
      _log('Error starting session: $e');
      return ULinkSessionResponse.error('Error starting session: $e');
    }
  }
  
  /// Helper method to send session start request to the server
  Future<ULinkSessionResponse> _sendSessionStartRequest(ULinkSession session) async {
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
        return ULinkSessionResponse.fromJson(responseData);
      } else {
        _log('Error starting session: ${response.statusCode}');
        return ULinkSessionResponse.error(
          responseData['message'] ?? 'Error starting session: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log('Error sending session request: $e');
      return ULinkSessionResponse.error('Error sending session request: $e');
    }
  }
  
  /// Start a new session with the server
  /// 
  /// This method allows you to start a new session with additional data.
  /// If a session is already active, it will be ended before starting a new one.
  /// 
  /// Device information (battery level, network type, etc.) is automatically collected
  /// when available, but you can also provide specific values to override the automatic collection.
  /// 
  /// Parameters:
  /// - [networkType]: The type of network connection (e.g., 'wifi', 'cellular')
  /// - [deviceOrientation]: The current device orientation (e.g., 'portrait', 'landscape')
  /// - [batteryLevel]: The current battery level as a percentage (0.0 to 1.0)
  /// - [isCharging]: Whether the device is currently charging
  /// - [metadata]: Additional custom data to include with the session
  Future<ULinkSessionResponse> startSession({
    String? networkType,
    String? deviceOrientation,
    double? batteryLevel,
    bool? isCharging,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _log('Starting session with metadata for installation: $_installationId');
      
      if (_installationId == null) {
        return ULinkSessionResponse.error('Installation ID not available');
      }
      
      // End any existing session first
      if (_currentSessionId != null) {
        await endSession();
      }
      
      // Collect device information automatically
      final deviceInfo = await DeviceInfoHelper.getCompleteDeviceInfo();
      _log('Collected device info for session: ${deviceInfo.keys.join(', ')}');
      
      // Use provided values or fall back to automatically collected values
      final String? sessionNetworkType = networkType ?? deviceInfo['networkType'] as String?;
      final String? sessionDeviceOrientation = deviceOrientation ?? deviceInfo['deviceOrientation'] as String?;
      final double? sessionBatteryLevel = batteryLevel ?? deviceInfo['batteryLevel'] as double?;
      final bool? sessionIsCharging = isCharging ?? deviceInfo['isCharging'] as bool?;
      
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
      
      // Create session data with all collected and provided parameters
      return await _sendSessionStartRequest(ULinkSession(
        installationId: _installationId!,
        networkType: sessionNetworkType,
        deviceOrientation: sessionDeviceOrientation,
        batteryLevel: sessionBatteryLevel,
        isCharging: sessionIsCharging,
        metadata: sessionMetadata.isEmpty ? null : sessionMetadata,
      ));
    } catch (e) {
      _log('Error starting session: $e');
      return ULinkSessionResponse.error('Error starting session: $e');
    }
  }
  
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
      
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('Session ended successfully');
        return ULinkResponse.success('Session ended successfully', responseData);
      } else {
        _log('Error ending session: ${response.statusCode}');
        return ULinkResponse.error(
          responseData['message'] ?? 'Error ending session: ${response.statusCode}',
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

/// Configuration for the ULink SDK
class ULinkConfig {
  /// The API key for the ULink service
  final String apiKey;

  /// The base URL for the ULink API
  final String baseUrl;

  /// Whether to use debug mode
  final bool debug;

  /// Persistence controls for last link data
  final bool persistLastLinkData;
  final Duration? lastLinkTimeToLive;
  final bool clearLastLinkOnRead;
  final bool redactAllParametersInLastLink;
  final List<String> redactedParameterKeysInLastLink;

  /// Whether to enable deep link integration on init
  final bool enableDeepLinkIntegration;

  /// Whether to enable automatic AppDelegate integration (iOS only)
  /// When enabled, the plugin will automatically handle universal links and URL schemes
  /// without requiring manual AppDelegate modifications
  final bool enableAutomaticAppDelegateIntegration;

  /// Whether to enable analytics
  final bool enableAnalytics;

  /// Whether to enable crash reporting
  final bool enableCrashReporting;

  /// Request timeout in milliseconds
  final int timeout;

  /// Number of retry attempts
  final int retryCount;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Whether to automatically check for deferred deep links on first app launch
  /// If false, developers must manually call checkDeferredLink() when ready
  final bool autoCheckDeferredLink;

  /// Creates a new ULink configuration
  ULinkConfig({
    required this.apiKey,
    this.baseUrl = 'https://api.ulink.ly',
    this.debug = false,
    this.persistLastLinkData = false,
    this.lastLinkTimeToLive,
    this.clearLastLinkOnRead = true,
    this.redactAllParametersInLastLink = false,
    this.redactedParameterKeysInLastLink = const [],
    this.enableDeepLinkIntegration = true,
    this.enableAutomaticAppDelegateIntegration = true,
    this.enableAnalytics = true,
    this.enableCrashReporting = false,
    this.timeout = 30000,
    this.retryCount = 3,
    this.metadata,
    this.autoCheckDeferredLink = true,
  });

  /// Converts the configuration to a map
  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'debug': debug,
      'persistLastLinkData': persistLastLinkData,
      'lastLinkTimeToLive': lastLinkTimeToLive?.inMilliseconds, // Serialize Duration to milliseconds
      'clearLastLinkOnRead': clearLastLinkOnRead,
      'redactAllParametersInLastLink': redactAllParametersInLastLink,
      'redactedParameterKeysInLastLink': redactedParameterKeysInLastLink,
      'enableDeepLinkIntegration': enableDeepLinkIntegration,
      'enableAutomaticAppDelegateIntegration': enableAutomaticAppDelegateIntegration,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'timeout': timeout,
      'retryCount': retryCount,
      'metadata': metadata,
      'autoCheckDeferredLink': autoCheckDeferredLink,
    };
  }

  /// Converts the configuration to JSON (backward compatibility)
  Map<String, dynamic> toJson() => toMap();

  /// Creates a configuration from JSON
  factory ULinkConfig.fromJson(Map<String, dynamic> json) {
    return ULinkConfig(
      apiKey: json['apiKey'],
      baseUrl: json['baseUrl'] ?? 'https://api.ulink.ly',
      debug: json['debug'] ?? false,
      persistLastLinkData: json['persistLastLinkData'] ?? false,
      lastLinkTimeToLive: json['lastLinkTimeToLive'] != null
          ? Duration(milliseconds: json['lastLinkTimeToLive'])
          : null,
      clearLastLinkOnRead: json['clearLastLinkOnRead'] ?? true,
      redactAllParametersInLastLink:
          json['redactAllParametersInLastLink'] ?? false,
      redactedParameterKeysInLastLink:
          List<String>.from(json['redactedParameterKeysInLastLink'] ?? []),
      enableDeepLinkIntegration: json['enableDeepLinkIntegration'] ?? true,
      enableAutomaticAppDelegateIntegration: json['enableAutomaticAppDelegateIntegration'] ?? true,
      enableAnalytics: json['enableAnalytics'] ?? true,
      enableCrashReporting: json['enableCrashReporting'] ?? false,
      timeout: json['timeout'] ?? 30000,
      retryCount: json['retryCount'] ?? 3,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      autoCheckDeferredLink: json['autoCheckDeferredLink'] ?? true,
    );
  }
}
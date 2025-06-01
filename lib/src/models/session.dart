/// Models for session management

/// Session data for tracking user sessions
class ULinkSession {
  /// Unique identifier for the installation
  final String installationId;

  /// Network type (wifi, cellular, etc)
  final String? networkType;

  /// Device orientation
  final String? deviceOrientation;

  /// Battery level (0-1)
  final double? batteryLevel;

  /// Whether the device is charging
  final bool? isCharging;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Creates a new session data object
  ULinkSession({
    required this.installationId,
    this.networkType,
    this.deviceOrientation,
    this.batteryLevel,
    this.isCharging,
    this.metadata,
  });

  /// Converts the session data to a JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'installationId': installationId,
    };

    if (networkType != null) data['networkType'] = networkType;
    if (deviceOrientation != null) data['deviceOrientation'] = deviceOrientation;
    if (batteryLevel != null) data['batteryLevel'] = batteryLevel;
    if (isCharging != null) data['isCharging'] = isCharging;
    if (metadata != null) data['metadata'] = metadata;

    return data;
  }

  /// Creates a session data object from JSON
  factory ULinkSession.fromJson(Map<String, dynamic> json) {
    return ULinkSession(
      installationId: json['installationId'],
      networkType: json['networkType'],
      deviceOrientation: json['deviceOrientation'],
      batteryLevel: json['batteryLevel'],
      isCharging: json['isCharging'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

/// Response from starting a session
class ULinkSessionResponse {
  /// Whether the operation was successful
  final bool success;

  /// The session ID
  final String? sessionId;

  /// Error message if unsuccessful
  final String? error;

  /// Creates a new session response
  ULinkSessionResponse({
    required this.success,
    this.sessionId,
    this.error,
  });

  /// Creates a successful response
  factory ULinkSessionResponse.success(String sessionId) {
    return ULinkSessionResponse(
      success: true,
      sessionId: sessionId,
    );
  }

  /// Creates an error response
  factory ULinkSessionResponse.error(String error) {
    return ULinkSessionResponse(
      success: false,
      error: error,
    );
  }

  /// Creates a response from JSON
  factory ULinkSessionResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return ULinkSessionResponse.error(json['error']);
    }

    return ULinkSessionResponse(
      success: json['success'] ?? false,
      sessionId: json['sessionId'],
    );
  }
}
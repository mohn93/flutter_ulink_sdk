/// Models for installation tracking
library;

/// Installation data for tracking app installations
class ULinkInstallation {
  /// Unique identifier for the installation
  final String installationId;

  /// Device identifier
  final String? deviceId;

  /// Device model
  final String? deviceModel;

  /// Device manufacturer
  final String? deviceManufacturer;

  /// Operating system name
  final String? osName;

  /// Operating system version
  final String? osVersion;

  /// App version
  final String? appVersion;

  /// App build number
  final String? appBuild;

  /// User language
  final String? language;

  /// User timezone
  final String? timezone;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Creates a new installation data object
  ULinkInstallation({
    required this.installationId,
    this.deviceId,
    this.deviceModel,
    this.deviceManufacturer,
    this.osName,
    this.osVersion,
    this.appVersion,
    this.appBuild,
    this.language,
    this.timezone,
    this.metadata,
  });

  /// Converts the installation data to a JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'installationId': installationId,
    };

    if (deviceId != null) data['deviceId'] = deviceId;
    if (deviceModel != null) data['deviceModel'] = deviceModel;
    if (deviceManufacturer != null) {
      data['deviceManufacturer'] = deviceManufacturer;
    }
    if (osName != null) data['osName'] = osName;
    if (osVersion != null) data['osVersion'] = osVersion;
    if (appVersion != null) data['appVersion'] = appVersion;
    if (appBuild != null) data['appBuild'] = appBuild;
    if (language != null) data['language'] = language;
    if (timezone != null) data['timezone'] = timezone;
    if (metadata != null) data['metadata'] = metadata;

    return data;
  }

  /// Creates an installation data object from JSON
  factory ULinkInstallation.fromJson(Map<String, dynamic> json) {
    return ULinkInstallation(
      installationId: json['installationId'],
      deviceId: json['deviceId'],
      deviceModel: json['deviceModel'],
      deviceManufacturer: json['deviceManufacturer'],
      osName: json['osName'],
      osVersion: json['osVersion'],
      appVersion: json['appVersion'],
      appBuild: json['appBuild'],
      language: json['language'],
      timezone: json['timezone'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

/// Response from tracking an installation
class ULinkInstallationResponse {
  /// Whether the operation was successful
  final bool success;

  /// The installation ID
  final String? installationId;

  /// Whether this is a new installation
  final bool? isNew;

  /// Error message if unsuccessful
  final String? error;

  /// Creates a new installation response
  ULinkInstallationResponse({
    required this.success,
    this.installationId,
    this.isNew,
    this.error,
  });

  /// Creates a successful response
  factory ULinkInstallationResponse.success(String installationId, bool isNew) {
    return ULinkInstallationResponse(
      success: true,
      installationId: installationId,
      isNew: isNew,
    );
  }

  /// Creates an error response
  factory ULinkInstallationResponse.error(String error) {
    return ULinkInstallationResponse(
      success: false,
      error: error,
    );
  }

  /// Creates a response from JSON
  factory ULinkInstallationResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return ULinkInstallationResponse.error(json['error']);
    }

    return ULinkInstallationResponse(
      success: json['success'] ?? false,
      installationId: json['installationId'],
      isNew: json['isNew'],
    );
  }
}

/// Contains information about the current installation, including reinstall detection data.
///
/// This data is returned from the bootstrap process and indicates whether the current
/// installation was detected as a reinstall of a previous installation.
class ULinkInstallationInfo {
  /// The unique identifier for this installation (client-generated UUID)
  final String installationId;

  /// Whether this installation was detected as a reinstall
  final bool isReinstall;

  /// The ID of the previous installation if this is a reinstall.
  /// Null if this is a fresh install or reinstall detection is not available.
  final String? previousInstallationId;

  /// Timestamp when the reinstall was detected (ISO 8601 format)
  final String? reinstallDetectedAt;

  /// The persistent device ID used for reinstall detection
  final String? persistentDeviceId;

  const ULinkInstallationInfo({
    required this.installationId,
    this.isReinstall = false,
    this.previousInstallationId,
    this.reinstallDetectedAt,
    this.persistentDeviceId,
  });

  /// Creates a ULinkInstallationInfo from a JSON map
  factory ULinkInstallationInfo.fromJson(Map<String, dynamic> json) {
    return ULinkInstallationInfo(
      installationId: json['installationId'] as String? ?? '',
      isReinstall: json['isReinstall'] as bool? ?? false,
      previousInstallationId: json['previousInstallationId'] as String?,
      reinstallDetectedAt: json['reinstallDetectedAt'] as String?,
      persistentDeviceId: json['persistentDeviceId'] as String?,
    );
  }

  /// Converts this instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'installationId': installationId,
      'isReinstall': isReinstall,
      if (previousInstallationId != null)
        'previousInstallationId': previousInstallationId,
      if (reinstallDetectedAt != null)
        'reinstallDetectedAt': reinstallDetectedAt,
      if (persistentDeviceId != null) 'persistentDeviceId': persistentDeviceId,
    };
  }

  /// Creates a fresh installation info (not a reinstall)
  factory ULinkInstallationInfo.freshInstall({
    required String installationId,
    String? persistentDeviceId,
  }) {
    return ULinkInstallationInfo(
      installationId: installationId,
      isReinstall: false,
      persistentDeviceId: persistentDeviceId,
    );
  }

  @override
  String toString() {
    return 'ULinkInstallationInfo(installationId: $installationId, isReinstall: $isReinstall, previousInstallationId: $previousInstallationId, reinstallDetectedAt: $reinstallDetectedAt, persistentDeviceId: $persistentDeviceId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ULinkInstallationInfo &&
        other.installationId == installationId &&
        other.isReinstall == isReinstall &&
        other.previousInstallationId == previousInstallationId &&
        other.reinstallDetectedAt == reinstallDetectedAt &&
        other.persistentDeviceId == persistentDeviceId;
  }

  @override
  int get hashCode {
    return installationId.hashCode ^
        isReinstall.hashCode ^
        previousInstallationId.hashCode ^
        reinstallDetectedAt.hashCode ^
        persistentDeviceId.hashCode;
  }
}

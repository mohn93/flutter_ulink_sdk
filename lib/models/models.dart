/// Models for the ULink Bridge SDK
library;

export 'ulink_config.dart';
export 'ulink_parameters.dart';
export 'ulink_resolved_data.dart';
export 'ulink_response.dart';
export 'social_media_tags.dart';
export 'session_state.dart';
export 'ulink_log_entry.dart';
export 'ulink_installation_info.dart';

/// Enumeration for different types of links
enum ULinkType {
  /// Dynamic links designed for app deep linking with parameters, fallback URLs, and smart app store redirects
  dynamic,

  /// Simple platform-based redirects (iOS URL, Android URL, fallback URL) intended for in-app handling
  unified,
}

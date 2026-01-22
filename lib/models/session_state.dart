/// Session states for tracking session lifecycle
enum SessionState {
  /// No session operation in progress
  idle,

  /// Session start request sent, waiting for response
  initializing,

  /// Session successfully started
  active,

  /// Session end request sent
  ending,

  /// Session start/end failed
  failed,
}

/// Extension to convert SessionState to string
extension SessionStateExtension on SessionState {
  String get value {
    switch (this) {
      case SessionState.idle:
        return 'idle';
      case SessionState.initializing:
        return 'initializing';
      case SessionState.active:
        return 'active';
      case SessionState.ending:
        return 'ending';
      case SessionState.failed:
        return 'failed';
    }
  }

  static SessionState fromString(String value) {
    switch (value) {
      case 'idle':
        return SessionState.idle;
      case 'initializing':
        return SessionState.initializing;
      case 'active':
        return SessionState.active;
      case 'ending':
        return SessionState.ending;
      case 'failed':
        return SessionState.failed;
      default:
        return SessionState.idle;
    }
  }
}

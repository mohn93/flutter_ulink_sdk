/// Represents a log entry from the ULink SDK
class ULinkLogEntry {
  /// Log level: debug, info, warning, error
  final String level;

  /// Log tag/source
  final String tag;

  /// Log message
  final String message;

  /// Timestamp in milliseconds since epoch
  final int timestamp;

  /// Creates a log entry
  ULinkLogEntry({
    required this.level,
    required this.tag,
    required this.message,
    required this.timestamp,
  });

  /// Creates a log entry from a map
  factory ULinkLogEntry.fromMap(Map<dynamic, dynamic> map) {
    return ULinkLogEntry(
      level: map['level'] as String? ?? 'debug',
      tag: map['tag'] as String? ?? 'ULink',
      message: map['message'] as String? ?? '',
      timestamp:
          map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Converts to a map
  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'tag': tag,
      'message': message,
      'timestamp': timestamp,
    };
  }

  /// Returns the DateTime of this log entry
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// Returns a formatted time string (HH:mm:ss.SSS)
  String get formattedTime {
    final dt = dateTime;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}.${dt.millisecond.toString().padLeft(3, '0')}';
  }

  /// Log level constants
  static const String levelDebug = 'debug';
  static const String levelInfo = 'info';
  static const String levelWarning = 'warning';
  static const String levelError = 'error';

  @override
  String toString() => '[$formattedTime] [$level] [$tag] $message';
}

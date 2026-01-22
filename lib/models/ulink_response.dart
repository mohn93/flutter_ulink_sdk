/// Response from creating or resolving a ULink
class ULinkResponse {
  /// Whether the operation was successful
  final bool success;

  /// The generated URL (for createLink) or resolved URL (for resolveLink)
  final String? url;

  /// Error message if unsuccessful
  final String? error;

  /// Raw response data
  final Map<String, dynamic>? data;

  /// Creates a new ULink response
  ULinkResponse({
    required this.success,
    this.url,
    this.error,
    this.data,
  });

  /// Creates a successful response
  factory ULinkResponse.success(String url, [Map<String, dynamic>? data]) {
    return ULinkResponse(
      success: true,
      url: url,
      data: data,
    );
  }

  /// Creates an error response
  factory ULinkResponse.error(String error) {
    return ULinkResponse(
      success: false,
      error: error,
    );
  }

  /// Creates a response from a Map (for platform channel)
  factory ULinkResponse.fromMap(Map<String, dynamic> map) {
    return ULinkResponse(
      success: map['success'] == true,
      url: map['url'] as String?,
      error: map['error'] as String?,
      data: map['data'] != null
          ? Map<String, dynamic>.from(map['data'] as Map)
          : null,
    );
  }

  /// Creates a response from JSON
  factory ULinkResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return ULinkResponse.error(json['error']);
    }

    return ULinkResponse.success(
      json['url'] ?? '',
      json,
    );
  }

  /// Converts the response to a Map
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      if (url != null) 'url': url,
      if (error != null) 'error': error,
      if (data != null) 'data': data,
    };
  }
}

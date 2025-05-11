/// Models for the ULink SDK

/// Configuration for the ULink SDK
class ULinkConfig {
  /// The API key for the ULink service
  final String apiKey;

  /// The base URL for the ULink API
  final String baseUrl;

  /// Whether to use debug mode
  final bool debug;

  /// Creates a new ULink configuration
  ULinkConfig({
    required this.apiKey,
    this.baseUrl = 'https://api.ulink.ly',
    this.debug = false,
  });
}

/// Social media tags for Open Graph metadata
class SocialMediaTags {
  /// The title to be displayed when shared on social media
  final String? ogTitle;

  /// The description to be displayed when shared on social media
  final String? ogDescription;

  /// The image URL to be displayed when shared on social media
  final String? ogImage;

  /// Creates a new set of social media tags
  SocialMediaTags({
    this.ogTitle,
    this.ogDescription,
    this.ogImage,
  });

  /// Converts the social media tags to a JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (ogTitle != null) data['ogTitle'] = ogTitle;
    if (ogDescription != null) data['ogDescription'] = ogDescription;
    if (ogImage != null) data['ogImage'] = ogImage;

    return data;
  }
}

/// Dynamic link parameters
class ULinkParameters {
  /// Optional custom slug for the link
  final String? slug;

  /// iOS fallback URL for the link
  final String? iosFallbackUrl;

  /// Android fallback URL for the link
  final String? androidFallbackUrl;

  /// Fallback URL for the link
  final String? fallbackUrl;

  /// Additional parameters for the link
  final Map<String, dynamic>? parameters;

  /// Social media tags for the link
  final SocialMediaTags? socialMediaTags;

  /// Creates a new set of ULink parameters
  ULinkParameters({
    this.slug,
    this.iosFallbackUrl,
    this.androidFallbackUrl,
    this.fallbackUrl,
    this.parameters,
    this.socialMediaTags,
  });

  /// Converts the parameters to a JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (slug != null) data['slug'] = slug;
    if (iosFallbackUrl != null) data['iosFallbackUrl'] = iosFallbackUrl;
    if (androidFallbackUrl != null)
      data['androidFallbackUrl'] = androidFallbackUrl;
    if (fallbackUrl != null) data['fallbackUrl'] = fallbackUrl;

    // Merge regular parameters and social media tags
    final Map<String, dynamic> allParameters = {};
    if (parameters != null) {
      allParameters.addAll(parameters!);
    }

    if (socialMediaTags != null) {
      allParameters.addAll(socialMediaTags!.toJson());
    }

    if (allParameters.isNotEmpty) {
      data['parameters'] = allParameters;
    }

    return data;
  }
}

/// Response from creating a dynamic link
class ULinkResponse {
  /// Whether the operation was successful
  final bool success;

  /// The generated URL
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
  factory ULinkResponse.success(String url, Map<String, dynamic> data) {
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
}

/// Resolved dynamic link data
class ULinkResolvedData {
  /// The original slug used to create the link
  final String? slug;

  /// iOS fallback URL for the link
  final String? iosFallbackUrl;

  /// Android fallback URL for the link
  final String? androidFallbackUrl;

  /// Fallback URL for the link
  final String? fallbackUrl;

  /// Additional parameters from the link
  final Map<String, dynamic>? parameters;

  /// Social media tags from the link
  final SocialMediaTags? socialMediaTags;

  /// Raw data from the response
  final Map<String, dynamic> rawData;

  /// Creates a new resolved link data object
  ULinkResolvedData({
    this.slug,
    this.iosFallbackUrl,
    this.androidFallbackUrl,
    this.fallbackUrl,
    this.parameters,
    this.socialMediaTags,
    required this.rawData,
  });

  /// Creates a resolved link data object from JSON
  factory ULinkResolvedData.fromJson(Map<String, dynamic> json) {
    // Extract social media tags if they exist
    SocialMediaTags? socialMediaTags;
    Map<String, dynamic>? parameters =
        json['parameters'] as Map<String, dynamic>?;

    if (parameters != null) {
      // Extract social media tags
      final ogTitle = parameters['ogTitle'];
      final ogDescription = parameters['ogDescription'];
      final ogImage = parameters['ogImage'];

      if (ogTitle != null || ogDescription != null || ogImage != null) {
        socialMediaTags = SocialMediaTags(
          ogTitle: ogTitle,
          ogDescription: ogDescription,
          ogImage: ogImage,
        );
      }
    }

    return ULinkResolvedData(
      slug: json['slug'],
      iosFallbackUrl: json['iosFallbackUrl'],
      androidFallbackUrl: json['androidFallbackUrl'],
      fallbackUrl: json['fallbackUrl'],
      parameters: parameters,
      socialMediaTags: socialMediaTags,
      rawData: json,
    );
  }
}

/// Models for the ULink SDK
library;

export 'installation.dart';
export 'session.dart';

/// Enumeration for different types of links
enum ULinkType {
  /// Dynamic links designed for app deep linking with parameters, fallback URLs, and smart app store redirects
  dynamic,

  /// Simple platform-based redirects (iOS URL, Android URL, fallback URL) intended for browser handling
  unified,
}

/// Configuration for the ULink SDK
class ULinkConfig {
  /// The API key for the ULink service
  final String apiKey;

  /// The base URL for the ULink API
  final String baseUrl;

  /// Whether to use debug mode
  final bool debug;

  // Persistence controls for last link data (parity with Android)
  final bool persistLastLinkData;
  final Duration? lastLinkTimeToLive;
  final bool clearLastLinkOnRead;
  final bool redactAllParametersInLastLink;
  final List<String> redactedParameterKeysInLastLink;

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
  /// Link type: "unified" or "dynamic"
  final String? type;

  /// Optional custom slug for the link
  final String? slug;

  /// iOS URL for unified links (direct iOS app store or web URL)
  final String? iosUrl;

  /// Android URL for unified links (direct Google Play or web URL)
  final String? androidUrl;

  /// iOS fallback URL for dynamic links
  final String? iosFallbackUrl;

  /// Android fallback URL for dynamic links
  final String? androidFallbackUrl;

  /// Fallback URL for the link
  final String? fallbackUrl;

  /// Additional parameters for the link (non-social media parameters)
  final Map<String, dynamic>? parameters;

  /// Social media tags for the link
  final SocialMediaTags? socialMediaTags;

  /// Metadata map for social media data
  final Map<String, dynamic>? metadata;

  /// Creates a new set of ULink parameters
  ULinkParameters({
    this.type,
    this.slug,
    this.iosUrl,
    this.androidUrl,
    this.iosFallbackUrl,
    this.androidFallbackUrl,
    this.fallbackUrl,
    this.parameters,
    this.socialMediaTags,
    this.metadata,
  });

  /// Factory constructor for creating dynamic links
  /// Dynamic links are designed for in-app deep linking with parameters and smart app store redirects
  factory ULinkParameters.dynamic({
    String? slug,
    String? iosFallbackUrl,
    String? androidFallbackUrl,
    String? fallbackUrl,
    Map<String, dynamic>? parameters,
    SocialMediaTags? socialMediaTags,
    Map<String, dynamic>? metadata,
  }) {
    return ULinkParameters(
      type: 'dynamic',
      slug: slug,
      iosFallbackUrl: iosFallbackUrl,
      androidFallbackUrl: androidFallbackUrl,
      fallbackUrl: fallbackUrl,
      parameters: parameters,
      socialMediaTags: socialMediaTags,
      metadata: metadata,
    );
  }

  /// Factory constructor for creating unified links
  /// Unified links are simple platform-based redirects intended for browser handling
  factory ULinkParameters.unified({
    String? slug,
    required String iosUrl,
    required String androidUrl,
    required String fallbackUrl,
    Map<String, dynamic>? parameters,
    SocialMediaTags? socialMediaTags,
    Map<String, dynamic>? metadata,
  }) {
    return ULinkParameters(
      type: 'unified',
      slug: slug,
      iosUrl: iosUrl,
      androidUrl: androidUrl,
      fallbackUrl: fallbackUrl,
      parameters: parameters,
      socialMediaTags: socialMediaTags,
      metadata: metadata,
    );
  }

  /// Converts the parameters to a JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (type != null) data['type'] = type;
    if (slug != null) data['slug'] = slug;
    if (iosUrl != null) data['iosUrl'] = iosUrl;
    if (androidUrl != null) data['androidUrl'] = androidUrl;
    if (iosFallbackUrl != null) data['iosFallbackUrl'] = iosFallbackUrl;
    if (androidFallbackUrl != null) {
      data['androidFallbackUrl'] = androidFallbackUrl;
    }
    if (fallbackUrl != null) data['fallbackUrl'] = fallbackUrl;

    // Handle regular parameters (non-social media)
    final Map<String, dynamic> regularParameters = {};
    if (parameters != null) {
      // Filter out social media parameters from regular parameters
      parameters!.forEach((key, value) {
        if (!key.startsWith('og') && !_isSocialMediaParameter(key)) {
          regularParameters[key] = value;
        }
      });
    }

    if (regularParameters.isNotEmpty) {
      data['parameters'] = regularParameters;
    }

    // Handle metadata (social media data)
    final Map<String, dynamic> metadataMap = {};

    // Add social media tags from socialMediaTags object
    if (socialMediaTags != null) {
      metadataMap.addAll(socialMediaTags!.toJson());
    }

    // Add social media parameters from parameters map
    if (parameters != null) {
      parameters!.forEach((key, value) {
        if (key.startsWith('og') || _isSocialMediaParameter(key)) {
          metadataMap[key] = value;
        }
      });
    }

    // Add explicit metadata
    if (metadata != null) {
      metadataMap.addAll(metadata!);
    }

    if (metadataMap.isNotEmpty) {
      data['metadata'] = metadataMap;
    }

    return data;
  }

  /// Helper method to identify social media parameters
  bool _isSocialMediaParameter(String key) {
    const socialMediaKeys = [
      'ogTitle',
      'ogDescription',
      'ogImage',
      'ogSiteName',
      'ogType',
      'ogUrl',
      'twitterCard',
      'twitterSite',
      'twitterCreator',
      'twitterTitle',
      'twitterDescription',
      'twitterImage',
    ];
    return socialMediaKeys.contains(key);
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

  /// Additional parameters from the link (non-social media parameters)
  final Map<String, dynamic>? parameters;

  /// Social media tags from the link
  final SocialMediaTags? socialMediaTags;

  /// Metadata containing social media data
  final Map<String, dynamic>? metadata;

  /// The type of link (dynamic or unified)
  final ULinkType linkType;

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
    this.metadata,
    this.linkType = ULinkType.dynamic,
    required this.rawData,
  });

  /// Creates a resolved link data object from JSON
  factory ULinkResolvedData.fromJson(Map<String, dynamic> json) {
    // Extract social media tags from metadata if it exists
    SocialMediaTags? socialMediaTags;
    Map<String, dynamic>? metadata = json['metadata'] as Map<String, dynamic>?;
    Map<String, dynamic>? parameters =
        json['parameters'] as Map<String, dynamic>?;

    // Try to extract social media tags from metadata first
    if (metadata != null) {
      final ogTitle = metadata['ogTitle'];
      final ogDescription = metadata['ogDescription'];
      final ogImage = metadata['ogImage'];

      if (ogTitle != null || ogDescription != null || ogImage != null) {
        socialMediaTags = SocialMediaTags(
          ogTitle: ogTitle,
          ogDescription: ogDescription,
          ogImage: ogImage,
        );
      }
    }

    // Fallback: check parameters for backward compatibility
    if (socialMediaTags == null && parameters != null) {
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

    // Determine link type based on type field from rawData
    final typeFromData = json['type'] as String?;
    final linkType =
        typeFromData == 'dynamic' ? ULinkType.dynamic : ULinkType.unified;

    return ULinkResolvedData(
      slug: json['slug'],
      iosFallbackUrl: json['iosUrl'] ?? json['iosFallbackUrl'],
      androidFallbackUrl: json['androidUrl'] ?? json['androidFallbackUrl'],
      fallbackUrl: json['fallbackUrl'],
      parameters: parameters,
      socialMediaTags: socialMediaTags,
      metadata: metadata,
      linkType: linkType,
      rawData: json,
    );
  }
}

import 'models.dart';

/// Dynamic link parameters
class ULinkParameters {
  /// Link type: "unified" or "dynamic"
  final String type;

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

  /// Domain host to use for the link (e.g., "example.com" or "subdomain.shared.ly")
  /// Required to ensure consistent link generation and prevent app breakage
  /// when projects have multiple domains configured.
  final String domain;

  /// Creates a new set of ULink parameters
  ULinkParameters({
    this.type = 'dynamic',
    required this.domain,
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
    required String domain,
    String? slug,
    String? iosFallbackUrl,
    String? androidFallbackUrl,
    String? fallbackUrl,
    Map<String, dynamic>? parameters,
    SocialMediaTags? socialMediaTags,
  }) {
    return ULinkParameters(
      type: 'dynamic',
      domain: domain,
      slug: slug,
      iosFallbackUrl: iosFallbackUrl,
      androidFallbackUrl: androidFallbackUrl,
      fallbackUrl: fallbackUrl,
      parameters: parameters,
      socialMediaTags: socialMediaTags,
    );
  }

  /// Factory constructor for creating unified links
  /// Unified links are simple platform-based redirects intended for in-app handling
  factory ULinkParameters.unified({
    required String domain,
    String? slug,
    String? iosUrl,
    String? androidUrl,
    String? fallbackUrl,
    Map<String, dynamic>? parameters,
    SocialMediaTags? socialMediaTags,
  }) {
    return ULinkParameters(
      type: 'unified',
      domain: domain,
      slug: slug,
      iosUrl: iosUrl,
      androidUrl: androidUrl,
      fallbackUrl: fallbackUrl,
      parameters: parameters,
      socialMediaTags: socialMediaTags,
    );
  }

  /// Converts the parameters to a JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': type,
      'domain': domain,
    };

    if (slug != null) data['slug'] = slug;
    if (iosUrl != null) data['iosUrl'] = iosUrl;
    if (androidUrl != null) data['androidUrl'] = androidUrl;
    if (iosFallbackUrl != null) data['iosFallbackUrl'] = iosFallbackUrl;
    if (androidFallbackUrl != null)
      data['androidFallbackUrl'] = androidFallbackUrl;
    if (fallbackUrl != null) data['fallbackUrl'] = fallbackUrl;
    if (parameters != null) data['parameters'] = parameters;
    if (socialMediaTags != null)
      data['socialMediaTags'] = socialMediaTags!.toJson();
    if (metadata != null) data['metadata'] = metadata;

    return data;
  }

  /// Creates parameters from JSON
  factory ULinkParameters.fromJson(Map<String, dynamic> json) {
    return ULinkParameters(
      type: json['type'] ?? 'dynamic',
      domain: json['domain'] ?? '',
      slug: json['slug'],
      iosUrl: json['iosUrl'],
      androidUrl: json['androidUrl'],
      iosFallbackUrl: json['iosFallbackUrl'],
      androidFallbackUrl: json['androidFallbackUrl'],
      fallbackUrl: json['fallbackUrl'],
      parameters: json['parameters'] != null
          ? Map<String, dynamic>.from(json['parameters'])
          : null,
      socialMediaTags: json['socialMediaTags'] != null
          ? SocialMediaTags.fromJson(json['socialMediaTags'])
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

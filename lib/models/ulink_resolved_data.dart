import 'models.dart';

/// Resolved link data containing information about a ULink
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
    Map<String, dynamic>? metadata;
    Map<String, dynamic>? parameters;
    
    // Safely extract metadata
    final metadataRaw = json['metadata'];
    if (metadataRaw is Map) {
      metadata = Map<String, dynamic>.from(metadataRaw);
    }
    
    // Safely extract parameters
    final parametersRaw = json['parameters'];
    if (parametersRaw is Map) {
      parameters = Map<String, dynamic>.from(parametersRaw);
    }

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

  /// Converts the resolved data to a JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': linkType == ULinkType.dynamic ? 'dynamic' : 'unified',
    };

    if (slug != null) data['slug'] = slug;
    if (iosFallbackUrl != null) data['iosFallbackUrl'] = iosFallbackUrl;
    if (androidFallbackUrl != null) data['androidFallbackUrl'] = androidFallbackUrl;
    if (fallbackUrl != null) data['fallbackUrl'] = fallbackUrl;
    if (parameters != null) data['parameters'] = parameters;
    if (socialMediaTags != null) data['socialMediaTags'] = socialMediaTags!.toJson();
    if (metadata != null) data['metadata'] = metadata;
    
    // Include raw data
    data.addAll(rawData);

    return data;
  }
}
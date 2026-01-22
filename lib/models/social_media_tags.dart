/// Social media tags for link sharing
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

  /// Creates social media tags from JSON
  factory SocialMediaTags.fromJson(Map<String, dynamic> json) {
    return SocialMediaTags(
      ogTitle: json['ogTitle'],
      ogDescription: json['ogDescription'],
      ogImage: json['ogImage'],
    );
  }
}

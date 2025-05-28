/// Demo script showing the new metadata functionality
/// This shows the JSON structure that will be sent to the API
/// Run with: dart example/test/metadata_demo.dart
void main() {
  print('ULink SDK Metadata Functionality Demo');
  print('=====================================\n');

  // Example showing the JSON structure that gets generated
  print('Example 1: JSON structure with metadata separation');
  print('-------------------------------------------------');

  final json1 = {
    'slug': 'product-123',
    'iosFallbackUrl': 'myapp://product/123',
    'androidFallbackUrl': 'myapp://product/123',
    'fallbackUrl': 'https://myapp.com/product/123',
    'parameters': {
      'utm_source': 'app',
      'utm_medium': 'share',
      'campaign': 'summer_sale',
      'productId': '123',
    },
    'metadata': {
      'ogTitle': 'Amazing Summer Sale Product',
      'ogDescription':
          'Get 50% off on this amazing product during our summer sale!',
      'ogImage': 'https://example.com/product-123.jpg',
      'ogSiteName': 'My App Store',
      'ogType': 'product',
      'twitterCard': 'summary_large_image',
    },
  };

  print('Generated JSON structure:');
  _prettyPrintJson(json1);
  print(
      '\n✅ Notice: Social media data is in "metadata", business data is in "parameters"\n');

  // Example 2: Before vs After comparison
  print('Example 2: Before vs After - Parameter separation');
  print('-----------------------------------------------');

  print('BEFORE (old approach - all in parameters):');
  final beforeJson = {
    'slug': 'product-456',
    'fallbackUrl': 'https://myapp.com/product/456',
    'parameters': {
      'utm_source': 'email',
      'utm_campaign': 'newsletter',
      'productId': '456',
      'ogTitle': 'Product from Email Campaign', // Mixed with business data
      'ogDescription': 'Check out this product from our newsletter!',
      'ogImage': 'https://example.com/product-456.jpg',
    },
  };
  _prettyPrintJson(beforeJson);

  print('\nAFTER (new approach - separated):');
  final afterJson = {
    'slug': 'product-456',
    'fallbackUrl': 'https://myapp.com/product/456',
    'parameters': {
      'utm_source': 'email',
      'utm_campaign': 'newsletter',
      'productId': '456',
    },
    'metadata': {
      'ogTitle': 'Product from Email Campaign',
      'ogDescription': 'Check out this product from our newsletter!',
      'ogImage': 'https://example.com/product-456.jpg',
    },
  };
  _prettyPrintJson(afterJson);

  print('\n✅ Notice: Much cleaner separation of concerns!\n');

  // Example 3: API Response structure
  print('Example 3: API Response with metadata');
  print('------------------------------------');

  final responseJson = {
    'slug': 'resolved-link',
    'iosFallbackUrl': 'myapp://resolved',
    'androidFallbackUrl': 'myapp://resolved',
    'fallbackUrl': 'https://myapp.com/resolved',
    'parameters': {
      'utm_source': 'resolved_test',
      'utm_campaign': 'metadata_demo',
      'customParam': 'resolvedValue',
    },
    'metadata': {
      'ogTitle': 'Resolved Link Title',
      'ogDescription': 'This link was resolved with metadata separation',
      'ogImage': 'https://example.com/resolved.jpg',
      'ogSiteName': 'Resolved App',
    },
  };

  print('API Response JSON:');
  _prettyPrintJson(responseJson);

  print('\n✅ All examples demonstrate the new metadata functionality!');
  print('📋 Summary of changes:');
  print('   • Added "metadata" field to ULinkParameters and ULinkResolvedData');
  print(
      '   • Social media parameters (og*, twitter*) are automatically moved to metadata');
  print('   • Regular business/tracking parameters stay in parameters');
  print('   • Backward compatibility maintained for existing code');
  print(
      '   • SocialMediaTags class now populates metadata instead of parameters');

  print('\n🚀 Usage Examples:');
  print('   // New metadata field:');
  print('   ULinkParameters(metadata: {"ogTitle": "Title", "ogImage": "url"})');
  print('   ');
  print('   // Auto-separation from parameters:');
  print(
      '   ULinkParameters(parameters: {"utm_source": "app", "ogTitle": "Title"})');
  print(
      '   // Result: {"parameters": {"utm_source": "app"}, "metadata": {"ogTitle": "Title"}}');
  print('   ');
  print('   // SocialMediaTags class (now goes to metadata):');
  print(
      '   ULinkParameters(socialMediaTags: SocialMediaTags(ogTitle: "Title"))');
  print('   // Result: {"metadata": {"ogTitle": "Title"}}');
}

void _prettyPrintJson(Map<String, dynamic> json, [int indent = 0]) {
  final spaces = '  ' * indent;
  print('$spaces{');

  json.forEach((key, value) {
    if (value is Map<String, dynamic>) {
      print('$spaces  "$key": {');
      value.forEach((subKey, subValue) {
        print('$spaces    "$subKey": ${_formatValue(subValue)},');
      });
      print('$spaces  },');
    } else {
      print('$spaces  "$key": ${_formatValue(value)},');
    }
  });

  print('$spaces}');
}

String _formatValue(dynamic value) {
  if (value is String) {
    return '"$value"';
  }
  return value.toString();
}

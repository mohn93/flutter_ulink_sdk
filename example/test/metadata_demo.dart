import 'package:flutter/foundation.dart';

/// Demo script showing the new metadata functionality
/// This shows the JSON structure that will be sent to the API
/// Run with: dart example/test/metadata_demo.dart
void main() {
  debugPrint('ULink SDK Metadata Functionality Demo');
  debugPrint('=====================================\n');

  // Example showing the JSON structure that gets generated
  debugPrint('Example 1: JSON structure with metadata separation');
  debugPrint('-------------------------------------------------');

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

  debugPrint('Generated JSON structure:');
  _prettydebugPrintJson(json1);
  debugPrint(
      '\n✅ Notice: Social media data is in "metadata", business data is in "parameters"\n');

  // Example 2: Before vs After comparison
  debugPrint('Example 2: Before vs After - Parameter separation');
  debugPrint('-----------------------------------------------');

  debugPrint('BEFORE (old approach - all in parameters):');
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
  _prettydebugPrintJson(beforeJson);

  debugPrint('\nAFTER (new approach - separated):');
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
  _prettydebugPrintJson(afterJson);

  debugPrint('\n✅ Notice: Much cleaner separation of concerns!\n');

  // Example 3: API Response structure
  debugPrint('Example 3: API Response with metadata');
  debugPrint('------------------------------------');

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

  debugPrint('API Response JSON:');
  _prettydebugPrintJson(responseJson);

  debugPrint('\n✅ All examples demonstrate the new metadata functionality!');
  debugPrint('📋 Summary of changes:');
  debugPrint(
      '   • Added "metadata" field to ULinkParameters and ULinkResolvedData');
  debugPrint(
      '   • Social media parameters (og*, twitter*) are automatically moved to metadata');
  debugPrint('   • Regular business/tracking parameters stay in parameters');
  debugPrint('   • Backward compatibility maintained for existing code');
  debugPrint(
      '   • SocialMediaTags class now populates metadata instead of parameters');

  debugPrint('\n🚀 Usage Examples:');
  debugPrint('   // New metadata field:');
  debugPrint(
      '   ULinkParameters(metadata: {"ogTitle": "Title", "ogImage": "url"})');
  debugPrint('   ');
  debugPrint('   // Auto-separation from parameters:');
  debugPrint(
      '   ULinkParameters(parameters: {"utm_source": "app", "ogTitle": "Title"})');
  debugPrint(
      '   // Result: {"parameters": {"utm_source": "app"}, "metadata": {"ogTitle": "Title"}}');
  debugPrint('   ');
  debugPrint('   // SocialMediaTags class (now goes to metadata):');
  debugPrint(
      '   ULinkParameters(socialMediaTags: SocialMediaTags(ogTitle: "Title"))');
  debugPrint('   // Result: {"metadata": {"ogTitle": "Title"}}');
}

void _prettydebugPrintJson(Map<String, dynamic> json, [int indent = 0]) {
  final spaces = '  ' * indent;
  debugPrint('$spaces{');

  json.forEach((key, value) {
    if (value is Map<String, dynamic>) {
      debugPrint('$spaces  "$key": {');
      value.forEach((subKey, subValue) {
        debugPrint('$spaces    "$subKey": ${_formatValue(subValue)},');
      });
      debugPrint('$spaces  },');
    } else {
      debugPrint('$spaces  "$key": ${_formatValue(value)},');
    }
  });

  debugPrint('$spaces}');
}

String _formatValue(dynamic value) {
  if (value is String) {
    return '"$value"';
  }
  return value.toString();
}

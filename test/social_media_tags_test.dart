import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk_method_channel.dart';
import 'package:flutter_ulink_sdk/models/models.dart';

/// Tests for social media tags serialization.
///
/// These tests guard the Dart-to-native bridge contract. Both the iOS and
/// Android plugins read specific key names from the map sent over the method
/// channel. If these keys change in Dart without matching changes in native
/// code, social media previews silently break on one or both platforms.
///
/// Regression: https://github.com/mohn93/flutter_ulink_sdk/issues/XXX
/// iOS plugin was reading "title"/"description"/"imageUrl" instead of
/// "ogTitle"/"ogDescription"/"ogImage", causing social previews to be empty.
void main() {
  group('SocialMediaTags', () {
    test('toJson uses ogTitle, ogDescription, ogImage keys', () {
      final tags = SocialMediaTags(
        ogTitle: 'Test Title',
        ogDescription: 'Test Description',
        ogImage: 'https://example.com/image.png',
      );

      final json = tags.toJson();

      // These exact keys are read by both native plugins.
      // iOS: socialMediaArgs["ogTitle"], socialMediaArgs["ogDescription"], socialMediaArgs["ogImage"]
      // Android: it["ogTitle"], it["ogDescription"], it["ogImage"]
      expect(json.containsKey('ogTitle'), isTrue);
      expect(json.containsKey('ogDescription'), isTrue);
      expect(json.containsKey('ogImage'), isTrue);
      expect(json['ogTitle'], 'Test Title');
      expect(json['ogDescription'], 'Test Description');
      expect(json['ogImage'], 'https://example.com/image.png');
    });

    test('toJson must NOT use "title", "description", "imageUrl" keys', () {
      final tags = SocialMediaTags(
        ogTitle: 'Test Title',
        ogDescription: 'Test Description',
        ogImage: 'https://example.com/image.png',
      );

      final json = tags.toJson();

      // These wrong keys were the cause of the iOS bug.
      // If someone accidentally changes toJson to use these, this test catches it.
      expect(json.containsKey('title'), isFalse,
          reason: 'Must use "ogTitle", not "title" — native plugins expect "ogTitle"');
      expect(json.containsKey('description'), isFalse,
          reason: 'Must use "ogDescription", not "description" — native plugins expect "ogDescription"');
      expect(json.containsKey('imageUrl'), isFalse,
          reason: 'Must use "ogImage", not "imageUrl" — native plugins expect "ogImage"');
    });

    test('toJson omits null fields', () {
      final tags = SocialMediaTags(ogTitle: 'Only Title');
      final json = tags.toJson();

      expect(json, {'ogTitle': 'Only Title'});
      expect(json.containsKey('ogDescription'), isFalse);
      expect(json.containsKey('ogImage'), isFalse);
    });

    test('toJson returns empty map when all fields are null', () {
      final tags = SocialMediaTags();
      final json = tags.toJson();

      expect(json, isEmpty);
    });

    test('fromJson round-trips correctly', () {
      final original = SocialMediaTags(
        ogTitle: 'Round Trip Title',
        ogDescription: 'Round Trip Description',
        ogImage: 'https://example.com/roundtrip.png',
      );

      final restored = SocialMediaTags.fromJson(original.toJson());

      expect(restored.ogTitle, original.ogTitle);
      expect(restored.ogDescription, original.ogDescription);
      expect(restored.ogImage, original.ogImage);
    });
  });

  group('ULinkParameters social media tags serialization', () {
    test('toJson nests social media tags under "socialMediaTags" key', () {
      final params = ULinkParameters.dynamic(
        domain: 'example.com',
        slug: 'test-slug',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Preview Title',
          ogDescription: 'Preview Description',
          ogImage: 'https://example.com/preview.png',
        ),
      );

      final json = params.toJson();

      expect(json.containsKey('socialMediaTags'), isTrue);
      final socialTags = json['socialMediaTags'] as Map<String, dynamic>;
      expect(socialTags['ogTitle'], 'Preview Title');
      expect(socialTags['ogDescription'], 'Preview Description');
      expect(socialTags['ogImage'], 'https://example.com/preview.png');
    });

    test('toJson omits socialMediaTags when null', () {
      final params = ULinkParameters.dynamic(
        domain: 'example.com',
        slug: 'no-tags',
      );

      final json = params.toJson();

      expect(json.containsKey('socialMediaTags'), isFalse);
    });

    test('dynamic link serializes social media tags correctly', () {
      final params = ULinkParameters.dynamic(
        domain: 'links.shared.ly',
        slug: 'promo',
        fallbackUrl: 'https://example.com',
        iosFallbackUrl: 'https://apps.apple.com/app/123',
        androidFallbackUrl: 'https://play.google.com/store/apps/details?id=com.app',
        parameters: {'screen': 'product', 'productId': '42'},
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Spring Sale',
          ogDescription: 'Don\'t miss out!',
          ogImage: 'https://example.com/sale.jpg',
        ),
      );

      final json = params.toJson();

      // Verify social tags are under "socialMediaTags", not mixed into "parameters"
      expect(json['socialMediaTags'], isA<Map>());
      expect(json['parameters'], isA<Map>());

      final tags = json['socialMediaTags'] as Map;
      expect(tags['ogTitle'], 'Spring Sale');
      expect(tags.containsKey('title'), isFalse);

      final parameters = json['parameters'] as Map;
      expect(parameters.containsKey('ogTitle'), isFalse,
          reason: 'OG tags should not leak into parameters');
    });

    test('unified link serializes social media tags correctly', () {
      final params = ULinkParameters.unified(
        domain: 'links.shared.ly',
        slug: 'share',
        iosUrl: 'https://apps.apple.com/app/123',
        androidUrl: 'https://play.google.com/store/apps/details?id=com.app',
        fallbackUrl: 'https://example.com',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Check this out',
          ogDescription: 'Shared via app',
          ogImage: 'https://example.com/share.jpg',
        ),
      );

      final json = params.toJson();

      expect(json['type'], 'unified');
      expect(json['socialMediaTags'], {
        'ogTitle': 'Check this out',
        'ogDescription': 'Shared via app',
        'ogImage': 'https://example.com/share.jpg',
      });
    });
  });

  group('Method channel social media tags contract', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late MethodChannelFlutterUlinkSdk platform;
    const channel = MethodChannel('flutter_ulink_sdk');
    Map<String, dynamic>? capturedArguments;

    setUp(() {
      platform = MethodChannelFlutterUlinkSdk();
      capturedArguments = null;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'createLink') {
          capturedArguments =
              Map<String, dynamic>.from(methodCall.arguments as Map);
          return {'success': true, 'url': 'https://test.ulink.ly/abc123'};
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('createLink passes social media tags with correct keys to native', () async {
      final params = ULinkParameters.dynamic(
        domain: 'example.com',
        slug: 'test',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Native Bridge Title',
          ogDescription: 'Native Bridge Description',
          ogImage: 'https://example.com/native.png',
        ),
      );

      await platform.createLink(params);

      expect(capturedArguments, isNotNull);
      final parametersMap =
          Map<String, dynamic>.from(capturedArguments!['parameters'] as Map);
      final socialTags =
          Map<String, dynamic>.from(parametersMap['socialMediaTags'] as Map);

      // These are the exact keys the native plugins read:
      // iOS: FlutterUlinkSdkPlugin.swift line 985-987
      // Android: FlutterUlinkSdkPlugin.kt line 522-532
      expect(socialTags['ogTitle'], 'Native Bridge Title');
      expect(socialTags['ogDescription'], 'Native Bridge Description');
      expect(socialTags['ogImage'], 'https://example.com/native.png');

      // Must NOT contain wrong keys
      expect(socialTags.containsKey('title'), isFalse);
      expect(socialTags.containsKey('description'), isFalse);
      expect(socialTags.containsKey('imageUrl'), isFalse);
    });

    test('createLink without social media tags omits the key entirely', () async {
      final params = ULinkParameters.dynamic(
        domain: 'example.com',
        slug: 'no-social',
      );

      await platform.createLink(params);

      expect(capturedArguments, isNotNull);
      final parametersMap =
          Map<String, dynamic>.from(capturedArguments!['parameters'] as Map);
      expect(parametersMap.containsKey('socialMediaTags'), isFalse);
    });

    test('createLink with partial social media tags sends only provided keys', () async {
      final params = ULinkParameters.dynamic(
        domain: 'example.com',
        slug: 'partial',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Only Title Set',
        ),
      );

      await platform.createLink(params);

      expect(capturedArguments, isNotNull);
      final parametersMap =
          Map<String, dynamic>.from(capturedArguments!['parameters'] as Map);
      final socialTags =
          Map<String, dynamic>.from(parametersMap['socialMediaTags'] as Map);

      expect(socialTags, {'ogTitle': 'Only Title Set'});
      expect(socialTags.containsKey('ogDescription'), isFalse);
      expect(socialTags.containsKey('ogImage'), isFalse);
    });
  });
}

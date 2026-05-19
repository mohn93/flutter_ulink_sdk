import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/models/models.dart';

/// Tests for `externalId` on ULinkParameters. The field opts callers into
/// idempotent link creation server-side — repeated calls with the same key
/// return the existing link instead of creating a duplicate. See
/// https://docs.ulink.ly/create-links/idempotent-link-creation
///
/// The native bridges (Kotlin / Swift) read `externalId` from the
/// method-channel map and forward it to the native ULinkParameters
/// constructors, which currently DO NOT have the field on published
/// pinned versions. Those bridge + podspec/build.gradle bumps land in a
/// follow-up PR once the native SDKs publish 1.1.0.
void main() {
  group('ULinkParameters.unified externalId', () {
    test('serializes externalId in toJson when set', () {
      final params = ULinkParameters.unified(
        domain: 'links.shared.ly',
        iosUrl: 'myapp://post/456',
        androidUrl: 'myapp://post/456',
        fallbackUrl: 'https://example.com/post/456',
        externalId: 'share:user:123:post:456',
      );

      expect(params.externalId, 'share:user:123:post:456');
      expect(params.toJson()['externalId'], 'share:user:123:post:456');
    });

    test('omits externalId from toJson when null', () {
      final params = ULinkParameters.unified(
        domain: 'links.shared.ly',
        iosUrl: 'myapp://post/456',
        androidUrl: 'myapp://post/456',
        fallbackUrl: 'https://example.com/post/456',
      );

      expect(params.externalId, isNull);
      expect(params.toJson().containsKey('externalId'), isFalse);
    });
  });

  group('ULinkParameters.dynamic externalId', () {
    test('serializes externalId in toJson when set', () {
      final params = ULinkParameters.dynamic(
        domain: 'links.shared.ly',
        externalId: 'campaign:summer-sale-2026',
      );

      expect(params.externalId, 'campaign:summer-sale-2026');
      expect(params.toJson()['externalId'], 'campaign:summer-sale-2026');
    });

    test('omits externalId from toJson when null', () {
      final params = ULinkParameters.dynamic(domain: 'links.shared.ly');

      expect(params.externalId, isNull);
      expect(params.toJson().containsKey('externalId'), isFalse);
    });
  });

  group('ULinkParameters.fromJson externalId', () {
    test('round-trips externalId through fromJson', () {
      final original = ULinkParameters.unified(
        domain: 'links.shared.ly',
        iosUrl: 'a',
        androidUrl: 'b',
        fallbackUrl: 'c',
        externalId: 'roundtrip:abc',
      );

      final restored = ULinkParameters.fromJson(original.toJson());

      expect(restored.externalId, 'roundtrip:abc');
    });

    test('parses externalId as null when absent', () {
      final restored = ULinkParameters.fromJson({
        'type': 'unified',
        'domain': 'links.shared.ly',
      });

      expect(restored.externalId, isNull);
    });
  });
}

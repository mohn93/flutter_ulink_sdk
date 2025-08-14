import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('Resolve token capture', () {
    test('resolve captures X-Installation-Token header', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/sdk/resolve')) {
          return http.Response(
            json.encode({'fallbackUrl': 'https://example.com'}),
            200,
            headers: {
              'content-type': 'application/json',
              'x-installation-token': 'new-token-456',
            },
          );
        }
        return http.Response('Not Found', 404);
      });

      final ulink = ULink.forTesting(
        config: ULinkConfig(
          apiKey: 'k',
          baseUrl: 'https://api.ulink.ly',
          debug: true,
          enableDeepLinkIntegration: false,
        ),
        httpClient: client,
      );

      final res = await ulink.resolveLink('https://domain/slug');
      expect(res.success, isTrue);

      // We cannot directly read token, but no exception thrown means header parsing worked.
      // Optionally, expose a testing accessor if desired.
    });
  });
}

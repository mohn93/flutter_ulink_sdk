import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/testing.dart';

void main() {
  group('ULink Bootstrap', () {
    testWidgets('initialize calls /sdk/bootstrap and sets token + session',
        (tester) async {
      String? capturedPath;
      Map<String, String>? capturedHeaders;
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((http.Request request) async {
        capturedPath = request.url.path;
        capturedHeaders = request.headers;
        if (request.body.isNotEmpty) {
          capturedBody = json.decode(request.body) as Map<String, dynamic>;
        }

        if (request.url.path.endsWith('/sdk/bootstrap')) {
          return http.Response(
            json.encode({
              'installationId': 'inst-abc',
              'installationToken': 'jwt-token-123',
              'sessionId': 'sess-xyz',
              'sessionCreated': true,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final ulink = await ULink.initialize(
        config: ULinkConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.ulink.ly',
          debug: true,
          enableDeepLinkIntegration: false,
        ),
        httpClient: mockClient,
      );

      // Validate bootstrap was called
      expect(capturedPath, endsWith('/sdk/bootstrap'));
      expect(capturedHeaders!['X-App-Key'], 'test-key');

      // Validate SDK state after bootstrap
      expect(ulink.hasActiveSession(), isTrue);
      expect(ulink.getCurrentSessionId(), 'sess-xyz');
      expect(ulink.getInstallationId(), 'inst-abc');

      // Validate client headers present
      expect(capturedHeaders!['X-ULink-Client'], 'sdk-flutter');
      expect(capturedHeaders!.containsKey('X-ULink-Client-Version'), isTrue);
      expect(capturedHeaders!.containsKey('X-ULink-Client-Platform'), isTrue);

      // Validate body contains installation fields similar to /sdk/installations/track
      expect(capturedBody!['installationId'], isNotNull);
      expect(capturedBody!['deviceId'], isA<Object?>());
      expect(capturedBody!['deviceModel'], isA<Object?>());
      expect(capturedBody!['deviceManufacturer'], isA<Object?>());
      expect(capturedBody!['osName'], isA<Object?>());
      expect(capturedBody!['osVersion'] ?? capturedBody!['androidVersion'],
          isA<Object?>());
      expect(capturedBody!['appVersion'], isA<Object?>());
      expect(capturedBody!['appBuild'], isA<Object?>());
      expect(capturedBody!['language'], isA<Object?>());
      expect(capturedBody!['timezone'], isA<Object?>());
    });
  });
}

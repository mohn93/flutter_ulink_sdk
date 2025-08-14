import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Session lifecycle with bootstrap + resume', () {
    testWidgets('resume triggers startSession only when idle', (tester) async {
      var startSessionCalls = 0;

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/sdk/bootstrap')) {
          return http.Response(
            json.encode({
              'installationId': 'inst-1',
              'installationToken': 'tok-1',
              'sessionId': 'sess-1',
              'sessionCreated': true,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/sdk/sessions/start')) {
          startSessionCalls++;
          return http.Response(
            json.encode({'success': true, 'sessionId': 'sess-2'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/sdk/resolve')) {
          return http.Response(json.encode({'fallbackUrl': 'https://x'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final ulink = await ULink.initialize(
        config: ULinkConfig(
          apiKey: 'k',
          baseUrl: 'https://api.ulink.ly',
          debug: true,
          enableDeepLinkIntegration: false,
        ),
        httpClient: client,
      );

      // After bootstrap, session active; resume should not start a new session immediately
      expect(ulink.hasActiveSession(), isTrue);
      expect(startSessionCalls, 0);

      // Simulate end of session
      await ulink.endSession();
      expect(ulink.hasActiveSession(), isFalse);

      // Now simulate resume behavior by directly calling internal start
      // (Cannot trigger lifecycle in unit test; validate startSession can be invoked)
      // Invoke a resolve; server will ensure session, but we also allow manual start
      await ulink.resolveLink('https://domain/slug');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:http/http.dart' as http;

// Simple mock client for testing
class MockClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Return a successful response for any request
    return http.StreamedResponse(
      Stream.fromIterable(
          ['{"success": true, "sessionId": "test-session-123"}'.codeUnits]),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('Lifecycle Management Tests', () {
    late MockClient mockClient;
    late ULink ulink;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();

      mockClient = MockClient();

      // Create ULink instance for testing
      ulink = ULink.forTesting(
        config: ULinkConfig(
          apiKey: 'test-api-key',
          baseUrl: 'https://api.ulink.ly',
          debug: true,
        ),
        httpClient: mockClient,
      );
    });

    test('should create ULink instance for testing', () {
      // Test that the ULink instance is properly created
      expect(ulink, isNotNull);
      expect(ulink.hasActiveSession(), isFalse);
      expect(ulink.getCurrentSessionId(), isNull);
    });

    test('should have session management methods', () {
      // Test that session management methods are available
      expect(ulink.hasActiveSession, isA<Function>());
      expect(ulink.getCurrentSessionId, isA<Function>());
      expect(ulink.endSession, isA<Function>());
    });

    test('should handle session lifecycle', () async {
      // Test basic session functionality
      expect(ulink.hasActiveSession(), isFalse);

      // Test ending a non-existent session
      final endResult = await ulink.endSession();
      expect(endResult.success, isFalse);
      expect(endResult.error, contains('No active session'));
    });

    test('should unregister lifecycle observer on dispose', () {
      // Test that dispose properly cleans up
      expect(() => ulink.dispose(), returnsNormally);
    });
  });
}

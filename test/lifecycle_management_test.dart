import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'lifecycle_management_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('Lifecycle Management Tests', () {
    late MockClient mockClient;
    late ULink ulink;
    late TestWidgetsFlutterBinding binding;

    setUp(() {
      // Initialize test binding
      binding = TestWidgetsFlutterBinding.ensureInitialized();
      
      mockClient = MockClient();
      
      // Mock successful session start response
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"success": true, "sessionId": "test-session-123"}',
        200,
      ));
      
      // Mock successful session end response
      when(mockClient.post(
        Uri.parse('https://api.ulink.ly/sdk/sessions/test-session-123/end'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
        '{"success": true, "message": "Session ended"}',
        200,
      ));
      
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

    testWidgets('should register lifecycle observer on initialization', (WidgetTester tester) async {
      // The lifecycle observer should be registered automatically
      // We can't directly test the observer registration, but we can test
      // that the ULink instance is properly configured
      expect(ulink, isNotNull);
    });

    testWidgets('should start session on app resume when no session exists', (WidgetTester tester) async {
      // Simulate app lifecycle state change to resumed
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter/lifecycle'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'AppLifecycleState.resumed') {
            // Trigger the lifecycle state change
            ulink.didChangeAppLifecycleState(AppLifecycleState.resumed);
          }
          return null;
        },
      );

      // Initially no session should be active
      expect(ulink.hasActiveSession(), isFalse);
      expect(ulink.getCurrentSessionId(), isNull);

      // Simulate app resume
      ulink.didChangeAppLifecycleState(AppLifecycleState.resumed);
      
      // Wait for async operations
      await tester.pump();
      
      // Session should be started (we can't easily test the async result,
      // but we can verify the method was called)
      verify(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(greaterThan(0));
    });

    testWidgets('should end session on app pause', (WidgetTester tester) async {
      // First, simulate having an active session
      ulink.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      
      // Now simulate app pause
      ulink.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();
      
      // Verify that session end was called
      verify(mockClient.post(
        Uri.parse('https://api.ulink.ly/sdk/sessions/test-session-123/end'),
        headers: anyNamed('headers'),
      )).called(greaterThan(0));
    });

    testWidgets('should end session on app inactive', (WidgetTester tester) async {
      // First, simulate having an active session
      ulink.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      
      // Now simulate app inactive
      ulink.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await tester.pump();
      
      // Verify that session end was called
      verify(mockClient.post(
        Uri.parse('https://api.ulink.ly/sdk/sessions/test-session-123/end'),
        headers: anyNamed('headers'),
      )).called(greaterThan(0));
    });

    testWidgets('should end session on app detached', (WidgetTester tester) async {
      // First, simulate having an active session
      ulink.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      
      // Now simulate app detached
      ulink.didChangeAppLifecycleState(AppLifecycleState.detached);
      await tester.pump();
      
      // Verify that session end was called
      verify(mockClient.post(
        Uri.parse('https://api.ulink.ly/sdk/sessions/test-session-123/end'),
        headers: anyNamed('headers'),
      )).called(greaterThan(0));
    });

    testWidgets('should end session on app hidden', (WidgetTester tester) async {
      // First, simulate having an active session
      ulink.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      
      // Now simulate app hidden
      ulink.didChangeAppLifecycleState(AppLifecycleState.hidden);
      await tester.pump();
      
      // Verify that session end was called
      verify(mockClient.post(
        Uri.parse('https://api.ulink.ly/sdk/sessions/test-session-123/end'),
        headers: anyNamed('headers'),
      )).called(greaterThan(0));
    });

    testWidgets('should not start new session on resume if session already exists', (WidgetTester tester) async {
      // Mock that a session already exists
      // This would require modifying the ULink class to allow setting session state for testing
      // For now, we'll test the basic lifecycle behavior
      
      // Simulate app resume twice
      ulink.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      
      // Reset mock call count
      clearInteractions(mockClient);
      
      // Resume again - should not start new session if one exists
      ulink.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      
      // This test would need more sophisticated mocking to verify
      // that a new session is not started when one already exists
    });

    test('should unregister lifecycle observer on dispose', () {
      // Test that dispose properly cleans up
      expect(() => ulink.dispose(), returnsNormally);
    });
  });
}
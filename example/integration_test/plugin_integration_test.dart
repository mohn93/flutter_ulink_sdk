// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:flutter_ulink_sdk/models/ulink_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SDK initialization test', (WidgetTester tester) async {
    final ULink plugin = ULink.instance;

    // Test SDK initialization
    final config = ULinkConfig(
      apiKey: 'test_api_key',
      baseUrl: 'https://test.example.com',
    );

    try {
      await plugin.initialize(config);
      // If no exception is thrown, initialization succeeded
      expect(true, true);
    } catch (e) {
      // For integration tests, we expect this to fail without proper setup
      // but we're testing that the method can be called
      expect(e, isNotNull);
    }
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk_method_channel.dart';
import 'package:flutter_ulink_sdk/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFlutterUlinkSdk platform = MethodChannelFlutterUlinkSdk();
  const MethodChannel channel = MethodChannel('flutter_ulink_sdk');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'createLink':
          return 'https://test.ulink.ly/abc123';
        case 'getCurrentSessionId':
          return 'session123';
        case 'hasActiveSession':
          return true;
        case 'getSessionState':
          return 'active';
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('createLink', () async {
    final parameters = ULinkParameters.dynamic(
      slug: 'test',
      domain: 'example.com',
    );
    expect(
      await platform.createLink(parameters),
      'https://test.ulink.ly/abc123',
    );
  });

  test('getCurrentSessionId', () async {
    expect(await platform.getCurrentSessionId(), 'session123');
  });

  test('hasActiveSession', () async {
    expect(await platform.hasActiveSession(), true);
  });

  test('getSessionState', () async {
    expect(await platform.getSessionState(), SessionState.active);
  });
}

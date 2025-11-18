import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk_platform_interface.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk_method_channel.dart';
import 'package:flutter_ulink_sdk/models/models.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterUlinkSdkPlatform
    with MockPlatformInterfaceMixin
    implements FlutterUlinkSdkPlatform {
  @override
  Future<void> initialize(ULinkConfig config) => Future.value();

  @override
  Future<ULinkResponse> createLink(ULinkParameters parameters) =>
      Future.value(ULinkResponse.success('https://test.ulink.ly/abc123'));

  @override
  Future<ULinkResponse> resolveLink(String url) =>
      Future.value(ULinkResponse.error('Not found'));

  @override
  Future<void> endSession() => Future.value();

  @override
  Future<String?> getCurrentSessionId() => Future.value('session123');

  @override
  Future<bool> hasActiveSession() => Future.value(true);

  @override
  Future<SessionState> getSessionState() => Future.value(SessionState.active);

  @override
  Future<ULinkResolvedData?> handleDeepLink(String url) => Future.value(null);

  @override
  Future<void> setInitialUri(String uri) => Future.value();

  @override
  Future<String?> getInitialUri() => Future.value(null);

  @override
  Future<ULinkResolvedData?> getInitialDeepLink() => Future.value(null);

  @override
  Future<ULinkResolvedData?> getLastLinkData() => Future.value(null);

  @override
  Future<String?> getInstallationId() => Future.value('install123');

  @override
  Future<void> dispose() => Future.value();

  @override
  Stream<ULinkResolvedData> get onDynamicLink => Stream.empty();

  @override
  Stream<ULinkResolvedData> get onUnifiedLink => Stream.empty();

  @override
  Stream<ULinkResolvedData> get dynamicLinkStream => Stream.empty();

  @override
  Stream<ULinkResolvedData> get unifiedLinkStream => Stream.empty();
}

void main() {
  final FlutterUlinkSdkPlatform initialPlatform =
      FlutterUlinkSdkPlatform.instance;

  test('$MethodChannelFlutterUlinkSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterUlinkSdk>());
  });

  test('createLink returns ULinkResponse', () async {
    ULink flutterUlinkBridgeSdkPlugin =
        ULink.instance;
    MockFlutterUlinkSdkPlatform fakePlatform =
        MockFlutterUlinkSdkPlatform();
    FlutterUlinkSdkPlatform.instance = fakePlatform;

    final parameters = ULinkParameters.dynamic(
      slug: 'test',
      domain: 'example.com',
    );
    final response = await flutterUlinkBridgeSdkPlugin.createLink(parameters);
    expect(response.success, true);
    expect(response.url, 'https://test.ulink.ly/abc123');
  });
}

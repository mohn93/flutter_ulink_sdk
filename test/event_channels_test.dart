import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk_method_channel.dart';
import 'package:flutter_ulink_sdk/models/models.dart';

/// Tests for EventChannel stream handling in the method channel implementation.
///
/// These tests verify the Dart-side bridge contract for all 4 event channels:
/// - flutter_ulink_sdk/logs
/// - flutter_ulink_sdk/dynamic_links
/// - flutter_ulink_sdk/unified_links
/// - flutter_ulink_sdk/reinstall_detected
///
/// The corresponding native fixes ensure events are dispatched on the platform
/// thread (main thread) before reaching the Dart side. These tests verify the
/// Dart layer correctly parses and forwards those events.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelFlutterUlinkSdk platform;
  const methodChannel = MethodChannel('flutter_ulink_sdk');

  // Event channel names matching native side
  const logChannelName = 'flutter_ulink_sdk/logs';
  const dynamicLinkChannelName = 'flutter_ulink_sdk/dynamic_links';
  const unifiedLinkChannelName = 'flutter_ulink_sdk/unified_links';
  const reinstallChannelName = 'flutter_ulink_sdk/reinstall_detected';

  setUp(() {
    platform = MethodChannelFlutterUlinkSdk();

    // Mock the method channel to handle 'initialize' call
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'initialize':
          return true;
        case 'dispose':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);

    // Clean up event channel mocks
    for (final name in [
      logChannelName,
      dynamicLinkChannelName,
      unifiedLinkChannelName,
      reinstallChannelName,
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        EventChannel(name),
        null,
      );
    }
  });

  group('Event channel names match native contract', () {
    test('log event channel uses correct name', () {
      expect(platform.logEventChannel.name, logChannelName);
    });

    test('dynamic link event channel uses correct name', () {
      expect(platform.dynamicLinkEventChannel.name, dynamicLinkChannelName);
    });

    test('unified link event channel uses correct name', () {
      expect(platform.unifiedLinkEventChannel.name, unifiedLinkChannelName);
    });

    test('reinstall event channel uses correct name', () {
      expect(platform.reinstallEventChannel.name, reinstallChannelName);
    });
  });

  group('Log event channel (flutter_ulink_sdk/logs)', () {
    test('parses log events from native and forwards to onLog stream',
        () async {
      final logEvents = <ULinkLogEntry>[];

      // Set up mock stream handler to emit log events
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        platform.logEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success({
              'level': 'debug',
              'tag': 'ULink',
              'message': 'SDK initialized',
              'timestamp': 1700000000000,
            });
            events.success({
              'level': 'error',
              'tag': 'Network',
              'message': 'Connection failed',
              'timestamp': 1700000001000,
            });
          },
        ),
      );

      // Initialize to start listening
      await platform.initialize(ULinkConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test.com',
      ));

      // Collect log events
      final subscription = platform.onLog.listen(logEvents.add);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(logEvents, hasLength(2));
      expect(logEvents[0].level, 'debug');
      expect(logEvents[0].tag, 'ULink');
      expect(logEvents[0].message, 'SDK initialized');
      expect(logEvents[0].timestamp, 1700000000000);
      expect(logEvents[1].level, 'error');
      expect(logEvents[1].tag, 'Network');
      expect(logEvents[1].message, 'Connection failed');

      await subscription.cancel();
    });

    test('handles null log events gracefully', () async {
      final logEvents = <ULinkLogEntry>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        platform.logEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success(null); // null event should be skipped
            events.success({
              'level': 'info',
              'tag': 'ULink',
              'message': 'Valid event',
              'timestamp': 1700000000000,
            });
          },
        ),
      );

      await platform.initialize(ULinkConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test.com',
      ));

      final subscription = platform.onLog.listen(logEvents.add);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(logEvents, hasLength(1));
      expect(logEvents[0].message, 'Valid event');

      await subscription.cancel();
    });

    test('uses defaults for missing log entry fields', () async {
      final logEvents = <ULinkLogEntry>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        platform.logEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            // Minimal map with no fields - should use defaults
            events.success(<String, dynamic>{});
          },
        ),
      );

      await platform.initialize(ULinkConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test.com',
      ));

      final subscription = platform.onLog.listen(logEvents.add);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(logEvents, hasLength(1));
      expect(logEvents[0].level, 'debug'); // default
      expect(logEvents[0].tag, 'ULink'); // default
      expect(logEvents[0].message, ''); // default

      await subscription.cancel();
    });
  });

  group('Dynamic link event channel (flutter_ulink_sdk/dynamic_links)', () {
    test('parses dynamic link events and forwards to onDynamicLink stream',
        () async {
      final linkEvents = <ULinkResolvedData>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        platform.dynamicLinkEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success({
              'slug': 'test-link',
              'fallbackUrl': 'https://example.com',
              'parameters': {'screen': 'home'},
              'type': 'dynamic',
            });
          },
        ),
      );

      await platform.initialize(ULinkConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test.com',
      ));

      final subscription = platform.onDynamicLink.listen(linkEvents.add);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(linkEvents, hasLength(1));
      expect(linkEvents[0].slug, 'test-link');
      expect(linkEvents[0].fallbackUrl, 'https://example.com');

      await subscription.cancel();
    });

    test('handles null dynamic link events gracefully', () async {
      final linkEvents = <ULinkResolvedData>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        platform.dynamicLinkEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success(null);
          },
        ),
      );

      await platform.initialize(ULinkConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test.com',
      ));

      final subscription = platform.onDynamicLink.listen(linkEvents.add);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(linkEvents, isEmpty);

      await subscription.cancel();
    });
  });

  group('Unified link event channel (flutter_ulink_sdk/unified_links)', () {
    test('parses unified link events and forwards to onUnifiedLink stream',
        () async {
      final linkEvents = <ULinkResolvedData>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        platform.unifiedLinkEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success({
              'slug': 'unified-link',
              'iosUrl': 'https://apps.apple.com/app/123',
              'androidUrl': 'https://play.google.com/store/apps/details?id=com.test',
              'fallbackUrl': 'https://example.com/unified',
              'type': 'unified',
            });
          },
        ),
      );

      await platform.initialize(ULinkConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test.com',
      ));

      final subscription = platform.onUnifiedLink.listen(linkEvents.add);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(linkEvents, hasLength(1));
      expect(linkEvents[0].slug, 'unified-link');
      expect(linkEvents[0].fallbackUrl, 'https://example.com/unified');

      await subscription.cancel();
    });
  });

  group('Reinstall detection event channel (flutter_ulink_sdk/reinstall_detected)', () {
    test('parses reinstall events and forwards to onReinstallDetected stream',
        () async {
      final reinstallEvents = <ULinkInstallationInfo>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        platform.reinstallEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success({
              'installationId': 'new-install-123',
              'isReinstall': true,
              'previousInstallationId': 'old-install-456',
              'reinstallDetectedAt': '2024-01-15T10:30:00Z',
              'persistentDeviceId': 'device-789',
            });
          },
        ),
      );

      await platform.initialize(ULinkConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test.com',
      ));

      final subscription =
          platform.onReinstallDetected.listen(reinstallEvents.add);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(reinstallEvents, hasLength(1));
      expect(reinstallEvents[0].installationId, 'new-install-123');
      expect(reinstallEvents[0].isReinstall, isTrue);
      expect(reinstallEvents[0].previousInstallationId, 'old-install-456');
      expect(reinstallEvents[0].reinstallDetectedAt, '2024-01-15T10:30:00Z');
      expect(reinstallEvents[0].persistentDeviceId, 'device-789');

      await subscription.cancel();
    });

    test('handles fresh install event (isReinstall false)', () async {
      final reinstallEvents = <ULinkInstallationInfo>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        platform.reinstallEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success({
              'installationId': 'fresh-install-123',
              'isReinstall': false,
            });
          },
        ),
      );

      await platform.initialize(ULinkConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test.com',
      ));

      final subscription =
          platform.onReinstallDetected.listen(reinstallEvents.add);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(reinstallEvents, hasLength(1));
      expect(reinstallEvents[0].installationId, 'fresh-install-123');
      expect(reinstallEvents[0].isReinstall, isFalse);
      expect(reinstallEvents[0].previousInstallationId, isNull);

      await subscription.cancel();
    });
  });

  group('Dispose cleans up all event channel subscriptions', () {
    test('dispose cancels all stream subscriptions and closes controllers',
        () async {
      // Set up mock streams for all channels
      for (final channel in [
        platform.logEventChannel,
        platform.dynamicLinkEventChannel,
        platform.unifiedLinkEventChannel,
        platform.reinstallEventChannel,
      ]) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          channel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              // Just open the stream, don't send anything
            },
          ),
        );
      }

      await platform.initialize(ULinkConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test.com',
      ));

      // Verify streams are active before dispose
      final logCompleter = Completer<void>();
      final dynamicLinkCompleter = Completer<void>();
      final unifiedLinkCompleter = Completer<void>();
      final reinstallCompleter = Completer<void>();

      final sub1 = platform.onLog.listen(
        (_) {},
        onDone: () => logCompleter.complete(),
      );
      final sub2 = platform.onDynamicLink.listen(
        (_) {},
        onDone: () => dynamicLinkCompleter.complete(),
      );
      final sub3 = platform.onUnifiedLink.listen(
        (_) {},
        onDone: () => unifiedLinkCompleter.complete(),
      );
      final sub4 = platform.onReinstallDetected.listen(
        (_) {},
        onDone: () => reinstallCompleter.complete(),
      );

      // Dispose should close all controllers
      await platform.dispose();

      // All stream controllers should have sent done events
      await logCompleter.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () => fail('onLog stream not closed after dispose'),
      );
      await dynamicLinkCompleter.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () => fail('onDynamicLink stream not closed after dispose'),
      );
      await unifiedLinkCompleter.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () => fail('onUnifiedLink stream not closed after dispose'),
      );
      await reinstallCompleter.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () =>
            fail('onReinstallDetected stream not closed after dispose'),
      );

      await sub1.cancel();
      await sub2.cancel();
      await sub3.cancel();
      await sub4.cancel();
    });
  });

  group('Multiple events on same channel', () {
    test('log channel receives multiple sequential events', () async {
      final logEvents = <ULinkLogEntry>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        platform.logEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success({
              'level': 'debug',
              'tag': 'Init',
              'message': 'Starting initialization',
              'timestamp': 1700000000000,
            });
            events.success({
              'level': 'info',
              'tag': 'Init',
              'message': 'Bootstrap complete',
              'timestamp': 1700000001000,
            });
            events.success({
              'level': 'warning',
              'tag': 'Network',
              'message': 'Slow connection detected',
              'timestamp': 1700000002000,
            });
            events.success({
              'level': 'error',
              'tag': 'Session',
              'message': 'Session creation failed',
              'timestamp': 1700000003000,
            });
          },
        ),
      );

      await platform.initialize(ULinkConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test.com',
      ));

      final subscription = platform.onLog.listen(logEvents.add);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(logEvents, hasLength(4));
      expect(logEvents.map((e) => e.level).toList(),
          ['debug', 'info', 'warning', 'error']);
      expect(logEvents.map((e) => e.tag).toList(),
          ['Init', 'Init', 'Network', 'Session']);

      await subscription.cancel();
    });
  });

  group('ULinkLogEntry model', () {
    test('fromMap parses all fields correctly', () {
      final entry = ULinkLogEntry.fromMap({
        'level': 'warning',
        'tag': 'CustomTag',
        'message': 'Test warning message',
        'timestamp': 1700000000000,
      });

      expect(entry.level, 'warning');
      expect(entry.tag, 'CustomTag');
      expect(entry.message, 'Test warning message');
      expect(entry.timestamp, 1700000000000);
    });

    test('fromMap uses defaults for missing fields', () {
      final entry = ULinkLogEntry.fromMap({});

      expect(entry.level, 'debug');
      expect(entry.tag, 'ULink');
      expect(entry.message, '');
    });

    test('toMap round-trips correctly', () {
      final original = ULinkLogEntry(
        level: 'error',
        tag: 'Test',
        message: 'Round trip',
        timestamp: 1700000000000,
      );

      final restored = ULinkLogEntry.fromMap(original.toMap());

      expect(restored.level, original.level);
      expect(restored.tag, original.tag);
      expect(restored.message, original.message);
      expect(restored.timestamp, original.timestamp);
    });

    test('formattedTime returns correct format', () {
      // 2023-11-14 22:13:20.000 UTC
      final entry = ULinkLogEntry(
        level: 'info',
        tag: 'Test',
        message: 'Time test',
        timestamp: 1700000000000,
      );

      expect(entry.formattedTime, matches(RegExp(r'^\d{2}:\d{2}:\d{2}\.\d{3}$')));
    });

    test('level constants are correct', () {
      expect(ULinkLogEntry.levelDebug, 'debug');
      expect(ULinkLogEntry.levelInfo, 'info');
      expect(ULinkLogEntry.levelWarning, 'warning');
      expect(ULinkLogEntry.levelError, 'error');
    });
  });

  group('ULinkInstallationInfo model', () {
    test('fromJson parses reinstall event correctly', () {
      final info = ULinkInstallationInfo.fromJson({
        'installationId': 'abc-123',
        'isReinstall': true,
        'previousInstallationId': 'old-456',
        'reinstallDetectedAt': '2024-01-15T10:30:00Z',
        'persistentDeviceId': 'device-789',
      });

      expect(info.installationId, 'abc-123');
      expect(info.isReinstall, isTrue);
      expect(info.previousInstallationId, 'old-456');
      expect(info.reinstallDetectedAt, '2024-01-15T10:30:00Z');
      expect(info.persistentDeviceId, 'device-789');
    });

    test('fromJson uses defaults for missing optional fields', () {
      final info = ULinkInstallationInfo.fromJson({
        'installationId': 'abc-123',
      });

      expect(info.installationId, 'abc-123');
      expect(info.isReinstall, isFalse);
      expect(info.previousInstallationId, isNull);
      expect(info.reinstallDetectedAt, isNull);
      expect(info.persistentDeviceId, isNull);
    });

    test('toJson round-trips correctly', () {
      final original = ULinkInstallationInfo(
        installationId: 'test-123',
        isReinstall: true,
        previousInstallationId: 'prev-456',
        reinstallDetectedAt: '2024-01-15T10:30:00Z',
        persistentDeviceId: 'device-789',
      );

      final restored = ULinkInstallationInfo.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('toJson omits null optional fields', () {
      final info = ULinkInstallationInfo(
        installationId: 'test-123',
        isReinstall: false,
      );

      final json = info.toJson();

      expect(json.containsKey('installationId'), isTrue);
      expect(json.containsKey('isReinstall'), isTrue);
      expect(json.containsKey('previousInstallationId'), isFalse);
      expect(json.containsKey('reinstallDetectedAt'), isFalse);
      expect(json.containsKey('persistentDeviceId'), isFalse);
    });

    test('equality works correctly', () {
      final info1 = ULinkInstallationInfo(
        installationId: 'test-123',
        isReinstall: true,
        previousInstallationId: 'prev-456',
      );
      final info2 = ULinkInstallationInfo(
        installationId: 'test-123',
        isReinstall: true,
        previousInstallationId: 'prev-456',
      );
      final info3 = ULinkInstallationInfo(
        installationId: 'different',
        isReinstall: false,
      );

      expect(info1, equals(info2));
      expect(info1, isNot(equals(info3)));
    });

    test('freshInstall factory creates correct instance', () {
      final info = ULinkInstallationInfo.freshInstall(
        installationId: 'fresh-123',
        persistentDeviceId: 'device-abc',
      );

      expect(info.installationId, 'fresh-123');
      expect(info.isReinstall, isFalse);
      expect(info.previousInstallationId, isNull);
      expect(info.persistentDeviceId, 'device-abc');
    });
  });
}

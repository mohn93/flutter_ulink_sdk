import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_ulink_sdk_platform_interface.dart';
import 'models/models.dart';

/// An implementation of [FlutterUlinkSdkPlatform] that uses method channels.
class MethodChannelFlutterUlinkSdk extends FlutterUlinkSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_ulink_sdk');

  /// Event channel for dynamic link events
  @visibleForTesting
  final dynamicLinkEventChannel = const EventChannel(
    'flutter_ulink_sdk/dynamic_links',
  );

  /// Event channel for unified link events
  @visibleForTesting
  final unifiedLinkEventChannel = const EventChannel(
    'flutter_ulink_sdk/unified_links',
  );

  /// Event channel for log events
  @visibleForTesting
  final logEventChannel = const EventChannel(
    'flutter_ulink_sdk/logs',
  );

  StreamSubscription<dynamic>? _dynamicLinkSubscription;
  StreamSubscription<dynamic>? _unifiedLinkSubscription;
  StreamSubscription<dynamic>? _logSubscription;
  final StreamController<ULinkResolvedData> _dynamicLinkController =
      StreamController<ULinkResolvedData>.broadcast();
  final StreamController<ULinkResolvedData> _unifiedLinkController =
      StreamController<ULinkResolvedData>.broadcast();
  final StreamController<ULinkLogEntry> _logController =
      StreamController<ULinkLogEntry>.broadcast();

  @override
  Future<void> initialize(ULinkConfig config) async {
    await methodChannel.invokeMethod('initialize', {'config': config.toMap()});

    // Set up event channel listeners
    _dynamicLinkSubscription = dynamicLinkEventChannel
        .receiveBroadcastStream()
        .listen(
          (dynamic event) {
            if (event != null) {
              final linkData = ULinkResolvedData.fromJson(
                Map<String, dynamic>.from(event),
              );
              _dynamicLinkController.add(linkData);
            }
          },
          onError: (error) {
            debugPrint('Dynamic link event channel error: $error');
          },
        );

    _unifiedLinkSubscription = unifiedLinkEventChannel
        .receiveBroadcastStream()
        .listen(
          (dynamic event) {
            if (event != null) {
              final linkData = ULinkResolvedData.fromJson(
                Map<String, dynamic>.from(event),
              );
              _unifiedLinkController.add(linkData);
            }
          },
          onError: (error) {
            debugPrint('Unified link event channel error: $error');
          },
        );

    _logSubscription = logEventChannel
        .receiveBroadcastStream()
        .listen(
          (dynamic event) {
            if (event != null) {
              final logEntry = ULinkLogEntry.fromMap(
                Map<dynamic, dynamic>.from(event),
              );
              _logController.add(logEntry);
            }
          },
          onError: (error) {
            debugPrint('Log event channel error: $error');
          },
        );
  }

  @override
  Future<ULinkResponse> createLink(ULinkParameters parameters) async {
    try {
      final result = await methodChannel.invokeMethod('createLink', {
        'parameters': parameters.toJson(),
      });

      if (result != null && result is Map) {
        final responseMap = Map<String, dynamic>.from(result);
        return ULinkResponse.fromMap(responseMap);
      }
      return ULinkResponse.error('Failed to create link');
    } on PlatformException catch (e) {
      return ULinkResponse.error(e.message ?? 'Platform error: ${e.code}');
    } catch (e) {
      return ULinkResponse.error('Error creating link: $e');
    }
  }

  @override
  Future<ULinkResponse> resolveLink(String url) async {
    try {
      final result = await methodChannel.invokeMethod('resolveLink', {
        'url': url,
      });

      if (result != null && result is Map) {
        final responseMap = Map<String, dynamic>.from(result);
        return ULinkResponse.fromMap(responseMap);
      }
      return ULinkResponse.error('Failed to resolve link');
    } on PlatformException catch (e) {
      return ULinkResponse.error(e.message ?? 'Platform error: ${e.code}');
    } catch (e) {
      return ULinkResponse.error('Error resolving link: $e');
    }
  }

  @override
  Future<void> endSession() async {
    await methodChannel.invokeMethod('endSession');
  }

  @override
  Future<String?> getCurrentSessionId() async {
    final result = await methodChannel.invokeMethod<String>(
      'getCurrentSessionId',
    );
    return result;
  }

  @override
  Future<bool> hasActiveSession() async {
    final result = await methodChannel.invokeMethod<bool>('hasActiveSession');
    return result ?? false;
  }

  @override
  Future<SessionState> getSessionState() async {
    final result = await methodChannel.invokeMethod<String>('getSessionState');
    return SessionStateExtension.fromString(result ?? 'idle');
  }

  @override
  Future<void> setInitialUri(String uri) async {
    await methodChannel.invokeMethod('setInitialUri', {'url': uri});
  }

  @override
  Future<String?> getInitialUri() async {
    final result = await methodChannel.invokeMethod<String>('getInitialUri');
    return result;
  }

  @override
  Future<ULinkResolvedData?> getInitialDeepLink() async {
    final result = await methodChannel.invokeMethod('getInitialDeepLink');
    if (result != null && result is Map) {
      // Extract the 'data' field from the response structure
      final data = result['data'];
      if (data != null && data is Map) {
        // Convert to Map<String, dynamic>
        final dataMap = Map<String, dynamic>.from(data);
        return ULinkResolvedData.fromJson(dataMap);
      }
    }
    return null;
  }

  @override
  Future<ULinkResolvedData?> getLastLinkData() async {
    final result = await methodChannel.invokeMethod('getLastLinkData');
    if (result != null && result is Map) {
      // Extract the 'data' field from the response structure
      final data = result['data'];
      if (data != null && data is Map) {
        // Convert to Map<String, dynamic>
        final dataMap = Map<String, dynamic>.from(data);
        return ULinkResolvedData.fromJson(dataMap);
      }
    }
    return null;
  }

  @override
  Future<String?> getInstallationId() async {
    final result = await methodChannel.invokeMethod<String>(
      'getInstallationId',
    );
    return result;
  }

  @override
  Future<void> checkDeferredLink() async {
    await methodChannel.invokeMethod('checkDeferredLink');
  }

  @override
  Future<void> dispose() async {
    await _dynamicLinkSubscription?.cancel();
    await _unifiedLinkSubscription?.cancel();
    await _logSubscription?.cancel();
    await _dynamicLinkController.close();
    await _unifiedLinkController.close();
    await _logController.close();
    await methodChannel.invokeMethod('dispose');
  }

  @override
  Stream<ULinkResolvedData> get onDynamicLink => _dynamicLinkController.stream;

  @override
  Stream<ULinkResolvedData> get onUnifiedLink => _unifiedLinkController.stream;

  @override
  Stream<ULinkLogEntry> get onLog => _logController.stream;
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_udid/flutter_udid.dart';

/// Helper class for gathering device information
class DeviceInfoHelper {
  /// Get detailed device information using device_info_plus package
  ///
  /// This method gathers detailed information about the device using the
  /// device_info_plus package.
  static Future<Map<String, dynamic>> getBasicDeviceInfo() async {
    final Map<String, dynamic> deviceData = {};
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    try {
      // Platform information
      deviceData['osName'] = defaultTargetPlatform.toString().split('.').last;

      // For app version and build number, we recommend using package_info_plus
      final packageInfo = await PackageInfo.fromPlatform();
      deviceData['appVersion'] = packageInfo.version;
      deviceData['appBuild'] = packageInfo.buildNumber;

      // Get locale information
      deviceData['language'] = PlatformDispatcher.instance.locale.toString();

      // Get timezone
      deviceData['timezone'] = DateTime.now().timeZoneName;

      // Get detailed device information based on platform
      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        deviceData['deviceModel'] = webInfo.browserName.name;
        deviceData['deviceManufacturer'] = 'Web';
        deviceData['userAgent'] = webInfo.userAgent;
        deviceData['platform'] = webInfo.platform;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData['deviceModel'] = androidInfo.model;
        deviceData['deviceManufacturer'] = androidInfo.manufacturer;
        deviceData['androidVersion'] = androidInfo.version.release;
        deviceData['sdkVersion'] = androidInfo.version.sdkInt.toString();
        deviceData['brand'] = androidInfo.brand;
        deviceData['device'] = androidInfo.device;
        deviceData['isPhysicalDevice'] = androidInfo.isPhysicalDevice;

        // Use flutter_udid package for getting device ID
        try {
          final String udid = await FlutterUdid.udid;
          deviceData['deviceId'] = udid;
        } catch (e) {
          debugPrint('Error getting UDID: $e');
          // Fallback to the old method if flutter_udid package fails
          deviceData['deviceId'] = androidInfo.id;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData['deviceModel'] = iosInfo.model;
        deviceData['deviceManufacturer'] = 'Apple';
        deviceData['systemName'] = iosInfo.systemName;
        deviceData['systemVersion'] = iosInfo.systemVersion;
        deviceData['name'] = iosInfo.name;
        deviceData['isPhysicalDevice'] = iosInfo.isPhysicalDevice;
        deviceData['utsname'] = iosInfo.utsname.machine;
        deviceData['deviceId'] = iosInfo.identifierForVendor;
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfoPlugin.macOsInfo;
        deviceData['deviceModel'] = macOsInfo.model;
        deviceData['deviceManufacturer'] = 'Apple';
        deviceData['computerName'] = macOsInfo.computerName;
        deviceData['hostName'] = macOsInfo.hostName;
        deviceData['arch'] = macOsInfo.arch;
        deviceData['osRelease'] = macOsInfo.osRelease;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        deviceData['deviceModel'] = 'Windows Device';
        deviceData['deviceManufacturer'] = 'Windows';
        deviceData['computerName'] = windowsInfo.computerName;
        deviceData['numberOfCores'] = windowsInfo.numberOfCores.toString();
        deviceData['systemMemoryInMegabytes'] =
            windowsInfo.systemMemoryInMegabytes.toString();
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        deviceData['deviceModel'] = 'Linux Device';
        deviceData['deviceManufacturer'] = 'Linux';
        deviceData['name'] = linuxInfo.name;
        deviceData['version'] = linuxInfo.version;
        deviceData['id'] = linuxInfo.id;
        deviceData['prettyName'] = linuxInfo.prettyName;
      } else {
        deviceData['deviceModel'] = 'Unknown';
        deviceData['deviceManufacturer'] = 'Unknown';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return deviceData;
  }

  /// Get battery information
  ///
  /// Returns a map containing:
  /// - batteryLevel: Battery level as a percentage (0.0 to 1.0)
  /// - isCharging: Whether the device is currently charging
  static Future<Map<String, dynamic>> getBatteryInfo() async {
    final Map<String, dynamic> batteryData = {};

    try {
      final Battery battery = Battery();
      final int batteryLevelInt = await battery.batteryLevel;
      final batteryLevel = batteryLevelInt / 100.0;
      final isCharging = await battery.batteryState == BatteryState.charging;

      batteryData['batteryLevel'] = batteryLevel;
      batteryData['isCharging'] = isCharging;
    } catch (e) {
      debugPrint('Error getting battery info: $e');
      // Provide default values in case of error
      batteryData['batteryLevel'] = null;
      batteryData['isCharging'] = null;
    }

    return batteryData;
  }

  /// Get network connectivity information
  ///
  /// Returns a map containing:
  /// - networkType: The type of network connection (wifi, mobile, none, etc.)
  static Future<Map<String, dynamic>> getNetworkInfo() async {
    final Map<String, dynamic> networkData = {};

    try {
      final Connectivity connectivity = Connectivity();
      final connectivityResults = await connectivity.checkConnectivity();

      String networkType;
      // Handle the list of connectivity results
      if (connectivityResults.isEmpty) {
        networkType = 'none';
      } else {
        // Use the first connectivity result
        final connectivityResult = connectivityResults.first;
        switch (connectivityResult) {
          case ConnectivityResult.wifi:
            networkType = 'wifi';
            break;
          case ConnectivityResult.mobile:
            networkType = 'mobile';
            break;
          case ConnectivityResult.ethernet:
            networkType = 'ethernet';
            break;
          case ConnectivityResult.bluetooth:
            networkType = 'bluetooth';
            break;
          case ConnectivityResult.vpn:
            networkType = 'vpn';
            break;
          case ConnectivityResult.none:
            networkType = 'none';
            break;
          default:
            networkType = 'unknown';
        }
      }

      networkData['networkType'] = networkType;
    } catch (e) {
      debugPrint('Error getting network info: $e');
      networkData['networkType'] = null;
    }

    return networkData;
  }

  /// Get device orientation
  ///
  /// Returns the current device orientation as a string
  /// Note: This method requires a BuildContext to access MediaQuery
  /// and should be called from a widget context
  static String? getDeviceOrientation(BuildContext? context) {
    try {
      if (context != null) {
        final orientation = MediaQuery.of(context).orientation;
        return orientation == Orientation.portrait ? 'portrait' : 'landscape';
      }

      // If no context is provided, try to determine orientation from screen size
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final view = PlatformDispatcher.instance.views.first;
        final size = view.physicalSize;
        final orientation = size.width > size.height ? 'landscape' : 'portrait';
        return orientation;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting device orientation: $e');
      return null;
    }
  }

  /// Get comprehensive device information
  ///
  /// This method combines all available device information methods
  /// and returns a complete picture of the device state
  static Future<Map<String, dynamic>> getCompleteDeviceInfo(
      [BuildContext? context]) async {
    final Map<String, dynamic> completeInfo = {};

    try {
      // Get orientation first (before any async operations to avoid BuildContext issues)
      final orientation = getDeviceOrientation(context);
      if (orientation != null) {
        completeInfo['deviceOrientation'] = orientation;
      }

      // Get basic device info
      final basicInfo = await getBasicDeviceInfo();
      completeInfo.addAll(basicInfo);

      // Get battery info
      final batteryInfo = await getBatteryInfo();
      if (batteryInfo['batteryLevel'] != null) {
        completeInfo['batteryLevel'] = batteryInfo['batteryLevel'];
      }
      if (batteryInfo['isCharging'] != null) {
        completeInfo['isCharging'] = batteryInfo['isCharging'];
      }

      // Get network info
      final networkInfo = await getNetworkInfo();
      if (networkInfo['networkType'] != null) {
        completeInfo['networkType'] = networkInfo['networkType'];
      }
    } catch (e) {
      debugPrint('Error getting complete device info: $e');
    }

    return completeInfo;
  }
}

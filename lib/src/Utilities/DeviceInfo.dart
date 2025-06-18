import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:dart_flutter_version/dart_flutter_version.dart';
import '../Metriqus.dart';

/// Device information collector for Flutter
class DeviceInfo {
  String packageName = '';
  String appVersion = '';
  String flutterVersion = '';
  String deviceType = '';
  String deviceName = '';
  String deviceModel = '';
  int platform = -1; // 0: iOS, 1: Android, -1: Other
  String graphicsDeviceName = '';
  String osName = '';
  int systemMemorySize = 0;
  int graphicsMemorySize = 0;
  String language = '';
  String country = '';
  int screenDpi = 0;
  int screenWidth = 0;
  int screenHeight = 0;
  String deviceId = '';
  String? vendorId;
  String adId = '';
  bool trackingEnabled = false;

  DeviceInfo();

  /// Initialize device info asynchronously
  Future<void> initialize() async {
    try {
      // Get package info
      final packageInfo = await PackageInfo.fromPlatform();
      packageName = packageInfo.packageName;
      appVersion = packageInfo.version;

      // Get Flutter version from native code
      await _updateFlutterVersion();

      // Get device info
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        platform = 1;
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceName = androidInfo.device;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';

        String buildDisplay = androidInfo.display ?? '';
        osName =
            'Android OS ${androidInfo.version.release} / API-${androidInfo.version.sdkInt}';
        if (buildDisplay.isNotEmpty) {
          osName += ' ($buildDisplay)';
        }

        deviceId = androidInfo.id;
        deviceType = _getAndroidDeviceType();
        await _getGpuInfo();
        await _getAdInfo();
      } else if (Platform.isIOS) {
        platform = 0;
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceName = iosInfo.model;
        deviceModel = iosInfo.utsname.machine;

        String systemName = iosInfo.systemName;
        if (iosInfo.model.toLowerCase().contains('ipad')) {
          systemName = 'iPadOS';
        }
        osName = '$systemName ${iosInfo.systemVersion}';

        deviceId = iosInfo.identifierForVendor ?? '';
        vendorId = iosInfo.identifierForVendor;
        deviceType = _getIOSDeviceType(iosInfo.model);
        await _getGpuInfo();
        await _getAdInfo();
      } else {
        platform = -1;
        deviceType = 'desktop';
        osName = Platform.operatingSystem;
      }

      // Get screen info from platform channel
      await _getScreenInfo();

      // Get system info
      final localeLanguageCode = Platform.localeName.split('_')[0];
      language = await _getLanguageDisplayName(localeLanguageCode);
      country = Platform.localeName.contains('_')
          ? Platform.localeName.split('_')[1]
          : 'US';
    } catch (e) {
      Metriqus.errorLog('Error initializing device info: $e');
    }
  }

  /// Get screen information via platform channel
  Future<void> _getScreenInfo() async {
    try {
      const platform = MethodChannel('metriqus_flutter_sdk/device_info');
      final result = await platform.invokeMethod('getScreenInfo');

      if (result != null) {
        screenWidth = result['width'] ?? 0;
        screenHeight = result['height'] ?? 0;
        screenDpi = (result['dpi'] ?? 0.0).round();
      }
    } catch (e) {
      // Fallback values
      screenWidth = 1080;
      screenHeight = 1920;
      screenDpi = 160;
    }
  }

  /// Get GPU information directly from native code
  Future<void> _getGpuInfo() async {
    try {
      const platform = MethodChannel('metriqus_flutter_sdk/device_info');
      final result = await platform.invokeMethod('getGpuInfo');

      if (result != null && result is Map) {
        graphicsDeviceName = result['renderer'] ?? 'Unknown GPU';
        systemMemorySize =
            ((result['systemMemory'] ?? 0) / (1024 * 1024)).round();
        graphicsMemorySize =
            ((result['graphicsMemory'] ?? 0) / (1024 * 1024)).round();
      } else {
        graphicsDeviceName = 'Unknown GPU';
      }
    } catch (e) {
      Metriqus.errorLog('Error getting GPU info: $e');
      graphicsDeviceName = 'Unknown GPU';
    }
  }

  /// Get advertising ID and tracking status from native code
  Future<void> _getAdInfo() async {
    try {
      const platform = MethodChannel('metriqus_flutter_sdk/device_info');
      final result = await platform.invokeMethod('getAdId');

      if (result != null && result is Map) {
        adId = result['adId'] ?? '';
        trackingEnabled = result['trackingEnabled'] ?? false;
      }
    } catch (e) {
      Metriqus.errorLog('Error getting Ad info: $e');
      adId = '';
      trackingEnabled = false;
    }
  }

  /// Get Flutter framework version using dart_flutter_version package
  Future<void> _updateFlutterVersion() async {
    try {
      // dart_flutter_version paketini kullanarak Flutter version'ı al
      final DartFlutterVersion versionInfo = DartFlutterVersion();
      final flutterVersionObj = versionInfo.flutterVersion;

      if (flutterVersionObj != null) {
        flutterVersion = flutterVersionObj.toString();
      } else {
        flutterVersion = '';
      }
    } catch (e) {
      Metriqus.errorLog('Error getting Flutter version: $e');
      flutterVersion = '';
    }
  }

  /// Calculate device diagonal size in inches
  double _deviceDiagonalSizeInInches() {
    if (screenDpi <= 0) return 0.0;

    double screenWidthInches = screenWidth / screenDpi.toDouble();
    double screenHeightInches = screenHeight / screenDpi.toDouble();
    return sqrt(pow(screenWidthInches, 2) + pow(screenHeightInches, 2));
  }

  /// Determine Android device type
  String _getAndroidDeviceType() {
    double shortestSidePx = min(screenWidth, screenHeight).toDouble();

    double logicalShortestSide = (shortestSidePx * 160) / screenDpi.toDouble();

    if (logicalShortestSide > 600) {
      return 'tablet';
    } else {
      return 'phone';
    }
  }

  /// Determine iOS device type
  String _getIOSDeviceType(String model) {
    if (model.toLowerCase().contains('ipad')) {
      return 'tablet';
    } else if (model.toLowerCase().contains('iphone')) {
      return 'phone';
    }
    return 'phone'; // Default for iOS
  }

  /// Convert language code to display name using native code
  Future<String> _getLanguageDisplayName(String languageCode) async {
    try {
      const platform = MethodChannel('metriqus_flutter_sdk/device_info');
      final result = await platform.invokeMethod('getLanguageDisplayName', {
        'languageCode': languageCode,
      });

      if (result != null && result is String && result.isNotEmpty) {
        return result;
      }

      // Fallback olarak bilinen dilleri kullan
      return _getLanguageNameFromCode(languageCode);
    } catch (e) {
      return _getLanguageNameFromCode(languageCode);
    }
  }

  /// Fallback method for common language codes
  String _getLanguageNameFromCode(String languageCode) {
    // En yaygın dillerin mapping'i - daha kısa liste
    switch (languageCode.toLowerCase()) {
      case 'en':
        return 'English';
      case 'tr':
        return 'Turkish';
      case 'ar':
        return 'Arabic';
      case 'de':
        return 'German';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'it':
        return 'Italian';
      case 'pt':
        return 'Portuguese';
      case 'ru':
        return 'Russian';
      case 'zh':
        return 'Chinese';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      default:
        return languageCode.toUpperCase();
    }
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appVersion': appVersion,
      'flutterVersion': flutterVersion,
      'deviceType': deviceType,
      'deviceName': deviceName,
      'deviceModel': deviceModel,
      'platform': platform,
      'graphicsDeviceName': graphicsDeviceName,
      'osName': osName,
      'systemMemorySize': systemMemorySize,
      'graphicsMemorySize': graphicsMemorySize,
      'language': language,
      'country': country,
      'screenDpi': screenDpi,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'deviceId': deviceId,
      'vendorId': vendorId,
      'adId': adId,
      'trackingEnabled': trackingEnabled,
    };
  }
}

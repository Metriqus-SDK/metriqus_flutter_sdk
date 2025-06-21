import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'MetriqusSettings.dart';
import 'Utilities/MetriqusUtils.dart';
import 'Native/MetriqusNative.dart';
import 'Native/iOS/MetriqusIOS.dart';
import 'Native/Android/MetriqusAndroid.dart';
import 'EventModels/AdRevenue/MetriqusAdRevenue.dart';
import 'EventModels/AdRevenue/MetriqusApplovinAdRevenue.dart';

import 'EventModels/AdRevenue/MetriqusAdmobAdRevenue.dart';
import 'EventModels/MetriqusInAppRevenue.dart';
import 'EventModels/CustomEvents/MetriqusCustomEvent.dart';
import 'EventLogger/Parameters/TypedParameter.dart';
import 'Utilities/MetriqusEnvironment.dart';
import 'Utilities/UniqueUserIdentifier.dart';
import 'EventModels/CustomEvents/LevelProgression/MetriqusLevelStartedEvent.dart';
import 'EventModels/CustomEvents/LevelProgression/MetriqusLevelCompletedEvent.dart';
import 'EventModels/CustomEvents/MetriqusItemUsedEvent.dart';
import 'EventModels/CustomEvents/MetriqusCampaignActionEvent.dart';
import 'Package/PackageModels/AppInfoPackage.dart';
import 'EventLogger/MetriqusLogger.dart';

/// Main Metriqus SDK class for Flutter
class Metriqus {
  // Private static fields
  static MetriqusNative? _native;
  static MetriqusSettings? _metriqusSettings;
  static bool _isInitialized = false;
  static bool _isTrackingEnabled = true;

  // Stream controllers for events
  static final StreamController<String> _onLogController =
      StreamController<String>.broadcast();
  static final StreamController<bool> _onSdkInitializeController =
      StreamController<bool>.broadcast();

  // Public getters
  static Stream<String> get onLog => _onLogController.stream;
  static Stream<bool> get onSdkInitialize => _onSdkInitializeController.stream;
  static bool get isInitialized => _isInitialized;
  static bool get isTrackingEnabled => _isTrackingEnabled;
  static MetriqusSettings? get settings => _metriqusSettings;
  static MetriqusNative? get native => _native;

  /// Initialize the SDK
  static Future<void> initSdk(MetriqusSettings settings) async {
    try {
      verboseLog("🚀 Metriqus SDK initialization started");

      if (settings.clientKey.isEmpty || settings.clientSecret.isEmpty) {
        errorLog("❌ Client key or secret is empty");
        _onSdkInitializeController.add(false);
        return;
      }

      _metriqusSettings = settings;
      verboseLog("🔧 Settings configured");

      // Create platform-specific native implementation
      if (MetriqusUtils.isIOS) {
        _native = MetriqusIOS();
        verboseLog("🔧 iOS native instance created");
      } else if (MetriqusUtils.isAndroid) {
        _native = MetriqusAndroid();
        verboseLog("🔧 Android native instance created");
      } else {
        errorLog("❌ Unsupported platform");
        _onSdkInitializeController.add(false);
        return;
      }

      // Initialize native SDK
      try {
        verboseLog("🔧 Starting native SDK initialization...");
        await _native!.initSdk(settings);
        verboseLog("🔧 Native SDK initialization method completed");

        _isInitialized = _native!.getIsInitialized;
        verboseLog("🔧 Native isInitialized status: $_isInitialized");

        if (_isInitialized) {
          infoLog("✅ Metriqus SDK initialization completed successfully");
          _onSdkInitializeController.add(true);
        } else {
          errorLog(
              "❌ Metriqus SDK initialization failed - native returned false");
          _onSdkInitializeController.add(false);
        }
      } catch (nativeError) {
        errorLog("❌ Exception during native SDK initialization: $nativeError");
        _isInitialized = false;
        _onSdkInitializeController.add(false);
        rethrow;
      }
    } catch (e, stackTrace) {
      errorLog("❌ Error during SDK initialization: $e");
      errorLog("❌ Stack trace: $stackTrace");
      _isInitialized = false;
      _onSdkInitializeController.add(false);
    }
  }

  /// Check if SDK is initialized
  static bool _checkInitialization() {
    if (!_isInitialized || _native == null) {
      // During initialization, avoid calling infoLog which checks _metriqusSettings
      if (_metriqusSettings != null) {
        infoLog("⚠️ SDK not initialized. Call initSdk() first.");
      }
      return false;
    }
    return true;
  }

  /// Set tracking enabled/disabled
  static void setTrackingEnabled(bool enabled) {
    _isTrackingEnabled = enabled;
    infoLog("📊 Tracking ${enabled ? 'enabled' : 'disabled'}");
  }

  /// Track ad revenue (with MetriqusAdRevenue object)
  static void trackAdRevenue(MetriqusAdRevenue adRevenue) {
    if (!_checkInitialization()) return;

    eventLog("ad_revenue", {
      "source": adRevenue.source,
      "revenue": adRevenue.revenue,
      "currency": adRevenue.currency,
    });
    infoLog("Ad revenue event created and sent to native layer");
    _native!.trackAdRevenue(adRevenue);
  }

  /// Track AppLovin ad revenue
  static void trackApplovinAdRevenue(MetriqusApplovinAdRevenue adRevenue) {
    if (!_checkInitialization()) return;

    eventLog("applovin_ad_revenue", {
      "ad_unit": adRevenue.adRevenueUnit,
      "revenue": adRevenue.revenue,
      "currency": adRevenue.currency,
    });
    infoLog("AppLovin ad revenue event created and sent to native layer");
    _native!.trackAdRevenue(adRevenue);
  }

  /// Track AdMob ad revenue
  static void trackAdmobAdRevenue(MetriqusAdmobAdRevenue adRevenue) {
    if (!_checkInitialization()) return;

    eventLog("admob_ad_revenue", {
      "ad_unit": adRevenue.adRevenueUnit,
      "revenue": adRevenue.revenue,
      "currency": adRevenue.currency,
    });
    infoLog("AdMob ad revenue event created and sent to native layer");
    _native!.trackAdRevenue(adRevenue);
  }

  /// Track ad revenue (with Map for backward compatibility)
  static void trackAdRevenueMap(Map<String, dynamic> adRevenue) {
    if (!_checkInitialization()) return;

    verboseLog("💰 Tracking ad revenue from map: $adRevenue");
    // Convert map to MetriqusAdRevenue if needed
    // For now, just log it
  }

  /// Track IAP event
  static void trackIAPEvent(MetriqusInAppRevenue iapEvent) {
    if (!_checkInitialization()) return;

    eventLog("iap_revenue", {
      "product_id": iapEvent.productId,
      "revenue": iapEvent.revenue,
      "currency": iapEvent.currency,
      "name": iapEvent.name,
    });
    infoLog("IAP event created and sent to native layer");
    _native!.trackIAPEvent(iapEvent);
  }

  static void trackCustomEvent(MetriqusCustomEvent customEvent) {
    if (!_checkInitialization()) return;

    eventLog(customEvent.key ?? 'custom_event', null);
    infoLog(
      "Custom event '${customEvent.key ?? 'custom_event'}' created and sent to native layer",
    );
    _native!.trackCustomEvent(customEvent);
  }

  /// Track custom event with string and parameters (backward compatibility)
  static void trackCustomEventWithParameters(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) {
    if (!_checkInitialization()) return;

    var customEvent = MetriqusCustomEvent(eventName);

    if (parameters != null) {
      parameters.forEach((key, value) {
        if (value is String) {
          customEvent.addParameter(TypedParameter.string(key, value));
        } else if (value is int) {
          customEvent.addParameter(TypedParameter.int(key, value));
        } else if (value is double) {
          customEvent.addParameter(TypedParameter.double(key, value));
        } else if (value is bool) {
          customEvent.addParameter(TypedParameter.bool(key, value));
        } else {
          customEvent.addParameter(
            TypedParameter.string(key, value.toString()),
          );
        }
      });
    }

    eventLog(eventName, parameters);
    infoLog("Custom event '$eventName' created and sent to native layer");
    _native!.trackCustomEvent(customEvent);
  }

  /// Track level started with event object
  static void trackLevelStarted(MetriqusLevelStartedEvent levelEvent) {
    if (!_checkInitialization()) return;

    eventLog(levelEvent.key ?? 'level_start', null);
    infoLog(
      "Level started event '${levelEvent.key ?? 'level_start'}' created and sent to native layer",
    );
    _native!.trackCustomEvent(levelEvent);
  }

  /// Track level completed with event object
  static void trackLevelCompleted(MetriqusLevelCompletedEvent levelEvent) {
    if (!_checkInitialization()) return;

    eventLog(levelEvent.key ?? 'level_completed', null);
    infoLog(
      "Level completed event '${levelEvent.key ?? 'level_completed'}' created and sent to native layer",
    );
    _native!.trackCustomEvent(levelEvent);
  }

  /// Track item used with event object
  static void trackItemUsed(MetriqusItemUsedEvent itemEvent) {
    if (!_checkInitialization()) return;

    eventLog(itemEvent.key ?? 'item_used', null);
    infoLog(
      "Item used event '${itemEvent.key ?? 'item_used'}' created and sent to native layer",
    );
    _native!.trackCustomEvent(itemEvent);
  }

  /// Track campaign action with event object
  static void trackCampaignAction(MetriqusCampaignActionEvent campaignEvent) {
    if (!_checkInitialization()) return;

    eventLog(campaignEvent.key ?? 'campaign_details', null);
    infoLog(
      "Campaign action event '${campaignEvent.key ?? 'campaign_details'}' created and sent to native layer",
    );
    _native!.trackCustomEvent(campaignEvent);
  }

  /// Track screen view
  static void trackScreenView(String screenName) {
    var customEvent = MetriqusCustomEvent('screen_view');
    customEvent.addParameter(TypedParameter.string('screen_name', screenName));
    trackCustomEvent(customEvent);
  }

  /// Track performance
  static void trackPerformance(double fps) {
    var customEvent = MetriqusCustomEvent('performance');
    customEvent.addParameter(TypedParameter.double('fps', fps));
    trackCustomEvent(customEvent);
  }

  /// Track button click
  static void trackButtonClick(String buttonName) {
    var customEvent = MetriqusCustomEvent('button_click');
    customEvent.addParameter(TypedParameter.string('button_name', buttonName));
    trackCustomEvent(customEvent);
  }

  static void setUserAttribute(TypedParameter parameter) {
    if (!_checkInitialization()) return;

    verboseLog(
      "👤 Setting user attribute: ${parameter.name} = ${parameter.value}",
    );
    _native!.setUserAttribute(parameter);
  }

  /// Set user attribute with key-value (backward compatibility)
  static void setUserAttributeKeyValue(String key, dynamic value) {
    if (!_checkInitialization()) return;

    TypedParameter parameter;
    if (value is String) {
      parameter = TypedParameter.string(key, value);
    } else if (value is int) {
      parameter = TypedParameter.int(key, value);
    } else if (value is double) {
      parameter = TypedParameter.double(key, value);
    } else if (value is bool) {
      parameter = TypedParameter.bool(key, value);
    } else {
      parameter = TypedParameter.string(key, value.toString());
    }

    verboseLog("👤 Setting user attribute: $key = $value");
    _native!.setUserAttribute(parameter);
  }

  /// Remove user attribute
  static void removeUserAttribute(String key) {
    if (!_checkInitialization()) return;

    verboseLog("👤 Removing user attribute: $key");
    _native!.removeUserAttribute(key);
  }

  /// Send session beat event
  static void sendSessionBeatEvent() {
    if (!_checkInitialization()) return;

    verboseLog("💓 Sending session beat");
    _native!.sendSessionBeatEvent();
  }

  /// Update iOS conversion value (iOS specific)
  static void updateIOSConversionValue(int value) {
    if (!_checkInitialization()) return;

    if (MetriqusUtils.isIOS) {
      verboseLog("🍎 Updating iOS conversion value: $value");
      _native!.updateIOSConversionValue(value);
    }
  }

  /// Get advertising ID
  static String? getAdid() {
    if (!_checkInitialization()) return null;
    return _native!.getAdid();
  }

  /// Get session ID
  static String? getSessionId() {
    if (!_checkInitialization()) return null;
    return _native!.getSessionId;
  }

  /// Get unique user identifier
  static String? getUserId() {
    if (!_checkInitialization()) return null;
    // Get the user ID from the UniqueUserIdentifier instance
    if (_native!.uniqueUserIdentifier != null) {
      return _native!.uniqueUserIdentifier!.id;
    }
    // Fallback: check storage directly
    if (_native!.storage != null) {
      // Check if user ID exists in storage synchronously using new key
      if (_native!.storage!.checkKeyExist("UniqueUserIdentifier")) {
        return _native!.storage!.loadData("UniqueUserIdentifier");
      }
    }
    return null;
  }

  /// Get client SDK version
  static Future<String> getClientSdk() async {
    try {
      // Read pubspec.yaml from assets
      final pubspecContent = await rootBundle
          .loadString('packages/metriqus_flutter_sdk/pubspec.yaml');

      // Parse YAML content properly
      final yamlDoc = loadYaml(pubspecContent);
      final version = yamlDoc['version']?.toString();

      if (version != null && version.isNotEmpty) {
        return "flutter-$version";
      }

      return "flutter-";
    } catch (e) {
      verboseLog("Could not read SDK version from pubspec.yaml: $e");
      return "flutter-";
    }
  }

  /// Get device info
  static dynamic getDeviceInfo() {
    if (!_checkInitialization()) return null;
    return _native!.getDeviceInfo;
  }

  /// Get remote settings
  static dynamic getMetriqusRemoteSettings() {
    if (!_checkInitialization()) return null;
    return _native!.getMetriqusRemoteSettings();
  }

  /// Get Metriqus settings
  static MetriqusSettings? getMetriqusSettings() {
    return _metriqusSettings;
  }

  /// Get log level
  static LogLevel get logLevel => _metriqusSettings?.logLevel ?? LogLevel.noLog;

  /// Get unique user ID (for backward compatibility)
  static String? getUniqueUserId() {
    return getUserId();
  }

  /// Enqueue callback for thread safety
  static void enqueueCallback(Function action) {
    try {
      action();
    } catch (e) {
      errorLog("Error executing callback: $e");
    }
  }

  /// Get if this is first launch (for backward compatibility)
  static bool getIsFirstLaunch() {
    return isFirstLaunch();
  }

  /// Get user first touch timestamp
  static DateTime? getUserFirstTouchTimestamp() {
    if (!_checkInitialization()) return null;
    return _native!.getFirstLaunchTime();
  }

  /// Get geolocation
  static dynamic getGeolocation() {
    if (!_checkInitialization()) return null;
    return _native!.getGeolocation();
  }

  /// Get user attributes
  static Map<String, dynamic>? getUserAttributes() {
    if (!_checkInitialization()) return null;

    final attributes = _native!.userAttributes?.getAllAttributes();
    if (attributes == null || attributes.isEmpty) return null;

    return attributes;
  }

  /// Check if this is first launch
  static bool isFirstLaunch() {
    if (!_checkInitialization()) return false;
    return _native!.getIsFirstLaunch;
  }

  /// Application lifecycle methods
  static void onPause() {
    if (!_checkInitialization()) return;
    verboseLog("⏸️ App paused");
    _native!.onPause();
  }

  static void onResume() {
    if (!_checkInitialization()) return;
    verboseLog("▶️ App resumed");
    _native!.onResume();
  }

  static void onQuit() {
    if (!_checkInitialization()) return;
    verboseLog("🛑 App quit");
    _native!.onQuit();
  }

  /// Dispose resources
  static void dispose() {
    MetriqusLogger.dispose();
    _onLogController.close();
    _onSdkInitializeController.close();
    _isInitialized = false;
    _native = null;
    _metriqusSettings = null;
    verboseLog("🗑️ Metriqus SDK disposed");
  }

  /// Debug log method with proper level filtering
  static void debugLog(String message, [LogLevel level = LogLevel.verbose]) {
    final timestamp = MetriqusUtils.timestampSecondsToDateTime(
      MetriqusUtils.getCurrentUtcTimestampSeconds(),
    ).toIso8601String();
    String logLevelStr = level.toString().split('.').last.toUpperCase();
    String logMessage = "[$timestamp][METRIQUS][$logLevelStr] $message";

    // Always add to stream for listeners (independent of logLevel setting)
    _onLogController.add(logMessage);

    // Get current log level from settings for console printing
    LogLevel currentLogLevel = _metriqusSettings?.logLevel ?? LogLevel.noLog;

    // Check if we should print to console based on current log level
    // noLog(0) = print nothing
    // errorsOnly(1) = print only errorsOnly level messages
    // debug(2) = print errorsOnly + debug level messages
    // verbose(3) = print errorsOnly + debug + verbose level messages
    bool shouldPrintToConsole = _shouldPrintToConsole(currentLogLevel, level);

    // Only print to console if log level allows it
    if (shouldPrintToConsole) {
      print(logMessage);
    }
  }

  /// Helper method to determine if a message should be printed to console
  static bool _shouldPrintToConsole(
      LogLevel currentLogLevel, LogLevel messageLevel) {
    switch (currentLogLevel) {
      case LogLevel.noLog:
        return false; // Never print to console
      case LogLevel.errorsOnly:
        return messageLevel == LogLevel.errorsOnly;
      case LogLevel.debug:
        return messageLevel == LogLevel.errorsOnly ||
            messageLevel == LogLevel.debug;
      case LogLevel.verbose:
        return true; // Print all levels
    }
  }

  /// Verbose logging for detailed operations
  static void verboseLog(String message) {
    debugLog("$message", LogLevel.verbose);
  }

  /// Info logging for general information
  static void infoLog(String message) {
    debugLog("$message", LogLevel.debug);
  }

  /// Error logging for errors
  static void errorLog(String message) {
    debugLog("$message", LogLevel.errorsOnly);
  }

  /// Event logging for tracking events
  static void eventLog(String eventName, Map<String, dynamic>? parameters) {
    String paramStr =
        parameters != null ? " | Parameters: ${parameters.toString()}" : "";
    debugLog("📊 EVENT: $eventName$paramStr", LogLevel.debug);
  }

  /// EventQueue logging for queue operations
  static void eventQueueLog(String operation, {Map<String, dynamic>? details}) {
    String detailStr =
        details != null ? " | Details: ${details.toString()}" : "";
    debugLog("📦 EVENTQUEUE: $operation$detailStr", LogLevel.verbose);
  }

  /// Network logging for HTTP requests/responses
  static void networkLog(
    String operation,
    String url, {
    String? requestBody,
    String? responseBody,
    int? statusCode,
  }) {
    String logMessage = "🌐 NETWORK: $operation | URL: $url";
    if (statusCode != null) logMessage += " | Status: $statusCode";
    if (requestBody != null) logMessage += " | Request: $requestBody";
    if (responseBody != null) logMessage += " | Response: $responseBody";
    debugLog(logMessage, LogLevel.verbose);
  }

  /// Debug method to clear all storage (for development only)
  static void clearStorage() {
    if (_native?.storage != null) {
      try {
        // Clear specific keys that might have malformed data
        final keysToRemove = [
          'metriqus_current_events',
          'metriqus_events_to_send',
          'metriqus_last_flush_time',
        ];

        for (String key in keysToRemove) {
          if (_native!.storage!.checkKeyExist(key)) {
            _native!.storage!.deleteData(key);
            verboseLog("🗑️ Cleared storage key: $key");
          }
        }

        infoLog("🗑️ Storage cleared successfully");
      } catch (e) {
        errorLog("❌ Error clearing storage: $e");
      }
    } else {
      errorLog("❌ Storage not available");
    }
  }
}

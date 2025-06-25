import 'dart:convert';
import 'Metriqus.dart';

/// Remote settings configuration for Metriqus
class MetriqusRemoteSettings {
  // Singleton instance
  static MetriqusRemoteSettings? _instance;

  int maxEventBatchCount = 10;
  int maxEventStoreSeconds = 2 * 60; // 2 minutes
  int sendEventIntervalSeconds = 2;
  int sessionIntervalMinutes = 30;
  int attributionCheckWindow = 20;
  int geolocationFetchIntervalDays = 2;
  String? eventPostUrl;

  // Private constructor
  MetriqusRemoteSettings._internal();

  /// Get singleton instance
  static MetriqusRemoteSettings getInstance() {
    _instance ??= MetriqusRemoteSettings._internal();
    return _instance!;
  }

  /// Update settings from remote data
  static void updateFromRemote(dynamic input) {
    final instance = getInstance();
    final parsedSettings = _parseRemoteData(input);

    if (parsedSettings != null) {
      // Update all fields in the singleton instance
      instance.maxEventBatchCount = parsedSettings.maxEventBatchCount;
      instance.maxEventStoreSeconds = parsedSettings.maxEventStoreSeconds;
      instance.sendEventIntervalSeconds =
          parsedSettings.sendEventIntervalSeconds;
      instance.sessionIntervalMinutes = parsedSettings.sessionIntervalMinutes;
      instance.attributionCheckWindow = parsedSettings.attributionCheckWindow;
      instance.geolocationFetchIntervalDays =
          parsedSettings.geolocationFetchIntervalDays;
      instance.eventPostUrl = parsedSettings.eventPostUrl;

      Metriqus.verboseLog(
          'MetriqusRemoteSettings singleton updated successfully');
    } else {
      Metriqus.errorLog(
          'Failed to parse remote settings, keeping current values');
    }
  }

  /// Parse remote settings from JSON string or Map (kept for backward compatibility)
  static MetriqusRemoteSettings? parse(dynamic input) {
    final instance = getInstance();
    final parsedSettings = _parseRemoteData(input);

    if (parsedSettings != null) {
      // Update the singleton instance instead of creating a new one
      instance.maxEventBatchCount = parsedSettings.maxEventBatchCount;
      instance.maxEventStoreSeconds = parsedSettings.maxEventStoreSeconds;
      instance.sendEventIntervalSeconds =
          parsedSettings.sendEventIntervalSeconds;
      instance.sessionIntervalMinutes = parsedSettings.sessionIntervalMinutes;
      instance.attributionCheckWindow = parsedSettings.attributionCheckWindow;
      instance.geolocationFetchIntervalDays =
          parsedSettings.geolocationFetchIntervalDays;
      instance.eventPostUrl = parsedSettings.eventPostUrl;
    }

    return instance;
  }

  /// Internal method to parse remote data
  static MetriqusRemoteSettings? _parseRemoteData(dynamic input) {
    try {
      Map<String, dynamic> jsonData;

      if (input is Map<String, dynamic>) {
        // Direct Map input
        Metriqus.verboseLog('MetriqusRemoteSettings input: Map object');
        jsonData = input;
      } else if (input is String) {
        Metriqus.verboseLog('MetriqusRemoteSettings jsonString: $input');

        // If the input is already a Map object (converted to string), try to parse it differently
        if (input.startsWith('{') && !input.contains('"')) {
          // This looks like a Dart Map toString() output, not valid JSON
          Metriqus.infoLog(
              'Input appears to be Dart Map toString(), keeping current settings');
          return null; // Return null to keep current settings
        }

        // Clean the JSON string - remove any extra quotes or escape characters
        String cleanedJsonString = input.trim();

        // If the string starts and ends with quotes, it might be double-encoded
        if (cleanedJsonString.startsWith('"') &&
            cleanedJsonString.endsWith('"')) {
          cleanedJsonString =
              cleanedJsonString.substring(1, cleanedJsonString.length - 1);
          // Unescape any escaped quotes
          cleanedJsonString = cleanedJsonString.replaceAll('\\"', '"');
          cleanedJsonString = cleanedJsonString.replaceAll('\\\\', '\\');
        }

        Metriqus.verboseLog(
            'MetriqusRemoteSettings cleaned jsonString: $cleanedJsonString');

        jsonData = jsonDecode(cleanedJsonString);
      } else {
        // Unsupported input type
        Metriqus.errorLog('MetriqusRemoteSettings: Unsupported input type');
        return null;
      }

      final tempSettings = MetriqusRemoteSettings._internal();

      // Parse and assign values, keeping default values if parsing fails or value is missing
      if (jsonData.containsKey('maxEventBatchCount')) {
        try {
          tempSettings.maxEventBatchCount =
              int.parse(jsonData['maxEventBatchCount'].toString());
        } catch (e) {
          // Keep default value
        }
      }

      if (jsonData.containsKey('maxEventStoreSeconds')) {
        try {
          tempSettings.maxEventStoreSeconds =
              int.parse(jsonData['maxEventStoreSeconds'].toString());
        } catch (e) {
          // Keep default value
        }
      }

      if (jsonData.containsKey('sendEventIntervalSeconds')) {
        try {
          tempSettings.sendEventIntervalSeconds =
              int.parse(jsonData['sendEventIntervalSeconds'].toString());
        } catch (e) {
          // Keep default value
        }
      }

      if (jsonData.containsKey('sessionIntervalMinutes')) {
        try {
          tempSettings.sessionIntervalMinutes =
              int.parse(jsonData['sessionIntervalMinutes'].toString());
        } catch (e) {
          // Keep default value
        }
      }

      if (jsonData.containsKey('attributionCheckWindow')) {
        try {
          tempSettings.attributionCheckWindow =
              int.parse(jsonData['attributionCheckWindow'].toString());
        } catch (e) {
          // Keep default value
        }
      }

      if (jsonData.containsKey('geolocationFetchIntervalDays')) {
        try {
          tempSettings.geolocationFetchIntervalDays =
              int.parse(jsonData['geolocationFetchIntervalDays'].toString());
        } catch (e) {
          // Keep default value
        }
      }

      if (jsonData.containsKey('eventPostUrl')) {
        try {
          tempSettings.eventPostUrl = jsonData['eventPostUrl']?.toString();
        } catch (e) {
          // Keep default value (null)
        }
      }

      return tempSettings;
    } catch (e) {
      Metriqus.errorLog('Error parsing MetriqusRemoteSettings: $e');
      return null;
    }
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'maxEventBatchCount': maxEventBatchCount,
      'maxEventStoreSeconds': maxEventStoreSeconds,
      'sendEventIntervalSeconds': sendEventIntervalSeconds,
      'sessionIntervalMinutes': sessionIntervalMinutes,
      'attributionCheckWindow': attributionCheckWindow,
      'geolocationFetchIntervalDays': geolocationFetchIntervalDays,
      'eventPostUrl': eventPostUrl,
    };
  }

  /// Create from JSON for deserialization - simplified to use parse method
  factory MetriqusRemoteSettings.fromJson(Map<String, dynamic> json) {
    return parse(json) ?? getInstance();
  }

  /// Reset singleton instance (for testing purposes)
  static void resetInstance() {
    _instance = null;
  }

  @override
  String toString() {
    return 'MetriqusRemoteSettings{maxEventBatchCount: $maxEventBatchCount, maxEventStoreSeconds: $maxEventStoreSeconds, sendEventIntervalSeconds: $sendEventIntervalSeconds, sessionIntervalMinutes: $sessionIntervalMinutes, attributionCheckWindow: $attributionCheckWindow, geolocationFetchIntervalDays: $geolocationFetchIntervalDays, eventPostUrl: $eventPostUrl}';
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'Metriqus.dart';

/// Remote settings configuration for Metriqus
class MetriqusRemoteSettings {
  int maxEventBatchCount = 10;
  int maxEventStoreSeconds = 2 * 60; // 2 minutes
  int sendEventIntervalSeconds = 2;
  int sessionIntervalMinutes = 30;
  int attributionCheckWindow = 20;
  int geolocationFetchIntervalDays = 2;
  String? eventPostUrl;

  MetriqusRemoteSettings();

  /// Parse remote settings from JSON string or Map
  static MetriqusRemoteSettings? parse(dynamic input) {
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
              'Input appears to be Dart Map toString(), using default settings');
          return MetriqusRemoteSettings(); // Return default settings
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
        if (jsonData == null) {
          return null;
        }
      } else {
        // Unsupported input type
        Metriqus.errorLog('MetriqusRemoteSettings: Unsupported input type');
        return null;
      }

      final remoteSettings = MetriqusRemoteSettings();

      try {
        remoteSettings.maxEventBatchCount =
            int.parse(jsonData['maxEventBatchCount']?.toString() ?? '10');
      } catch (e) {
        // Keep default value
      }

      try {
        remoteSettings.maxEventStoreSeconds =
            int.parse(jsonData['maxEventStoreSeconds']?.toString() ?? '120');
      } catch (e) {
        // Keep default value
      }

      try {
        remoteSettings.sendEventIntervalSeconds =
            int.parse(jsonData['sendEventIntervalSeconds']?.toString() ?? '2');
      } catch (e) {
        // Keep default value
      }

      try {
        remoteSettings.sessionIntervalMinutes =
            int.parse(jsonData['sessionIntervalMinutes']?.toString() ?? '30');
      } catch (e) {
        // Keep default value
      }

      try {
        remoteSettings.attributionCheckWindow =
            int.parse(jsonData['attributionCheckWindow']?.toString() ?? '20');
      } catch (e) {
        // Keep default value
      }

      try {
        remoteSettings.geolocationFetchIntervalDays = int.parse(
            jsonData['geolocationFetchIntervalDays']?.toString() ?? '2');
      } catch (e) {
        // Keep default value
      }

      try {
        remoteSettings.eventPostUrl = jsonData['eventPostUrl']?.toString();
      } catch (e) {
        // Keep default value (null)
      }

      return remoteSettings;
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

  /// Create from JSON for deserialization
  factory MetriqusRemoteSettings.fromJson(Map<String, dynamic> json) {
    final settings = MetriqusRemoteSettings();
    settings.maxEventBatchCount = json['maxEventBatchCount'] ?? 10;
    settings.maxEventStoreSeconds = json['maxEventStoreSeconds'] ?? 120;
    settings.sendEventIntervalSeconds = json['sendEventIntervalSeconds'] ?? 2;
    settings.sessionIntervalMinutes = json['sessionIntervalMinutes'] ?? 30;
    settings.attributionCheckWindow = json['attributionCheckWindow'] ?? 20;
    settings.geolocationFetchIntervalDays =
        json['geolocationFetchIntervalDays'] ?? 2;
    settings.eventPostUrl = json['eventPostUrl'];
    return settings;
  }

  @override
  String toString() {
    return 'MetriqusRemoteSettings{maxEventBatchCount: $maxEventBatchCount, maxEventStoreSeconds: $maxEventStoreSeconds, sendEventIntervalSeconds: $sendEventIntervalSeconds, sessionIntervalMinutes: $sessionIntervalMinutes, attributionCheckWindow: $attributionCheckWindow, geolocationFetchIntervalDays: $geolocationFetchIntervalDays, eventPostUrl: $eventPostUrl}';
  }
}

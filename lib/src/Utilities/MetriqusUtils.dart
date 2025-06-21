import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Utility functions for Metriqus SDK
class MetriqusUtils {
  static const String keySource = "utm_source";
  static const String keyMedium = "utm_medium";
  static const String keyCampaign = "utm_campaign";
  static const String keyTerm = "utm_term";
  static const String keyContent = "utm_content";

  /// Convert nullable bool to int (-1 for null, 1 for true, 0 for false)
  static int convertBool(bool? value) {
    if (value == null) {
      return -1;
    }
    return value ? 1 : 0;
  }

  /// Convert nullable double to double (-1 for null)
  static double convertDouble(double? value) {
    return value ?? -1.0;
  }

  /// Convert nullable int to int (-1 for null)
  static int convertInt(int? value) {
    return value ?? -1;
  }

  /// Convert nullable int to int (-1 for null) - for long values
  static int convertLong(int? value) {
    return value ?? -1;
  }

  /// Try to get value from map
  static String? tryGetValue(Map<String, String> dictionary, String key) {
    String? value = dictionary[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  /// Parses and sanitizes query string parameters
  static Map<String, String> parseAndSanitize(String queryString) {
    Map<String, String> sanitizedParameters = {};

    if (queryString.trim().isEmpty) {
      return sanitizedParameters;
    }

    // Ensure the query string starts with '?' if it doesn't already
    if (!queryString.startsWith("?")) {
      queryString = "?" + queryString;
    }

    try {
      Uri uri = Uri.parse("http://dummy$queryString");
      uri.queryParameters.forEach((key, value) {
        if (key.isNotEmpty) {
          sanitizedParameters[key] = value;
        }
      });
    } catch (e) {
      // If parsing fails, try manual parsing
      String query =
          queryString.startsWith('?') ? queryString.substring(1) : queryString;
      List<String> parameters = query.split('&');

      for (String param in parameters) {
        List<String> keyValue = param.split('=');
        if (keyValue.length == 2) {
          String key = Uri.decodeComponent(keyValue[0]).trim();
          String value = Uri.decodeComponent(keyValue[1]).trim();

          if (key.isNotEmpty) {
            sanitizedParameters[key] = value;
          }
        }
      }
    }

    return sanitizedParameters;
  }

  /// Get UTC start time (Unix epoch)
  static DateTime getUtcStartTime() {
    return DateTime.utc(1970, 1, 1, 0, 0, 0);
  }

  /// Convert DateTime to ISO string
  static String convertDateToString(DateTime date) {
    DateTime utcDate = date.toUtc();
    return utcDate.toIso8601String();
  }

  /// Parse date string to DateTime
  static DateTime parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.utc(1970, 1, 1, 0, 0, 0);
    }
  }

  /// Convert DateTime to Unix timestamp
  static int dateToTimestamp(DateTime date) {
    return date.millisecondsSinceEpoch ~/ 1000;
  }

  /// Get current UTC timestamp in seconds
  /// This is the centralized timestamp function that should be used throughout the SDK
  static int getCurrentUtcTimestampSeconds() {
    return DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  }

  /// Convert DateTime to UTC timestamp in seconds
  static int dateTimeToUtcTimestampSeconds(DateTime dateTime) {
    return dateTime.toUtc().millisecondsSinceEpoch ~/ 1000;
  }

  /// Convert timestamp in seconds to DateTime
  static DateTime timestampSecondsToDateTime(int timestampSeconds) {
    return DateTime.fromMillisecondsSinceEpoch(
      timestampSeconds * 1000,
      isUtc: true,
    );
  }

  /// Generate a unique session ID
  static String generateSessionId() {
    final timestamp = getCurrentUtcTimestampSeconds();
    final random = (timestamp.hashCode % 100000).toString().padLeft(5, '0');
    return "session_${timestamp}_$random";
  }

  /// Validate session ID format
  static bool isValidSessionId(String sessionId) {
    if (sessionId.isEmpty) return false;

    // Check if it matches our format: session_timestamp_random
    final pattern = RegExp(r'^session_\d+_\d{5}$');
    return pattern.hasMatch(sessionId);
  }

  /// Extract timestamp from session ID
  static DateTime? getTimestampFromSessionId(String sessionId) {
    try {
      if (!isValidSessionId(sessionId)) return null;

      final parts = sessionId.split('_');
      if (parts.length >= 2) {
        final timestampSeconds = int.parse(parts[1]);
        return timestampSecondsToDateTime(timestampSeconds);
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }

  /// Check if current platform is iOS
  static bool get isIOS {
    try {
      return defaultTargetPlatform == TargetPlatform.iOS;
    } catch (e) {
      // Fallback: assume iOS if we can't determine
      return false;
    }
  }

  /// Check if current platform is Android
  static bool get isAndroid {
    try {
      return defaultTargetPlatform == TargetPlatform.android;
    } catch (e) {
      // Fallback: assume Android if we can't determine
      return false;
    }
  }
}

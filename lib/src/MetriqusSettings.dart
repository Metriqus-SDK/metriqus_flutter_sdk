import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'Metriqus.dart';

/// Environment enumeration for Metriqus
enum Environment { sandbox, production }

/// Log level enumeration for Metriqus logging
enum LogLevel {
  noLog, // No logging
  errorsOnly, // Only error logs
  debug, // Error and info logs
  verbose, // All logs including debug
}

/// Settings configuration for Metriqus SDK
class MetriqusSettings {
  final String clientKey;
  final String clientSecret;
  final Environment environment;
  final LogLevel logLevel;
  final bool iOSUserTrackingDisabled;

  const MetriqusSettings({
    required this.clientKey,
    required this.clientSecret,
    this.environment = Environment.production,
    this.logLevel = LogLevel.errorsOnly,
    this.iOSUserTrackingDisabled = false,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'clientKey': clientKey,
      'clientSecret': clientSecret,
      'environment': environment.name,
      'logLevel': logLevel.name,
    };
  }

  /// Create from JSON
  factory MetriqusSettings.fromJson(Map<String, dynamic> json) {
    return MetriqusSettings(
      clientKey: json['clientKey'] ?? '',
      clientSecret: json['clientSecret'] ?? '',
      environment: Environment.values.firstWhere(
        (e) => e.name == json['environment'],
        orElse: () => Environment.production,
      ),
      logLevel: LogLevel.values.firstWhere(
        (e) => e.name == json['logLevel'],
        orElse: () => LogLevel.errorsOnly,
      ),
    );
  }

  /// Copy with new values
  MetriqusSettings copyWith({
    String? clientKey,
    String? clientSecret,
    Environment? environment,
    LogLevel? logLevel,
  }) {
    return MetriqusSettings(
      clientKey: clientKey ?? this.clientKey,
      clientSecret: clientSecret ?? this.clientSecret,
      environment: environment ?? this.environment,
      logLevel: logLevel ?? this.logLevel,
    );
  }

  /// Save settings to SharedPreferences
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(toJson());
      await prefs.setString('metriqus_settings', jsonString);
      Metriqus.verboseLog('Metriqus settings saved to SharedPreferences');
    } catch (e) {
      Metriqus.errorLog('Error saving Metriqus settings: $e');
    }
  }

  /// Load settings from SharedPreferences
  static Future<MetriqusSettings?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('metriqus_settings');
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        Metriqus.verboseLog('Metriqus settings loaded from SharedPreferences');
        return MetriqusSettings.fromJson(json);
      }
    } catch (e) {
      Metriqus.errorLog('Error loading Metriqus settings: $e');
    }
    return null;
  }

  /// Clear settings from SharedPreferences
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('metriqus_settings');
      Metriqus.verboseLog('Metriqus settings cleared from SharedPreferences');
    } catch (e) {
      Metriqus.errorLog('Error clearing Metriqus settings: $e');
    }
  }

  /// Check if settings exist in SharedPreferences
  static Future<bool> exists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('metriqus_settings');
    } catch (e) {
      Metriqus.errorLog('Error checking Metriqus settings: $e');
      return false;
    }
  }

  @override
  String toString() {
    return 'MetriqusSettings(clientKey: $clientKey, environment: ${environment.name}, logLevel: ${logLevel.name})';
  }
}

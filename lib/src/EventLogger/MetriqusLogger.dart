import 'package:flutter/foundation.dart';
import '../Storage/IStorage.dart';
import '../Utilities/MetriqusUtils.dart';
import 'Event.dart';
import 'EventQueueController.dart';
import 'IEventQueueController.dart';
import 'Parameters/TypedParameter.dart';
import '../Package/PackageBuilder.dart' as PackageBuilder;
import '../Package/PackageModels/AppInfoPackage.dart';
import '../Metriqus.dart';
import '../MetriqusSettings.dart';

/// Static logger class for Metriqus events
class MetriqusLogger {
  static IEventQueueController? _eventQueue;

  /// Initialize the logger with storage
  static void init(IStorage storage) {
    _eventQueue ??= EventQueueController(storage);
  }

  /// Log event with string parameter
  static void logEvent(
    String name,
    String parameterName,
    String parameterValue,
  ) {
    _eventQueue?.addEvent(
      Event.withParameters(name, [
        TypedParameter.string(parameterName, parameterValue),
      ]),
    );
  }

  /// Log event with double parameter
  static void logEventDouble(
    String name,
    String parameterName,
    double parameterValue,
  ) {
    _eventQueue?.addEvent(
      Event.withParameters(name, [
        TypedParameter.double(parameterName, parameterValue),
      ]),
    );
  }

  /// Log event with long parameter
  static void logEventLong(
    String name,
    String parameterName,
    int parameterValue,
  ) {
    _eventQueue?.addEvent(
      Event.withParameters(name, [
        TypedParameter.long(parameterName, parameterValue),
      ]),
    );
  }

  /// Log event with int parameter
  static void logEventInt(
    String name,
    String parameterName,
    int parameterValue,
  ) {
    _eventQueue?.addEvent(
      Event.withParameters(name, [
        TypedParameter.int(parameterName, parameterValue),
      ]),
    );
  }

  /// Log event with bool parameter
  static void logEventBool(
    String name,
    String parameterName,
    bool parameterValue,
  ) {
    _eventQueue?.addEvent(
      Event.withParameters(name, [
        TypedParameter.bool(parameterName, parameterValue),
      ]),
    );
  }

  /// Log simple event without parameters
  static void logSimpleEvent(String name) {
    _eventQueue?.addEvent(Event(name));
  }

  /// Log event with multiple parameters
  static void logEventWithParameters(
    String name,
    List<TypedParameter> parameters,
  ) {
    _eventQueue?.addEvent(Event.withParameters(name, parameters));
  }

  /// Log event from package
  static void logEventFromPackage(
    Package package, {
    bool sendImmediately = false,
  }) {
    _eventQueue?.addEvent(
      Event.fromPackage(package),
      sendImmediately: sendImmediately,
    );
  }

  /// Log event with Package object (overloaded method)
  static void logPackage(
    PackageBuilder.Package package, {
    bool sendImmediately = false,
  }) {
    if (_eventQueue == null) {
      Metriqus.errorLog(
        "🔧 ERROR: EventQueue is NULL! MetriqusLogger not initialized properly!",
      );
      return;
    }

    // Log detailed package info ONLY in verbose mode BEFORE converting to event
    if (Metriqus.logLevel == LogLevel.verbose) {
      try {
        final summary = _createPackageSummary(package);
        Metriqus.verboseLog("📦 PACKAGE SUMMARY:\n$summary");
      } catch (e) {
        Metriqus.errorLog("Package detail log error: $e");
      }
    }

    // Convert PackageBuilder.Package to Event for compatibility
    final event = Event.full(
      eventName: package.eventName ?? 'unknown',
      eventId: package.eventId,
      sessionId: package.sessionId,
      clientSdk: package.clientSdk,
      isFirstLaunch: package.isFirstLaunch ?? false,
      eventTimestamp: package.eventTimestamp ??
          MetriqusUtils.getCurrentUtcTimestampSeconds(),
      userId: package.userId,
      userFirstTouchTimestamp: package.userFirstTouchTimestamp ?? 0,
      environment: package.environment ?? 'production',
    );

    // Copy additional data
    event.device = package.device;
    event.geolocation = package.geolocation;
    // Convert PackageBuilder AppInfoPackage to Event AppInfoPackage
    if (package.appInfo != null) {
      event.appInfo = AppInfoPackage.fromJson(package.appInfo!.toJson());
    }
    event.publisher = package.publisher;
    event.item = package.item;
    event.attribution = package.attribution;
    event.parameters = package.parameters;
    event.userAttributes = package.userAttributes;
    event.eventParams = package.eventParams;

    _eventQueue?.addEvent(event, sendImmediately: sendImmediately);
  }

  /// Creates a compact summary of package for logging
  static String _createPackageSummary(PackageBuilder.Package package) {
    final buffer = StringBuffer();

    // Basic info
    buffer.writeln("🎯 Event: ${package.eventName ?? 'unknown'}");
    buffer.writeln("🆔 ID: ${package.eventId ?? 'null'}");
    buffer.writeln("👤 User: ${package.userId ?? 'null'}");
    buffer.writeln("📱 Session: ${package.sessionId ?? 'null'}");
    buffer.writeln("🌍 Environment: ${package.environment ?? 'null'}");

    // Device info
    if (package.device != null && package.device!.isNotEmpty) {
      buffer.writeln("📱 Device:");
      for (final param in package.device!) {
        buffer.writeln("   ${param.name}: ${param.value}");
      }
    } else {
      buffer.writeln("📱 Device: empty");
    }

    // Geolocation
    if (package.geolocation != null && package.geolocation!.isNotEmpty) {
      buffer.writeln("🌍 Geolocation:");
      for (final param in package.geolocation!) {
        buffer.writeln("   ${param.name}: ${param.value}");
      }
    } else {
      buffer.writeln("🌍 Geolocation: empty");
    }

    // App info
    if (package.appInfo != null) {
      buffer.writeln(
        "📦 App: ${package.appInfo!.packageName} v${package.appInfo!.appVersion}",
      );
    } else {
      buffer.writeln("📦 App: null");
    }

    // Parameters
    if (package.parameters != null && package.parameters!.isNotEmpty) {
      buffer.writeln("⚙️ Parameters (${package.parameters!.length}):");
      for (final param in package.parameters!) {
        buffer.writeln("   ${param.name}: ${param.value}");
      }
    } else {
      buffer.writeln("⚙️ Parameters: empty");
    }

    // User attributes
    if (package.userAttributes != null && package.userAttributes!.isNotEmpty) {
      buffer.writeln("👤 User Attributes (${package.userAttributes!.length}):");
      for (final attr in package.userAttributes!) {
        buffer.writeln("   ${attr.name}: ${attr.value}");
      }
    } else {
      buffer.writeln("👤 User Attributes: empty");
    }

    // Attribution
    if (package.attribution != null && package.attribution!.isNotEmpty) {
      buffer.writeln("🎯 Attribution:");
      for (final platform in package.attribution!.entries) {
        buffer.writeln("   Platform: ${platform.key}");
        for (final attr in platform.value) {
          if (attr.name == "params" && attr.value is List) {
            buffer.writeln(
                "   ${attr.name}: [${(attr.value as List).length} items]");
            for (final item in (attr.value as List)) {
              if (item is Map &&
                  item.containsKey('key') &&
                  item.containsKey('value')) {
                final key = item['key'];
                final value = item['value'];
                buffer.writeln("     - $key: $value");
              }
            }
          } else {
            buffer.writeln("   ${attr.name}: ${attr.value}");
          }
        }
      }
    } else {
      buffer.writeln(
          "🎯 Attribution: ${package.attribution == null ? 'null' : 'empty'}");
    }

    return buffer.toString().trim();
  }

  /// Formats JSON for readable logging
  static String _formatJsonForLog(dynamic json, int indent) {
    final indentStr = '  ' * indent;
    final nextIndentStr = '  ' * (indent + 1);

    if (json is Map<String, dynamic>) {
      final buffer = StringBuffer();
      buffer.writeln('{');

      final entries = json.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer.write('$nextIndentStr"${entry.key}": ');

        if (entry.value == null) {
          buffer.write('null');
        } else if (entry.value is String) {
          buffer.write('"${entry.value}"');
        } else if (entry.value is num || entry.value is bool) {
          buffer.write('${entry.value}');
        } else {
          buffer.write(_formatJsonForLog(entry.value, indent + 1));
        }

        if (i < entries.length - 1) {
          buffer.write(',');
        }
        buffer.writeln();
      }

      buffer.write('$indentStr}');
      return buffer.toString();
    } else if (json is List) {
      if (json.isEmpty) return '[]';

      final buffer = StringBuffer();
      buffer.writeln('[');

      for (int i = 0; i < json.length; i++) {
        buffer.write('$nextIndentStr');
        buffer.write(_formatJsonForLog(json[i], indent + 1));

        if (i < json.length - 1) {
          buffer.write(',');
        }
        buffer.writeln();
      }

      buffer.write('$indentStr]');
      return buffer.toString();
    } else {
      return json.toString();
    }
  }

  /// Dispose the logger and its resources
  static void dispose() {
    _eventQueue?.dispose();
    _eventQueue = null;
    Metriqus.verboseLog("MetriqusLogger disposed.");
  }
}

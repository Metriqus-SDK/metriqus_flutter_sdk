import 'dart:convert';
import '../Metriqus.dart';

/// Simple JSON wrapper for Flutter using dart:convert
/// This replaces the complex SimpleJSON C# library with Flutter's built-in JSON support
class JSON {
  /// Parse JSON String to dynamic object
  static dynamic parse(String jsonString) {
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      Metriqus.errorLog('JSON Parse Error: $e');
      return null;
    }
  }

  /// Convert object to JSON string
  static String stringify(dynamic object) {
    try {
      return jsonEncode(object);
    } catch (e) {
      Metriqus.errorLog('JSON Stringify Error: $e');
      return '';
    }
  }
}

/// JSONNode equivalent for compatibility
class JSONNode {
  dynamic _data;

  JSONNode(this._data);

  /// Get the raw data
  dynamic get data => _data;

  /// Get value as string
  String get value => _data?.toString() ?? '';

  /// Get value as int
  int get asInt => int.tryParse(value) ?? 0;

  /// Get value as double
  double get asDouble => double.tryParse(value) ?? 0.0;

  /// Get value as bool
  bool get asBool {
    if (_data is bool) return _data;
    final str = value.toLowerCase();
    return str == 'true' || str == '1';
  }

  /// Array access
  JSONNode operator [](dynamic key) {
    if (_data is Map && key is String) {
      return JSONNode(_data[key]);
    } else if (_data is List && key is int) {
      return JSONNode(_data[key]);
    }
    return JSONNode(null);
  }

  /// Check if value exists
  bool get exists => _data != null;

  /// Get count of items (for arrays/objects)
  int get count {
    if (_data is Map) return (_data as Map).length;
    if (_data is List) return (_data as List).length;
    return 0;
  }

  @override
  String toString() => value;

  /// Static parse method for compatibility
  static JSONNode parse(String jsonString) {
    return JSONNode(JSON.parse(jsonString));
  }
}

/// Utility class for getting JSON String values
class MetriqusJSON {
  /// Get String value from JSON node
  static String getJsonString(dynamic jsonNode, String key) {
    if (jsonNode is Map) {
      return jsonNode[key]?.toString() ?? '';
    }
    return '';
  }

  /// Get int value from JSON node
  static int getJsonInt(dynamic jsonNode, String key) {
    if (jsonNode is Map) {
      final value = jsonNode[key];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// Get double value from JSON node
  static double getJsonDouble(dynamic jsonNode, String key) {
    if (jsonNode is Map) {
      final value = jsonNode[key];
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Get bool value from JSON node
  static bool getJsonBool(dynamic jsonNode, String key) {
    if (jsonNode is Map) {
      final value = jsonNode[key];
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
    }
    return false;
  }
}

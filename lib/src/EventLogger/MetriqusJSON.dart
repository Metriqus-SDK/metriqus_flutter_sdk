import 'dart:convert';
import '../Metriqus.dart';
import '../ThirdParty/SimpleJSON.dart';
import 'Parameters/TypedParameter.dart';

/// Custom JSON serialization utility inspired by Unity SDK
/// Handles proper encoding without unwanted escaping
class MetriqusJSON {
  /// Get string value from JSON node
  static String? getJsonString(JSONNode? node, String key) {
    if (node == null) return null;

    var nodeValue = node[key];
    if (nodeValue == null || nodeValue.value.isEmpty) return null;

    return nodeValue.value;
  }

  /// Get int value from JSON node
  static int getJsonInt(JSONNode? node, String key) {
    if (node == null) return 0;

    var nodeValue = node[key];
    if (nodeValue == null || nodeValue.value.isEmpty) return 0;

    return parseInt(nodeValue.value);
  }

  /// Get double value from JSON node
  static double getJsonDouble(JSONNode? node, String key) {
    if (node == null) return 0.0;

    var nodeValue = node[key];
    if (nodeValue == null || nodeValue.value.isEmpty) return 0.0;

    return parseDouble(nodeValue.value);
  }

  /// Get bool value from JSON node
  static bool getJsonBool(JSONNode? node, String key) {
    if (node == null) return false;

    var nodeValue = node[key];
    if (nodeValue == null || nodeValue.value.isEmpty) return false;

    return parseBool(nodeValue.value);
  }

  // PARSE STRING TO PRIMITIVE
  static int parseInt(String? value) {
    if (value == null || value.isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }

  static double parseDouble(String? value) {
    if (value == null || value.isEmpty) return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  static bool parseBool(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.toLowerCase() == 'true';
  }

  /// Custom JSON serialization that preserves Unicode characters
  /// and prevents unwanted quote escaping
  static String serializeValue(dynamic value) {
    if (value == null) return 'null';

    if (value is String) {
      // Properly escape only necessary characters
      String escaped = value
          .replaceAll('\\', '\\\\') // Escape backslashes first
          // .replaceAll('"', '\\"') // Escape quotes
          .replaceAll('\n', '\\n') // Escape newlines
          .replaceAll('\r', '\\r') // Escape carriage returns
          .replaceAll('\t', '\\t'); // Escape tabs
      return '"$escaped"';
    }

    if (value is TypedParameter) {
      return value.serialize();
    }

    if (value is bool) {
      return value.toString().toLowerCase();
    }

    if (value is num) {
      return value.toString();
    }

    if (value is Map<String, dynamic>) {
      return serializeDictionary(value);
    }

    if (value is List) {
      return serializeArray(value);
    }

    // Default: convert to string and quote
    return serializeValue(value.toString());
  }

  /// Serialize dictionary/map to JSON
  static String serializeDictionary(Map<String, dynamic> dictionary) {
    if (dictionary.isEmpty) return '{}';

    List<String> pairs = [];

    dictionary.forEach((key, value) {
      String serializedKey = serializeValue(key);
      String serializedValue = serializeValue(value);
      pairs.add('$serializedKey:$serializedValue');
    });

    return '{${pairs.join(',')}}';
  }

  /// Serialize array/list to JSON
  static String serializeArray(List array) {
    if (array.isEmpty) return '[]';

    List<String> serializedItems = [];

    for (var item in array) {
      serializedItems.add(serializeValue(item));
    }

    return '[${serializedItems.join(',')}]';
  }

  /// Main serialization method for complex objects
  /// This is the primary method to use for encoding data
  static String encode(dynamic data) {
    try {
      String result = serializeValue(data);

      // Log encoding details for debugging
      Metriqus.verboseLog("🔧 [METRIQUS_JSON] Custom encoding completed");

      // Check for problematic patterns
      bool hasUnicodeEscapes = result.contains('\\u');
      if (hasUnicodeEscapes) {
        Metriqus.infoLog("⚠️ [METRIQUS_JSON] Found Unicode escapes - fixing");
        result = _fixUnicodeEscapes(result);
        Metriqus.verboseLog("✅ [METRIQUS_JSON] Unicode escapes fixed");
      }

      return result;
    } catch (e) {
      Metriqus.errorLog("Custom JSON encoding failed: $e");
      // Fallback to standard encoding
      return jsonEncode(data);
    }
  }

  /// Fix Unicode escape sequences back to actual Unicode characters
  static String _fixUnicodeEscapes(String json) {
    return json.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
      int codePoint = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(codePoint);
    });
  }

  /// Parse JSON to object (simplified version compatible with JSONNode)
  static dynamic parseValue(JSONNode jsonNode) {
    try {
      // Check if it's a Map (object)
      if (jsonNode.data is Map) {
        Map<String, dynamic> dict = {};
        Map<String, dynamic> mapData = jsonNode.data as Map<String, dynamic>;

        mapData.forEach((key, value) {
          dict[key] = parseValue(JSONNode(value));
        });

        return dict;
      }
      // Check if it's a List (array)
      else if (jsonNode.data is List) {
        List<dynamic> array = [];
        List<dynamic> listData = jsonNode.data as List<dynamic>;

        for (var item in listData) {
          array.add(parseValue(JSONNode(item)));
        }

        return array;
      }
      // Primitive value
      else {
        String value = jsonNode.value.trim();

        // Try to parse as different types
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
        if (value.toLowerCase() == 'null') return null;

        // Try numeric parsing
        int? intValue = int.tryParse(value);
        if (intValue != null) return intValue;

        double? doubleValue = double.tryParse(value);
        if (doubleValue != null) return doubleValue;

        // Return as string
        return value;
      }
    } catch (e) {
      Metriqus.errorLog("JSON parsing failed: $e");
      return null;
    }
  }
}

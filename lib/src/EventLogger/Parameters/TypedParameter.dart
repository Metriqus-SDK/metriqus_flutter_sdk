import 'dart:convert';
import '../../Metriqus.dart';

/// Typed parameter for storing strongly-typed values in events
class TypedParameter {
  final String name;
  final dynamic value;
  final String type;

  TypedParameter._({
    required this.name,
    required this.value,
    required this.type,
  });

  /// Create string parameter
  factory TypedParameter.string(String name, String value) {
    return TypedParameter._(name: name, value: value, type: 'string');
  }

  /// Create integer parameter
  factory TypedParameter.int(String name, int value) {
    return TypedParameter._(name: name, value: value, type: 'int');
  }

  /// Create long parameter (alias for int)
  factory TypedParameter.long(String name, int value) {
    return TypedParameter._(name: name, value: value, type: 'long');
  }

  /// Create double parameter
  factory TypedParameter.double(String name, double value) {
    return TypedParameter._(name: name, value: value, type: 'double');
  }

  /// Create boolean parameter
  factory TypedParameter.bool(String name, bool value) {
    return TypedParameter._(name: name, value: value, type: 'bool');
  }

  /// Create from JSON
  factory TypedParameter.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final type = json['type'] as String;
    final value = json['value'];

    switch (type) {
      case 'string':
        return TypedParameter.string(name, value as String);
      case 'int':
        return TypedParameter.int(name, value as int);
      case 'double':
        return TypedParameter.double(name, (value as num).toDouble());
      case 'bool':
        return TypedParameter.bool(name, value as bool);
      default:
        throw ArgumentError('Unknown parameter type: $type');
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'type': type,
    };
  }

  /// Serialize to JSON string
  String serialize() {
    return jsonEncode(toJson());
  }

  /// Deserialize from JSON string
  static TypedParameter? deserialize(String jsonString) {
    try {
      if (jsonString.isEmpty) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TypedParameter.fromJson(json);
    } catch (e) {
      Metriqus.errorLog('TypedParameter Deserialize Error: $e');
      return null;
    }
  }

  /// Get the value as string
  String get valueAsString {
    return value.toString();
  }

  /// Get the value as int (if possible)
  int? get valueAsInt {
    if (value is int) {
      return value as int;
    } else if (value is double) {
      return (value as double).round();
    } else if (value is String) {
      return int.tryParse(value as String);
    }
    return null;
  }

  /// Get the value as double (if possible)
  double? get valueAsDouble {
    if (value is double) {
      return value as double;
    } else if (value is int) {
      return (value as int).toDouble();
    } else if (value is String) {
      return double.tryParse(value as String);
    }
    return null;
  }

  /// Get the value as bool (if possible)
  bool? get valueAsBool {
    if (value is bool) {
      return value as bool;
    } else if (value is String) {
      final str = (value as String).toLowerCase();
      if (str == 'true') return true;
      if (str == 'false') return false;
    } else if (value is int) {
      return (value as int) != 0;
    }
    return null;
  }

  /// Check if this parameter is equal to another
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TypedParameter &&
        other.name == name &&
        other.value == value &&
        other.type == type;
  }

  @override
  int get hashCode => name.hashCode ^ value.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'TypedParameter(name: $name, value: $value, type: $type)';
  }

  /// Serialize a list of TypedParameters to JSON string
  static String serializeList(List<TypedParameter> parameters) {
    final jsonList = parameters.map((p) => p.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Deserialize a list of TypedParameters from JSON string or Map
  static List<TypedParameter> deserializeList(dynamic input) {
    try {
      List<dynamic> jsonList;

      if (input is String) {
        if (input.isEmpty) return [];
        jsonList = jsonDecode(input) as List<dynamic>;
      } else if (input is Map<String, dynamic>) {
        // Convert Map to List of TypedParameters
        final parameters = <TypedParameter>[];
        input.forEach((key, value) {
          if (value is String) {
            parameters.add(TypedParameter.string(key, value));
          } else if (value is int) {
            parameters.add(TypedParameter.int(key, value));
          } else if (value is double) {
            parameters.add(TypedParameter.double(key, value));
          } else if (value is bool) {
            parameters.add(TypedParameter.bool(key, value));
          }
        });
        return parameters;
      } else if (input is List) {
        jsonList = input;
      } else {
        return [];
      }

      final parameters = <TypedParameter>[];

      for (final json in jsonList) {
        if (json is Map<String, dynamic>) {
          try {
            final parameter = TypedParameter.fromJson(json);
            parameters.add(parameter);
          } catch (e) {
            // Skip invalid parameters
            continue;
          }
        }
      }

      return parameters;
    } catch (e) {
      Metriqus.errorLog('TypedParameter deserializeList Error: $e');
      return [];
    }
  }

  /// Convert list of parameters to simple Map (key:value format)
  static Map<String, dynamic> toSimpleMap(List<TypedParameter> parameters) {
    final Map<String, dynamic> result = {};
    for (final param in parameters) {
      result[param.name] = param.value;
    }
    return result;
  }
}

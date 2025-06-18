import 'dart:convert';
import '../ThirdParty/SimpleJSON.dart';

/// Response object for Metriqus API calls
class MetriqusResponseObject {
  final dynamic data;
  final int statusCode;
  final List<String> errorMessages;

  /// Check if the response is successful
  bool get isSuccess =>
      errorMessages.isEmpty && statusCode >= 200 && statusCode < 300;

  /// Get status string based on success
  String get status => isSuccess ? 'success' : 'error';

  MetriqusResponseObject({
    required this.data,
    required this.statusCode,
    required this.errorMessages,
  });

  /// Parse JSON response to MetriqusResponseObject
  static MetriqusResponseObject? parse(String? json) {
    if (json == null || json.isEmpty) return null;

    try {
      var jsonNode = JSONNode.parse(json);

      if (!jsonNode.exists) {
        return null;
      }

      int statusCode = 0;
      dynamic data;
      List<String> errors = [];

      try {
        var dataValue = jsonNode["data"];
        if (!dataValue.exists) {
          return null;
        }
        // If data is a Map, return the Map object directly
        if (dataValue.data is Map) {
          data = dataValue.data;
        } else {
          data = dataValue.value;
        }
      } catch (e) {
        return null;
      }

      try {
        statusCode = MetriqusJSON.getJsonInt(jsonNode.data, "statusCode");
      } catch (e) {
        return null;
      }

      try {
        var errorArray = jsonNode["errorMessages"];
        if (errorArray.exists && errorArray.data is List) {
          List<dynamic> errorList = errorArray.data;
          for (var item in errorList) {
            if (item != null) {
              errors.add(item.toString());
            }
          }
        }
      } catch (e) {
        // Errors array is optional, continue without it
      }

      return MetriqusResponseObject(
        data: data,
        statusCode: statusCode,
        errorMessages: errors,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create from JSON map
  static MetriqusResponseObject? fromJson(Map<String, dynamic> json) {
    try {
      return MetriqusResponseObject(
        data: json['data'],
        statusCode: json['statusCode'] ?? 200,
        errorMessages:
            (json['errorMessages'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    } catch (e) {
      return null;
    }
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'statusCode': statusCode,
      'errorMessages': errorMessages,
    };
  }
}

import 'dart:convert';
import '../ThirdParty/SimpleJSON.dart';
import 'Parameters/TypedParameter.dart';
import 'Parameters/DynamicParameter.dart';
import '../Package/PackageModels/AppInfoPackage.dart';
import '../Utilities/MetriqusEnvironment.dart';
import '../Metriqus.dart';

/// Metriqus Logger Event
class Event {
  String eventName;
  String? eventId;
  String? sessionId;
  String? clientSdk;
  bool isFirstLaunch = false;
  int eventTimestamp = 0;
  String? userId;
  int userFirstTouchTimestamp = 0;
  String? environment;

  List<TypedParameter>? parameters;
  List<DynamicParameter>? userAttributes;
  List<DynamicParameter>? device;
  List<DynamicParameter>? geolocation;
  AppInfoPackage? appInfo;
  List<DynamicParameter>? item;
  List<DynamicParameter>? publisher;
  Map<String, List<DynamicParameter>>? attribution;
  List<DynamicParameter>? eventParams;

  String get eventNameGetter => eventName;
  List<TypedParameter>? get parametersGetter => parameters;

  Event(this.eventName);

  Event.withParameters(this.eventName, this.parameters);

  Event.fromPackage(Package package)
      : eventName = package.eventName,
        eventId = package.eventId,
        sessionId = package.sessionId,
        eventTimestamp = package.eventTimestamp,
        clientSdk = package.clientSdk,
        isFirstLaunch = package.isFirstLaunch,
        userId = package.userId,
        userFirstTouchTimestamp = package.userFirstTouchTimestamp,
        environment = package.environment.toLowercaseString(),
        device = package.device,
        geolocation = package.geolocation,
        appInfo = package.appInfo,
        publisher = package.publisher,
        item = package.item,
        attribution = package.attribution,
        parameters = package.parameters,
        userAttributes = package.userAttributes,
        eventParams = package.eventParams;

  Event.full({
    required this.eventName,
    this.eventId,
    this.sessionId,
    this.eventTimestamp = 0,
    this.clientSdk,
    this.isFirstLaunch = false,
    this.userId,
    this.userFirstTouchTimestamp = 0,
    this.environment,
    this.parameters,
    this.userAttributes,
    this.device,
    this.geolocation,
    this.appInfo,
    this.item,
    this.publisher,
    this.attribution,
    this.eventParams,
  });

  /// Convert event to Map
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> eventMap = {
      'event_name': eventName,
      'event_id': eventId,
      'session_id': sessionId,
      'client_sdk': clientSdk,
      'is_first_launch': isFirstLaunch,
      'event_timestamp': eventTimestamp,
      'user_id': userId,
      'user_first_touch_timestamp': userFirstTouchTimestamp,
      'environment': environment,
    };

    // Add device info
    if (device != null) {
      eventMap['device'] = _dynamicParametersToMap(device!);
    }

    // Add geolocation
    if (geolocation != null) {
      eventMap['geo'] = _dynamicParametersToMap(geolocation!);
    }

    // Add item info
    if (item != null) {
      eventMap['item'] = _dynamicParametersToMap(item!);
    }

    // Add publisher info
    if (publisher != null) {
      eventMap['publisher'] = _dynamicParametersToMap(publisher!);
    }

    // Add app info
    if (appInfo != null) {
      eventMap['app_info'] = appInfo!.toJson();
    }

    // Add attribution
    if (attribution != null) {
      final attributionMap = <String, Map<String, dynamic>>{};
      attribution!.forEach((key, value) {
        attributionMap[key] = _dynamicParametersToMap(value);
      });
      eventMap['attribution'] = attributionMap;
    }

    // Add event parameters
    if (parameters != null) {
      eventMap['event_params'] = TypedParameter.toSimpleMap(parameters!);
    }

    // Add user attributes as array
    if (userAttributes != null && userAttributes!.isNotEmpty) {
      // Check if this contains structured user properties data
      final firstParam = userAttributes!.first;
      if (firstParam.name == "user_properties_data" &&
          firstParam.value is List) {
        // Extract the structured array directly
        eventMap['user_properties'] = firstParam.value;
      } else {
        // Fallback to standard parameter mapping
        eventMap['user_properties'] = _dynamicParametersToMap(userAttributes!);
      }
    }

    // Add custom event parameters as array
    if (eventParams != null && eventParams!.isNotEmpty) {
      // Check if this contains structured event parameter data
      final firstParam = eventParams!.first;
      if (firstParam.name == "event_parameters_data" &&
          firstParam.value is List) {
        // Extract the structured array directly
        eventMap['event_params'] = firstParam.value;
      } else {
        // Fallback to standard parameter mapping
        eventMap['event_params'] = _dynamicParametersToMap(eventParams!);
      }
    }

    return eventMap;
  }

  /// Convert event to JSON string
  String toJson() {
    return jsonEncode(toMap());
  }

  /// Convert dynamic parameters to map
  Map<String, dynamic> _dynamicParametersToMap(List<DynamicParameter> params) {
    final Map<String, dynamic> result = {};
    for (final param in params) {
      result[param.name] = param.value;
    }
    return result;
  }

  /// Parse JSON to Event
  static Event? parseJson(JSONNode jsonNode) {
    if (!jsonNode.exists) return null;

    try {
      final data = jsonNode.data as Map<String, dynamic>;

      final event = Event.full(
        eventName: data['event_name'] ?? '',
        eventId: data['event_id'],
        sessionId: data['session_id'],
        clientSdk: data['client_sdk'],
        isFirstLaunch: data['is_first_launch'] ?? false,
        eventTimestamp: data['event_timestamp'] ?? 0,
        userId: data['user_id'],
        userFirstTouchTimestamp: data['user_first_touch_timestamp'] ?? 0,
        environment: data['environment'],
      );

      // Parse device info
      if (data['device'] != null) {
        event.device = _parseMapToDynamicParameters(data['device']);
      }

      // Parse geolocation
      if (data['geo'] != null) {
        event.geolocation = _parseMapToDynamicParameters(data['geo']);
      }

      // Parse item info
      if (data['item'] != null) {
        event.item = _parseMapToDynamicParameters(data['item']);
      }

      // Parse publisher info
      if (data['publisher'] != null) {
        event.publisher = _parseMapToDynamicParameters(data['publisher']);
      }

      // Parse app info
      if (data['app_info'] != null) {
        event.appInfo = AppInfoPackage.fromJson(data['app_info']);
      }

      // Parse attribution
      if (data['attribution'] != null) {
        final attributionData = data['attribution'] as Map<String, dynamic>;
        event.attribution = {};
        attributionData.forEach((key, value) {
          event.attribution![key] = _parseMapToDynamicParameters(value);
        });
      }

      // Parse event parameters
      if (data['event_params'] != null) {
        event.parameters = TypedParameter.deserializeList(data['event_params']);
      }

      // Parse user attributes
      if (data['user_properties'] != null) {
        // Since user_properties now comes as array format, convert to DynamicParameter
        if (data['user_properties'] is List) {
          event.userAttributes = [
            DynamicParameter("user_properties_data", data['user_properties'])
          ];
        } else {
          event.userAttributes =
              _parseMapToDynamicParameters(data['user_properties']);
        }
      }

      return event;
    } catch (e) {
      Metriqus.errorLog('Error parsing Event JSON: $e');
      return null;
    }
  }

  /// Parse map to dynamic parameters
  static List<DynamicParameter> _parseMapToDynamicParameters(
      Map<String, dynamic> map) {
    final List<DynamicParameter> result = [];
    map.forEach((key, value) {
      result.add(DynamicParameter(key, value));
    });
    return result;
  }

  @override
  String toString() {
    return 'Event(name: $eventName, id: $eventId, timestamp: $eventTimestamp)';
  }
}

/// Mock Package class for compatibility
class Package {
  final String eventName;
  final String? eventId;
  final String? sessionId;
  final int eventTimestamp;
  final String? clientSdk;
  final bool isFirstLaunch;
  final String? userId;
  final int userFirstTouchTimestamp;
  final MetriqusEnvironment environment;
  final List<DynamicParameter>? device;
  final List<DynamicParameter>? geolocation;
  final AppInfoPackage? appInfo;
  final List<DynamicParameter>? publisher;
  final List<DynamicParameter>? item;
  final Map<String, List<DynamicParameter>>? attribution;
  final List<TypedParameter>? parameters;
  final List<DynamicParameter>? userAttributes;
  final List<DynamicParameter>? eventParams;

  Package({
    required this.eventName,
    this.eventId,
    this.sessionId,
    this.eventTimestamp = 0,
    this.clientSdk,
    this.isFirstLaunch = false,
    this.userId,
    this.userFirstTouchTimestamp = 0,
    required this.environment,
    this.device,
    this.geolocation,
    this.appInfo,
    this.publisher,
    this.item,
    this.attribution,
    this.parameters,
    this.userAttributes,
    this.eventParams,
  });
}

// MetriqusEnvironment is imported from Utilities/MetriqusEnvironment.dart

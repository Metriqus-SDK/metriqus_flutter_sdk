import 'dart:io' show Platform;
import 'package:uuid/uuid.dart';
import '../MetriqusSettings.dart';
import '../Utilities/DeviceInfo.dart';
import '../Utilities/MetriqusUtils.dart';
import '../Metriqus.dart';
import '../EventModels/MetriqusInAppRevenue.dart';
import '../EventModels/Attribution/MetriqusAttribution.dart';
import '../EventModels/AdRevenue/MetriqusAdRevenue.dart';
import '../EventModels/CustomEvents/MetriqusCustomEvent.dart';
import '../EventLogger/Parameters/DynamicParameter.dart';
import '../EventLogger/Parameters/TypedParameter.dart';
import 'PackageModels/AppInfoPackage.dart';

/// Builds packages for different types of events
class PackageBuilder {
  DeviceInfo? deviceInfo;
  DateTime? createdAt;
  MetriqusSettings? metriqusSettings;

  /// Constructor
  PackageBuilder(MetriqusSettings metriqusSettings, DeviceInfo deviceInfo) {
    this.metriqusSettings = metriqusSettings;
    this.deviceInfo = deviceInfo;
    this.createdAt = MetriqusUtils.timestampSecondsToDateTime(
      MetriqusUtils.getCurrentUtcTimestampSeconds(),
    );
  }

  /// Builds session start package
  Future<Package> buildSessionStartPackage() async {
    final package = _getDefaultPackage();
    await _addDefaultParameters(package);
    package.setKey("session_start");
    return package;
  }

  /// Builds session beat package
  Future<Package> buildSessionBeatPackage() async {
    final package = _getDefaultPackage();
    await _addDefaultParameters(package);
    package.setKey("session_beat");
    return package;
  }

  /// Builds IAP event package
  Future<Package> buildIAPEventPackage(
    MetriqusInAppRevenue metriqusEvent,
  ) async {
    final package = _getDefaultPackage();
    await _setIAPEventParameters(package, metriqusEvent);
    package.setKey("iap_revenue");
    return package;
  }

  /// Builds attribution package
  Future<Package> buildAttributionPackage(
    MetriqusAttribution metriqusAttribution,
  ) async {
    final package = _getDefaultPackage();
    await _setAttributionParameters(package, metriqusAttribution);
    package.setKey("attribution");
    return package;
  }

  /// Builds ad revenue event package
  Future<Package> buildAdRevenueEventPackage(
    MetriqusAdRevenue adRevenue,
  ) async {
    final package = _getDefaultPackage();
    await _setAdRevenueEventParameters(package, adRevenue);
    package.setKey("ad_revenue");
    return package;
  }

  /// Builds custom event package
  Future<Package> buildCustomEventPackage(
    MetriqusCustomEvent customEvent,
  ) async {
    final package = _getDefaultPackage();
    await _setCustomEventParameters(package, customEvent);
    package.setKey(customEvent.key ?? "custom_event");
    return package;
  }

  /// Creates default package
  Package _getDefaultPackage() {
    return Package();
  }

  /// Sets IAP event parameters
  Future<void> _setIAPEventParameters(
    Package package,
    MetriqusInAppRevenue event,
  ) async {
    await _addDefaultParameters(package);

    final iapParameters = <DynamicParameter>[];

    // Always add all parameters to ensure complete data transmission
    if (event.revenue != null) {
      _addFloat(iapParameters, "revenue", (event.revenue! * 1000000));
    }

    // Basic parameters - add all of them
    _addStringAlways(iapParameters, "currency", event.currency);
    _addStringAlways(iapParameters, "product_id", event.productId);
    _addStringAlways(iapParameters, "name", event.name);
    _addStringAlways(iapParameters, "brand", event.brand);
    _addStringAlways(iapParameters, "variant", event.variant);
    _addStringAlways(iapParameters, "category", event.category);

    // Additional category levels
    _addStringAlways(iapParameters, "category2", event.category2);
    _addStringAlways(iapParameters, "category3", event.category3);
    _addStringAlways(iapParameters, "category4", event.category4);
    _addStringAlways(iapParameters, "category5", event.category5);

    // Price and quantity
    if (event.price != null) {
      _addFloat(iapParameters, "price", event.price!);
    }
    if (event.quantity != null) {
      _addInteger(iapParameters, "quantity", event.quantity!);
    }

    // Refund amount
    if (event.refund != null) {
      _addFloat(iapParameters, "refund", event.refund!);
    }

    // Promotion and marketing related
    _addStringAlways(iapParameters, "coupon", event.coupon);
    _addStringAlways(iapParameters, "affiliation", event.affiliation);
    _addStringAlways(iapParameters, "location_id", event.locationId);
    _addStringAlways(iapParameters, "list_id", event.listId);
    _addStringAlways(iapParameters, "list_name", event.listName);

    if (event.listIndex != null) {
      _addInteger(iapParameters, "list_index", event.listIndex!);
    }

    _addStringAlways(iapParameters, "promotion_id", event.promotionId);
    _addStringAlways(iapParameters, "promotion_name", event.promotionName);
    _addStringAlways(iapParameters, "creative_name", event.creativeName);
    _addStringAlways(iapParameters, "creative_slot", event.creativeSlot);

    // Transaction ID
    _addStringAlways(iapParameters, "transaction_id", event.getTransactionId());

    // Custom item parameters as array with typed values
    if (event.itemParams != null) {
      final itemParamsArray = event.itemParams!.map((param) {
        final Map<String, dynamic> valueMap = {};

        // Set appropriate value field based on type
        if (param.value is String) {
          valueMap['string_value'] = param.value as String;
        } else if (param.value is int) {
          valueMap['int_value'] = param.value as int;
        } else if (param.value is double) {
          valueMap['float_value'] = param.value as double;
        } else if (param.value is bool) {
          valueMap['bool_value'] = param.value as bool;
        }

        return {
          'key': param.name,
          'value': valueMap,
        };
      }).toList();
      iapParameters.add(DynamicParameter("item_params", itemParamsArray));
    }

    package.item = iapParameters;
  }

  /// Sets attribution parameters
  Future<void> _setAttributionParameters(
    Package package,
    MetriqusAttribution attribution,
  ) async {
    await _addDefaultParameters(package);

    final attributionParams = <String, List<DynamicParameter>>{};

    if (MetriqusUtils.isIOS) {
      attributionParams["ios"] = <DynamicParameter>[];

      // iOS-specific attribution fields (normal parameters) - exclude raw
      _addBooleanAlways(
          attributionParams["ios"]!, "attribution", attribution.attribution);
      _addIntegerAlways(attributionParams["ios"]!, "org_id", attribution.orgId);
      _addIntegerAlways(
          attributionParams["ios"]!, "campaign_id", attribution.campaignId);
      _addStringAlways(attributionParams["ios"]!, "conversion_type",
          attribution.conversionType);
      _addStringAlways(
          attributionParams["ios"]!, "click_date", attribution.clickDate);
      _addStringAlways(
          attributionParams["ios"]!, "claim_type", attribution.claimType);
      _addIntegerAlways(
          attributionParams["ios"]!, "ad_group_id", attribution.adGroupId);
      _addStringAlways(attributionParams["ios"]!, "country_or_region",
          attribution.countryOrRegion);
      _addIntegerAlways(
          attributionParams["ios"]!, "keyword_id", attribution.keywordId);
      _addIntegerAlways(
          attributionParams["ios"]!, "attribution_ad_id", attribution.adId);

      // Create params as key-value array with only raw data
      final iOSAttributionParamsArray = <Map<String, dynamic>>[];
      _addToKeyValueArray(iOSAttributionParamsArray, "raw", attribution.raw);

      // Add params as key-value array
      attributionParams["ios"]!
          .add(DynamicParameter("params", iOSAttributionParamsArray));
    } else if (MetriqusUtils.isAndroid) {
      attributionParams["android"] = <DynamicParameter>[];

      // Android-specific attribution fields (normal parameters) - exclude raw
      _addStringAlways(
          attributionParams["android"]!, "source", attribution.source);
      _addStringAlways(
          attributionParams["android"]!, "medium", attribution.medium);
      _addStringAlways(
          attributionParams["android"]!, "campaign", attribution.campaign);
      _addStringAlways(attributionParams["android"]!, "term", attribution.term);
      _addStringAlways(
          attributionParams["android"]!, "content", attribution.content);

      // Add custom parameters if available
      if (attribution.params != null && attribution.params!.isNotEmpty) {
        for (final param in attribution.params!) {
          if (param.value is String) {
            _addString(attributionParams["android"]!, param.name,
                param.value as String);
          } else if (param.value is int) {
            _addInteger(
                attributionParams["android"]!, param.name, param.value as int);
          } else if (param.value is double) {
            _addFloat(attributionParams["android"]!, param.name,
                param.value as double);
          } else if (param.value is bool) {
            _addBoolean(
                attributionParams["android"]!, param.name, param.value as bool);
          }
        }
      }

      // Create params as key-value array with only raw data
      final androidAttributionParamsArray = <Map<String, dynamic>>[];
      _addToKeyValueArray(
          androidAttributionParamsArray, "raw", attribution.raw);

      // Add params as key-value array
      attributionParams["android"]!
          .add(DynamicParameter("params", androidAttributionParamsArray));
    }

    package.attribution = attributionParams;
  }

  /// Sets ad revenue event parameters
  Future<void> _setAdRevenueEventParameters(
    Package package,
    MetriqusAdRevenue event,
  ) async {
    await _addDefaultParameters(package);

    final publisherParameters = <DynamicParameter>[];

    // Core ad revenue parameters
    _addStringAlways(publisherParameters, "ad_source", event.source);
    if (event.revenue != null) {
      _addFloat(publisherParameters, "ad_revenue", event.revenue! * 1000000);
    }
    _addStringAlways(publisherParameters, "ad_currency", event.currency);

    if (event.adImpressionsCount != null) {
      _addInteger(publisherParameters, "ad_impression_count",
          event.adImpressionsCount!);
    }
    _addStringAlways(
        publisherParameters, "ad_revenue_network", event.adRevenueNetwork);
    _addStringAlways(
        publisherParameters, "ad_revenue_unit", event.adRevenueUnit);
    _addStringAlways(
        publisherParameters, "ad_revenue_placement", event.adRevenuePlacement);

    package.publisher = publisherParameters;
  }

  /// Sets custom event parameters
  Future<void> _setCustomEventParameters(
    Package package,
    MetriqusCustomEvent event,
  ) async {
    await _addDefaultParameters(package);

    // Convert custom event parameters to array format like IAP
    final eventParams = event.getParameters();
    if (eventParams != null && eventParams.isNotEmpty) {
      final parametersArray = eventParams.map((param) {
        final Map<String, dynamic> valueMap = {};

        // Set appropriate value field based on type
        if (param.value is String) {
          valueMap['string_value'] = param.value as String;
        } else if (param.value is int) {
          valueMap['int_value'] = param.value as int;
        } else if (param.value is double) {
          valueMap['float_value'] = param.value as double;
        } else if (param.value is bool) {
          valueMap['bool_value'] = param.value as bool;
        }

        return {
          'key': param.name,
          'value': valueMap,
        };
      }).toList();

      // Add to eventParams field - store the structured array data
      package.eventParams = [
        DynamicParameter("event_parameters_data", parametersArray)
      ];
    }
  }

  /// Adds default parameters to package
  Future<void> _addDefaultParameters(Package package) async {
    try {
      // Set basic package information
      package.eventId = _generateEventId();
      // During initialization, get session ID directly from native
      final native = Metriqus.native;
      package.sessionId = native?.getSessionId;
      package.clientSdk = await Metriqus.getClientSdk();
      // During initialization, get first launch status directly from native
      package.isFirstLaunch = native?.getIsFirstLaunch ?? false;
      package.eventTimestamp = MetriqusUtils.getCurrentUtcTimestampSeconds();
      // During initialization, get user ID directly from native
      if (native?.uniqueUserIdentifier != null) {
        package.userId = native!.uniqueUserIdentifier!.id;
      } else if (native?.storage != null) {
        // Check if user ID exists in storage synchronously
        if (native!.storage!.checkKeyExist("UniqueUserIdentifier")) {
          package.userId = native.storage!.loadData("UniqueUserIdentifier");
        }
      }
      // During initialization, get first launch time directly from native
      package.userFirstTouchTimestamp =
          MetriqusUtils.dateTimeToUtcTimestampSeconds(
        native?.getFirstLaunchTime() ?? MetriqusUtils.getUtcStartTime(),
      );
      package.environment = metriqusSettings?.environment.name ?? 'production';

      // Device parameters
      final deviceParameters = <DynamicParameter>[];
      if (deviceInfo != null) {
        _addString(
          deviceParameters,
          "flutter_version",
          deviceInfo!.flutterVersion,
        );
        _addString(deviceParameters, "device_type", deviceInfo!.deviceType);
        _addString(deviceParameters, "device_name", deviceInfo!.deviceName);
        _addString(deviceParameters, "device_model", deviceInfo!.deviceModel);
        _addString(
          deviceParameters,
          "graphics_device_name",
          deviceInfo!.graphicsDeviceName,
        );
        _addString(deviceParameters, "os_name", deviceInfo!.osName);
        _addString(
          deviceParameters,
          "system_memory_size",
          deviceInfo!.systemMemorySize.toString(),
        );
        _addString(
          deviceParameters,
          "graphics_memory_size",
          deviceInfo!.graphicsMemorySize.toString(),
        );
        _addString(deviceParameters, "language", deviceInfo!.language);
        _addString(deviceParameters, "country", deviceInfo!.country);
        _addString(
          deviceParameters,
          "screen_dpi",
          deviceInfo!.screenDpi.toString(),
        );
        _addString(
          deviceParameters,
          "screen_width",
          deviceInfo!.screenWidth.toString(),
        );
        _addString(
          deviceParameters,
          "screen_height",
          deviceInfo!.screenHeight.toString(),
        );
        _addString(deviceParameters, "device_id", deviceInfo!.deviceId);
        _addString(deviceParameters, "ad_id", deviceInfo!.adId);
        _addString(
          deviceParameters,
          "tracking_enabled",
          deviceInfo!.trackingEnabled.toString().toUpperCase(),
        );
        _addString(
            deviceParameters, "platform", deviceInfo!.platform.toString());

        // Debug log
        Metriqus.verboseLog(
          '🔍 PACKAGE DEBUG: adId="${deviceInfo!.adId}", trackingEnabled=${deviceInfo!.trackingEnabled}',
        );
      }
      package.device = deviceParameters;

      // App info - use getCurrentAppInfo() method
      package.appInfo = await AppInfoPackage.getCurrentAppInfo();

      // Geolocation parameters - get directly from native during initialization
      final geolocation = native?.getGeolocation();
      if (geolocation != null) {
        final geolocationParameters = <DynamicParameter>[];
        _addString(geolocationParameters, "country", geolocation.country);
        _addString(
          geolocationParameters,
          "country_code",
          geolocation.countryCode,
        );
        _addString(geolocationParameters, "city", geolocation.city);
        _addString(geolocationParameters, "region", geolocation.region);
        _addString(
          geolocationParameters,
          "region_name",
          geolocation.regionName,
        );
        package.geolocation = geolocationParameters;
      }

      // User attributes - get directly from native during initialization
      final userAttributesMap = native?.userAttributes?.getAllAttributes();
      if (userAttributesMap != null && userAttributesMap.isNotEmpty) {
        final userAttributesArray = userAttributesMap.entries.map((entry) {
          final Map<String, dynamic> valueMap = {};

          // Set appropriate value field based on type
          if (entry.value is String) {
            valueMap['string_value'] = entry.value as String;
          } else if (entry.value is int) {
            valueMap['int_value'] = entry.value as int;
          } else if (entry.value is double) {
            valueMap['float_value'] = entry.value as double;
          } else if (entry.value is bool) {
            valueMap['bool_value'] = entry.value as bool;
          }

          return {
            'key': entry.key,
            'value': valueMap,
          };
        }).toList();

        // Store as DynamicParameter array like item_params
        final userPropertiesParameters = <DynamicParameter>[];
        userPropertiesParameters
            .add(DynamicParameter("user_properties_data", userAttributesArray));
        package.userAttributes = userPropertiesParameters;
      }
    } catch (e) {
      // Fallback values if something goes wrong
      package.eventId = _generateEventId();
      package.eventTimestamp = MetriqusUtils.getCurrentUtcTimestampSeconds();
      package.environment = metriqusSettings?.environment.name ?? 'production';
    }
  }

  /// Generate unique event ID
  String _generateEventId() {
    const uuid = Uuid();
    return uuid.v4();
  }

  /// Helper methods for adding parameters
  void _addString(List<DynamicParameter> list, String key, String? value) {
    if (key == "ad_id") {
      Metriqus.verboseLog(
        '🔍 _addString DEBUG: key="$key", value="$value", isNotEmpty=${value?.isNotEmpty}',
      );
    }
    if (value != null && value.isNotEmpty) {
      list.add(DynamicParameter(key, value));
      if (key == "ad_id") {
        Metriqus.verboseLog('✅ ad_id ADDED to parameters');
      }
    } else {
      if (key == "ad_id") {
        Metriqus.verboseLog('❌ ad_id NOT ADDED - value is null or empty');
      }
    }
  }

  void _addInteger(List<DynamicParameter> list, String key, int? value) {
    if (value != null) {
      list.add(DynamicParameter(key, value));
    }
  }

  void _addFloat(List<DynamicParameter> list, String key, double? value) {
    if (value != null) {
      list.add(DynamicParameter(key, value));
    }
  }

  void _addBoolean(List<DynamicParameter> list, String key, bool? value) {
    if (value != null) {
      list.add(DynamicParameter(key, value));
    }
  }

  // Always add methods for attribution fields that BigQuery expects
  void _addIntegerAlways(List<DynamicParameter> list, String key, int? value) {
    list.add(DynamicParameter(key, value));
  }

  void _addBooleanAlways(List<DynamicParameter> list, String key, bool? value) {
    list.add(DynamicParameter(key, value));
  }

  void _addStringAlways(
      List<DynamicParameter> list, String key, String? value) {
    // Always add the parameter, even if null or empty
    list.add(DynamicParameter(key, value ?? ""));
  }

  /// Helper method for adding parameters to key-value array format (like itemParams)
  void _addToKeyValueArray(
      List<Map<String, dynamic>> array, String key, dynamic value) {
    if (value != null) {
      final Map<String, dynamic> valueMap = {};

      // Set appropriate value field based on type
      if (value is String) {
        valueMap['string_value'] = value;
      } else if (value is int) {
        valueMap['int_value'] = value;
      } else if (value is double) {
        valueMap['float_value'] = value;
      } else if (value is bool) {
        valueMap['bool_value'] = value;
      }

      array.add({
        'key': key,
        'value': valueMap,
      });
    }
  }
}

/// Represents a package containing event data
class Package {
  String? eventName;
  String? eventId;
  String? sessionId;
  String? clientSdk;
  bool? isFirstLaunch;
  int? eventTimestamp;
  String? userId;
  int? userFirstTouchTimestamp;
  String? environment;

  List<DynamicParameter>? device;
  List<DynamicParameter>? geolocation;
  AppInfoPackage? appInfo;
  List<DynamicParameter>? item;
  List<DynamicParameter>? publisher;
  Map<String, List<DynamicParameter>>? attribution;
  List<TypedParameter>? parameters;
  List<DynamicParameter>? userAttributes;
  List<DynamicParameter>? eventParams;

  /// Default constructor
  Package();

  /// Sets the package key
  void setKey(String key) {
    eventName = key;
  }

  /// Converts to JSON map
  Map<String, dynamic> toJson() {
    return {
      'eventName': eventName,
      'eventId': eventId,
      'sessionId': sessionId,
      'clientSdk': clientSdk,
      'isFirstLaunch': isFirstLaunch,
      'eventTimestamp': eventTimestamp,
      'userId': userId,
      'userFirstTouchTimestamp': userFirstTouchTimestamp,
      'environment': environment,
      'device': device?.length ?? 0,
      'geolocation': geolocation?.length ?? 0,
      'appInfo': appInfo?.toJson(),
      'item': item?.length ?? 0,
      'publisher': publisher?.length ?? 0,
      'attribution': attribution?.keys.length ?? 0,
      'parameters': parameters?.length ?? 0,
      'userAttributes': userAttributes?.length ?? 0,
      'eventParams': eventParams?.length ?? 0,
    };
  }

  /// Converts to detailed JSON map for verbose logging
  Map<String, dynamic> toDetailedJson() {
    return {
      'eventName': eventName,
      'eventId': eventId,
      'sessionId': sessionId,
      'clientSdk': clientSdk,
      'isFirstLaunch': isFirstLaunch,
      'eventTimestamp': eventTimestamp,
      'userId': userId,
      'userFirstTouchTimestamp': userFirstTouchTimestamp,
      'environment': environment,
      'device': device?.map((param) => param.toJson()).toList(),
      'geolocation': geolocation?.map((param) => param.toJson()).toList(),
      'appInfo': appInfo?.toJson(),
      'item': item?.map((param) => param.toJson()).toList(),
      'publisher': publisher?.map((param) => param.toJson()).toList(),
      'attribution': attribution?.map(
        (key, value) =>
            MapEntry(key, value.map((param) => param.toJson()).toList()),
      ),
      'parameters': parameters
          ?.map((param) => {'name': param.name, 'value': param.value})
          .toList(),
      'userAttributes': userAttributes?.map((param) => param.toJson()).toList(),
      'eventParams': eventParams?.map((param) => param.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

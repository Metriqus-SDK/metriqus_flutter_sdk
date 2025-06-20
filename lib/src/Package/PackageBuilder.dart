import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';
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

    if (event.revenue != null) {
      _addInteger(iapParameters, "revenue", (event.revenue! * 1000000).toInt());
    }

    _addString(iapParameters, "currency", event.currency);
    _addString(iapParameters, "product_id", event.productId);
    _addString(iapParameters, "name", event.name);
    _addString(iapParameters, "brand", event.brand);
    _addString(iapParameters, "variant", event.variant);
    _addString(iapParameters, "category", event.category);

    package.item = iapParameters;
  }

  /// Sets attribution parameters
  Future<void> _setAttributionParameters(
    Package package,
    MetriqusAttribution attribution,
  ) async {
    await _addDefaultParameters(package);

    final attributionParams = <String, List<DynamicParameter>>{};

    if (Platform.isIOS) {
      attributionParams["ios"] = <DynamicParameter>[];
      _addBoolean(
        attributionParams["ios"]!,
        "attribution",
        attribution.attribution,
      );
      _addString(attributionParams["ios"]!, "raw", attribution.raw);
    } else if (Platform.isAndroid) {
      attributionParams["android"] = <DynamicParameter>[];
      _addString(attributionParams["android"]!, "source", attribution.source);
      _addString(attributionParams["android"]!, "medium", attribution.medium);
      _addString(
        attributionParams["android"]!,
        "campaign",
        attribution.campaign,
      );
      _addString(attributionParams["android"]!, "raw", attribution.raw);
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

    _addString(publisherParameters, "ad_source", event.source);
    if (event.revenue != null) {
      _addInteger(
        publisherParameters,
        "ad_revenue",
        (event.revenue! * 1000000).toInt(),
      );
    }
    _addString(publisherParameters, "ad_currency", event.currency);

    package.publisher = publisherParameters;
  }

  /// Sets custom event parameters
  Future<void> _setCustomEventParameters(
    Package package,
    MetriqusCustomEvent event,
  ) async {
    await _addDefaultParameters(package);
    package.parameters = event.getParameters();
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
        _addString(deviceParameters, "type", deviceInfo!.deviceType);
        _addString(deviceParameters, "name", deviceInfo!.deviceName);
        _addString(deviceParameters, "model", deviceInfo!.deviceModel);
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
        _addString(deviceParameters, "id", deviceInfo!.deviceId);
        _addString(deviceParameters, "ad_id", deviceInfo!.adId);
        _addString(
          deviceParameters,
          "tracking_enabled",
          deviceInfo!.trackingEnabled.toString().toUpperCase(),
        );

        // Debug log
        Metriqus.verboseLog(
          '🔍 PACKAGE DEBUG: adId="${deviceInfo!.adId}", trackingEnabled=${deviceInfo!.trackingEnabled}',
        );
      }
      package.device = deviceParameters;

      // Get package info to retrieve bundle ID and version
      final packageInfo = await PackageInfo.fromPlatform();

      // App info
      package.appInfo = AppInfoPackage(
        packageInfo.packageName,
        packageInfo.version,
      );

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
        final userAttributesList = <TypedParameter>[];
        userAttributesMap.forEach((key, value) {
          if (value is String) {
            userAttributesList.add(TypedParameter.string(key, value));
          } else if (value is int) {
            userAttributesList.add(TypedParameter.int(key, value));
          } else if (value is double) {
            userAttributesList.add(TypedParameter.double(key, value));
          } else if (value is bool) {
            userAttributesList.add(TypedParameter.bool(key, value));
          }
        });
        package.userAttributes = userAttributesList;
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

  void _addBoolean(List<DynamicParameter> list, String key, bool? value) {
    if (value != null) {
      list.add(DynamicParameter(key, value));
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
  List<TypedParameter>? userAttributes;

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
      'userAttributes': userAttributes
          ?.map((param) => {'name': param.name, 'value': param.value})
          .toList(),
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

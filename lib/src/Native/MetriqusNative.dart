import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../Storage/IStorage.dart';
import '../Utilities/MetriqusUtils.dart';
import '../Storage/Storage.dart';
import '../Storage/EncryptedStorageHandler.dart';
import '../MetriqusSettings.dart';
import '../MetriqusRemoteSettings.dart';
import '../Utilities/UniqueUserIdentifier.dart';
import 'UserAttributes.dart';
import '../Utilities/DeviceInfo.dart';
import '../Utilities/IPGeolocation.dart';
import '../Utilities/InternetConnectionChecker.dart';
import '../Utilities/Geolocation.dart';
import '../WebRequest/RequestSender.dart';
import '../WebRequest/MetriqusResponseObject.dart' as WebResponse;
import '../EventLogger/MetriqusLogger.dart';
import '../Metriqus.dart';
import '../EventModels/AdRevenue/MetriqusAdRevenue.dart';
import '../EventModels/MetriqusInAppRevenue.dart';
import '../EventModels/CustomEvents/MetriqusCustomEvent.dart';
import '../EventModels/Attribution/MetriqusAttribution.dart';
import '../EventLogger/Parameters/TypedParameter.dart';
import '../Package/IPackageSender.dart';
import '../Package/MetriqusPackageSender.dart';

/// Abstract base class for platform-specific native implementations
abstract class MetriqusNative {
  static const String firstLaunchTimeKey = "metriqus_first_launch_time";
  static const String lastSessionStartTimeKey = "metriqus_last_session_start_time";
  static const String sessionIdKey = "metriqus_session_id";
  static const String lastSendAttributionDateKey = "metriqus_last_send_attribution_date";
  static const String remoteSettingsKey = "metriqus_remote_settings";
  static const String geolocationKey = "geolocation_settings";
  static const String geolocationLastFetchedTimeKey = "geolocation_last_fetched_time";

  // Private fields
  IPackageSender? _packageSender;
  DeviceInfo? _deviceInfo;
  Geolocation? _geolocation;
  InternetConnectionChecker? _internetConnectionChecker;

  // Protected fields
  UniqueUserIdentifier? uniqueUserIdentifier;
  UserAttributes? userAttributes;
  IStorage? storage;
  MetriqusSettings? metriqusSettings;

  bool isTrackingEnabled = false;
  bool _isInitialized = false;
  bool _isFirstLaunch = false;
  bool _remoteSettingsFetched = false;
  bool _geolocationFetched = false;
  String? _sessionId;
  String? adId;

  // Getters
  bool get getIsTrackingEnabled => isTrackingEnabled;
  bool get getIsFirstLaunch => _isFirstLaunch;
  bool get getIsInitialized => _isInitialized;
  String? get getSessionId => _sessionId;
  DeviceInfo? get getDeviceInfo => _deviceInfo;
  UniqueUserIdentifier? get getUniqueUserIdentifier => uniqueUserIdentifier;
  UserAttributes? get getUserAttributes => userAttributes;
  InternetConnectionChecker? get getInternetConnectionChecker => _internetConnectionChecker;

  /// Initialize the SDK
  Future<void> initSdk(MetriqusSettings settings) async {
    try {
      this.metriqusSettings = settings;

      // Initialize storage with encrypted handler
      storage = Storage(EncryptedStorageHandler());

      // Wait for cache initialization to complete
      await storage!.waitForCacheInitialization();
      Metriqus.verboseLog(
        "🔧 [STORAGE] Cache initialization awaited successfully",
      );

      // Initialize device info
      _deviceInfo = DeviceInfo();
      await _deviceInfo!.initialize();

      // Initialize package sender
      _packageSender = MetriqusPackageSender();

      // Initialize internet connection checker
      _internetConnectionChecker = InternetConnectionChecker();

      // Initialize user identifier and attributes
      uniqueUserIdentifier = UniqueUserIdentifier(storage!);
      userAttributes = UserAttributes(storage!);

      // Initialize user attributes asynchronously
      await userAttributes!.initializeAsync();

      // Set up internet connection listener
      _internetConnectionChecker!.onConnectedToInternet = _onConnectedToInternet;

      // Wait for fetching remote settings and geolocation
      await _fetchRemoteSettings();
      await _fetchGeolocation();

      // Initialize logger
      MetriqusLogger.init(storage!);

      _isInitialized = true;
      Metriqus.verboseLog(
        "🔧 [NATIVE] SDK initialization completed successfully",
      );

      // Process initialization tasks after SDK is marked as initialized
      _processIsFirstLaunch();
      _processSession();

      // Process attribution asynchronously - this will handle all attribution logic
      Future.delayed(Duration(milliseconds: 100), () {
        _processAttribution();
      });
    } catch (e) {
      Metriqus.errorLog("❌ Error while initializing Native: $e");

      if (storage == null) {
        storage = Storage(EncryptedStorageHandler());
        MetriqusLogger.init(storage!);
      }

      _isInitialized = false;
    }
  }

  /// Get advertising ID
  String? getAdid() => adId;

  /// Abstract methods to be implemented by platform-specific classes
  void readAdid(Function(String) callback);
  void readAttribution(
    Function(MetriqusAttribution?) onReadCallback,
    Function(String) onError,
  );
  void getInstallTime(Function(int) callback);

  /// Handle internet connection
  Future<void> _onConnectedToInternet() async {
    /*debugPrint("OnConnectedToInternet");*/

    List<Future> tasks = [];

    if (!_remoteSettingsFetched) {
      tasks.add(_fetchRemoteSettings());
    }

    if (!_geolocationFetched) {
      tasks.add(_fetchGeolocation());
    }

    await Future.wait(tasks);
  }

  /// Track ad revenue
  void trackAdRevenue(MetriqusAdRevenue adRevenue) {
    _packageSender?.sendAdRevenuePackage(adRevenue);
  }

  /// Track IAP event
  void trackIAPEvent(MetriqusInAppRevenue metriqusEvent) {
    _packageSender?.sendIAPEventPackage(metriqusEvent);
  }

  /// Track custom event
  void trackCustomEvent(MetriqusCustomEvent event) {
    _packageSender?.sendCustomPackage(event);
  }

  /// Set user attribute
  void setUserAttribute(TypedParameter parameter) {
    userAttributes?.setAttribute(parameter.name, parameter.value);
  }

  /// Remove user attribute
  void removeUserAttribute(String key) {
    userAttributes?.removeAttribute(key);
  }

  /// Send session beat event
  void sendSessionBeatEvent() {
    _packageSender?.sendSessionBeatPackage();
  }

  /// Update iOS conversion value (iOS specific)
  void updateIOSConversionValue(int value) {
    // iOS specific implementation
  }

  /// Application lifecycle methods
  void onPause() {
    // Handle app pause
  }

  void onResume() {
    Metriqus.verboseLog("Application resumed. Processing session.");
    _processSession();
  }

  void onQuit() {
    Metriqus.verboseLog("Application quitting. Disposing resources.");
    dispose();
  }

  /// Public method to (re)process attribution on demand
  void processAttributionNow() {
    _processAttribution();
  }

  /// Dispose all native resources
  void dispose() {
    _packageSender?.dispose();
    Metriqus.verboseLog("Native resources disposed.");
  }

  /// Process session logic
  void _processSession() {
    DateTime currentTime = MetriqusUtils.timestampSecondsToDateTime(
      MetriqusUtils.getCurrentUtcTimestampSeconds(),
    );

    try {
      // Check if this is first session by checking lastSessionStartTimeKey exist
      bool isLastSessionStartTimeSaved = storage!.checkKeyExist(
        lastSessionStartTimeKey,
      );

      // If LastSessionStartTimeKey already saved, it means this is not first session
      if (isLastSessionStartTimeSaved) {
        // THIS IS NOT FIRST SESSION
        String lastSessionStartTimeStr = storage!.loadData(
          lastSessionStartTimeKey,
        );
        DateTime lastSessionStartTime = _parseDate(lastSessionStartTimeStr);

        var remoteSettings = getMetriqusRemoteSettings();

        double passedMinutesSinceLastSession = currentTime.difference(lastSessionStartTime).inMinutes.toDouble();

        Metriqus.verboseLog(
          "Passed Minutes Since Last Session: $passedMinutesSinceLastSession",
        );

        if (passedMinutesSinceLastSession >= remoteSettings.sessionIntervalMinutes) {
          _sessionId = _generateGuid();
          storage!.saveData(sessionIdKey, _sessionId!);

          _packageSender?.sendSessionStartPackage();
        } else {
          // Try to load existing session ID directly
          String existingSessionId = storage!.loadData(sessionIdKey);

          if (existingSessionId.isNotEmpty) {
            _sessionId = existingSessionId;
          } else {
            _sessionId = _generateGuid();
          }
        }
      } else {
        // THIS IS THE FIRST SESSION
        _sessionId = _generateGuid();
        storage!.saveData(sessionIdKey, _sessionId!);

        _packageSender?.sendSessionStartPackage();
      }
    } catch (e) {
      Metriqus.errorLog("An error occurred ProcessSession: $e");
    }

    storage!.saveData(
      lastSessionStartTimeKey,
      _convertDateToString(currentTime),
    );
  }

  /// Process attribution logic
  void _processAttribution() {
    try {
      // Cancel attribution if tracking disabled
      // if (!isTrackingEnabled) {
      //   Metriqus.infoLog(
      //     "ProcessAttribution canceled: user not allowed tracking",
      //   );
      //   return;
      // }

      // Cancel attribution on iOS platform if tracking disabled
      // if (metriqusSettings?.iOSUserTrackingDisabled == true) {
      //   Metriqus.infoLog(
      //     "ProcessAttribution canceled: iOS User Tracking Disabled",
      //   );
      //   return;
      // }

      DateTime currentDate = MetriqusUtils.timestampSecondsToDateTime(
        MetriqusUtils.getCurrentUtcTimestampSeconds(),
      );

      void sendAttr() {
        readAttribution(
          (attribution) {
            if (attribution != null) {
              _packageSender?.sendAttributionPackage(attribution);
              storage!.saveData(lastSendAttributionDateKey, _convertDateToString(currentDate));
            }
          },
          (error) {
            Metriqus.errorLog("Attribution read error: $error");
          },
        );
      }

      getInstallTime((installTime) {
        // Install date available if window logic is re-enabled in the future
        /* final DateTime installDate = MetriqusUtils.timestampSecondsToDateTime(
          installTime,
        ); */

        // Attribution window logic temporarily disabled; sending attribution once

        // C# Unity SDK attribution logic - exact match
        // if (daysSinceInstall < remoteSettings.attributionCheckWindow) {
        // if it has been less than attribution window days, send attribution
        sendAttr();
        // } else if (!lastSendAttributionDateExist) {
        //   // if didnt send any attribution send it
        //   sendAttr();
        // } else {
        //   // if last attribution send date before attribution window days and now it passed
        //   // attribution window days send last one more time
        //   String lastAttributionDateStr = storage!.loadData(
        //     lastSendAttributionDateKey,
        //   );
        //   DateTime lastAttributionDate = _parseDate(lastAttributionDateStr);

        //   int daysSinceInstallWhenLastSent = lastAttributionDate.difference(installDate).inDays;

        //   if (daysSinceInstallWhenLastSent < remoteSettings.attributionCheckWindow &&
        //       daysSinceInstall >= remoteSettings.attributionCheckWindow) {
        //     sendAttr();
        //   }
        // }
      });
    } catch (e) {
      Metriqus.errorLog("An error occurred on ProcessAttribution: $e");
    }
  }

  /// Process first launch logic
  void _processIsFirstLaunch() {
    try {
      // Try to load existing first launch time directly
      String existingFirstLaunchTime = storage!.loadData(firstLaunchTimeKey);

      if (existingFirstLaunchTime.isEmpty) {
        _isFirstLaunch = true;
        storage!.saveData(
          firstLaunchTimeKey,
          _convertDateToString(
            MetriqusUtils.timestampSecondsToDateTime(
              MetriqusUtils.getCurrentUtcTimestampSeconds(),
            ),
          ),
        );
        onFirstLaunch();
      }
    } catch (e) {
      Metriqus.errorLog("An error occurred on ProcessIsFirstLaunch: $e");
    }
  }

  /// Abstract method to be implemented by subclasses
  void onFirstLaunch();

  /// Get first launch time
  DateTime getFirstLaunchTime() {
    // Try to load first launch time directly
    String firstLaunchTime = storage!.loadData(firstLaunchTimeKey);

    if (firstLaunchTime.isNotEmpty) {
      return _parseDate(firstLaunchTime);
    }

    return MetriqusUtils.timestampSecondsToDateTime(
      MetriqusUtils.getCurrentUtcTimestampSeconds(),
    );
  }

  /// Get Metriqus settings
  MetriqusSettings getMetriqusSettings() {
    return metriqusSettings!;
  }

  /// Get Metriqus remote settings
  MetriqusRemoteSettings getMetriqusRemoteSettings() {
    return MetriqusRemoteSettings.getInstance();
  }

  /// Fetch geolocation
  Future<Geolocation?> _fetchGeolocation() async {
    Geolocation? info;

    DateTime geolocationLastFetchedTime = _getUtcStartTime();

    // Check if geolocation fetched before
    String geolocationLastFetchedTimeStr = storage!.loadData(
      geolocationLastFetchedTimeKey,
    );
    if (geolocationLastFetchedTimeStr.isNotEmpty) {
      // Load and parse last fetched date
      geolocationLastFetchedTime = _parseDate(geolocationLastFetchedTimeStr);
    }

    var remoteSettings = getMetriqusRemoteSettings();

    bool fetchingSuccessful = true;

    if (MetriqusUtils.timestampSecondsToDateTime(
          MetriqusUtils.getCurrentUtcTimestampSeconds(),
        ).difference(geolocationLastFetchedTime).inDays >
        remoteSettings.geolocationFetchIntervalDays) {
      // it passed {remoteSettings.geolocationFetchIntervalDays} since last fetched geolocation
      Metriqus.verboseLog(
        "Fetching geolocating. Last Fetched at: ${geolocationLastFetchedTime.toString()}",
      );

      var fetchedGeolocation = await IPGeolocation.getGeolocation();

      fetchingSuccessful = fetchedGeolocation != null;
      info = fetchedGeolocation;
    }

    if (info != null) {
      _geolocationFetched = true;
      _geolocation = info;

      Metriqus.verboseLog("Geolocation fetched: ${jsonEncode(info.toJson())}");

      storage!.saveData(geolocationKey, jsonEncode(info.toJson()));
      storage!.saveData(
        geolocationLastFetchedTimeKey,
        _convertDateToString(
          MetriqusUtils.timestampSecondsToDateTime(
            MetriqusUtils.getCurrentUtcTimestampSeconds(),
          ),
        ),
      );

      return info;
    } else {
      if (fetchingSuccessful) {
        _geolocationFetched = true;
      }

      String geolocationJson = storage!.loadData(geolocationKey);
      if (geolocationJson.isNotEmpty) {
        _geolocation = Geolocation.fromJson(jsonDecode(geolocationJson));

        Metriqus.verboseLog(
          "Geolocation loaded from storage: $geolocationJson",
        );

        return _geolocation;
      }
    }

    _geolocationFetched = false;
    return null;
  }

  /// Get geolocation
  Geolocation? getGeolocation() => _geolocation;

  /// Fetch remote settings
  Future<bool> _fetchRemoteSettings() async {
    var headers = <String, String>{};
    RequestSender.addContentType(headers, RequestSender.contentTypeJson);
    RequestSender.addAccept(headers, RequestSender.contentTypeJson);

    var response = await RequestSender.postAsync(
      "https://rmt.metriqus.com/event/remote-settings",
      jsonEncode(
        RemoteSettingRequestParams(
          platform: _deviceInfo!.platform,
          clientKey: metriqusSettings!.clientKey,
          packageName: _deviceInfo!.packageName,
        ).toJson(),
      ),
      headers: headers,
    ).timeout(Duration(seconds: 60));

    var mro = WebResponse.MetriqusResponseObject.parse(response.data);

    if (response.isSuccess && mro != null) {
      MetriqusRemoteSettings.parse(mro.data);

      // Save as JSON string for storage
      String dataToSave;
      if (mro.data is Map) {
        dataToSave = jsonEncode(mro.data);
      } else {
        dataToSave = mro.data.toString();
      }
      storage!.saveData(remoteSettingsKey, dataToSave);
      _remoteSettingsFetched = true;

      return true;
    } else {
      bool isKeyExist = storage!.checkKeyExist(remoteSettingsKey);

      if (isKeyExist) {
        String data = storage!.loadData(remoteSettingsKey);
        Metriqus.verboseLog("Remote Settings loaded from storage: $data");
        MetriqusRemoteSettings.parse(data);
      } else {
        // Use singleton instance with default values
        MetriqusRemoteSettings.getInstance();
        Metriqus.infoLog(
          "Remote Settings couldn't fetched or couldn't loaded from storage, using default",
        );
      }
    }

    _remoteSettingsFetched = false;
    return false;
  }

  // Utility methods
  String _generateGuid() {
    const uuid = Uuid();
    return uuid.v4();
  }

  DateTime _parseDate(String dateString) {
    return DateTime.parse(dateString);
  }

  String _convertDateToString(DateTime date) {
    return date.toIso8601String();
  }

  DateTime _getUtcStartTime() {
    return DateTime.utc(1970, 1, 1);
  }
}

/// Remote setting request parameters
class RemoteSettingRequestParams {
  int platform;
  String clientKey;
  String packageName;

  RemoteSettingRequestParams({
    required this.platform,
    required this.clientKey,
    required this.packageName,
  });

  Map<String, dynamic> toJson() {
    return {
      'Platform': platform,
      'ClientKey': clientKey,
      'PackageName': packageName,
    };
  }
}

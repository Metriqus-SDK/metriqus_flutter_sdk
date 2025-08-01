import 'package:flutter/services.dart';
import '../MetriqusNative.dart';
import '../../MetriqusSettings.dart';
import '../../Utilities/MetriqusUtils.dart';
import '../../EventModels/Attribution/MetriqusAttribution.dart';
import '../../EventModels/Attribution/MetaAttributionUtilities.dart';
import '../../Metriqus.dart';

/// Android-specific implementation of MetriqusNative
class MetriqusAndroid extends MetriqusNative {
  static const String installTimeKey = "AndroidInstallTime";

  @override
  Future<void> initSdk(MetriqusSettings settings) async {
    // Platform kontrolü - MetriqusUtils helper fonksiyonu ile güvenli şekilde
    if (!MetriqusUtils.isAndroid) {
      Metriqus.errorLog("MetriqusAndroid can only be used on Android platform");
      return;
    }

    metriqusSettings = settings;

    try {
      // Read advertising ID first
      await _readAdidAsync();

      // Call base InitSdk after getting AdId
      await super.initSdk(settings);
    } catch (e) {
      Metriqus.errorLog("❌ Error initializing Android SDK: $e");
      rethrow;
    }
  }

  // Helper method to read AdId synchronously
  Future<void> _readAdidAsync() async {
    try {
      if (adId != null) {
        return;
      }

      // Get Advertising ID via native Android code
      final platform = MethodChannel('metriqus_flutter_sdk/device_info');
      final result = await platform.invokeMethod('getAdId');

      if (result != null && result is Map) {
        final success = result['success'] ?? false;
        final advertisingId = result['adId'] ?? '';
        final trackingEnabled = result['trackingEnabled'] ?? false;

        isTrackingEnabled = trackingEnabled;

        if (success && advertisingId.isNotEmpty) {
          Metriqus.verboseLog(
            "✅ Android Advertising ID obtained: $advertisingId",
          );
          adId = advertisingId;
        } else {
          Metriqus.verboseLog(
            "❌ Android Advertising ID not available or tracking disabled",
          );
          adId = "";
        }
      } else {
        Metriqus.errorLog(
          "❌ Failed to get Android Advertising ID response from native",
        );
        adId = "";
      }
    } catch (e) {
      Metriqus.errorLog("Error fetching Android Advertising ID: $e");
      adId = "";
    }
  }

  @override
  void readAdid(Function(String) callback) async {
    try {
      if (adId != null) {
        callback(adId!);
        return;
      }

      // Get Advertising ID via native Android code
      final platform = MethodChannel('metriqus_flutter_sdk/device_info');
      final result = await platform.invokeMethod('getAdId');

      if (result != null && result is Map) {
        final success = result['success'] ?? false;
        final advertisingId = result['adId'] ?? '';
        final trackingEnabled = result['trackingEnabled'] ?? false;

        isTrackingEnabled = trackingEnabled;

        if (success && advertisingId.isNotEmpty) {
          Metriqus.verboseLog(
            "✅ Android Advertising ID obtained: $advertisingId",
          );
          callback(advertisingId);
        } else {
          Metriqus.verboseLog(
            "❌ Android Advertising ID not available or tracking disabled",
          );
          callback("");
        }
      } else {
        Metriqus.errorLog(
          "❌ Failed to get Android Advertising ID response from native",
        );
        callback("");
      }
    } catch (e) {
      Metriqus.errorLog("Error fetching Android Advertising ID: $e");
      callback("");
    }
  }

  @override
  void readAttribution(
    Function(MetriqusAttribution?) onReadCallback,
    Function(String) onError,
  ) async {
    try {
      Metriqus.verboseLog(
        "🔍 ReadAttribution Android - Starting attribution read",
      );

      // Get attribution data via native Android code
      final platform = MethodChannel('metriqus_flutter_sdk/device_info');
      final result = await platform.invokeMethod('readAttribution');

      if (result != null && result is Map) {
        final success = result['success'] ?? false;

        if (success) {
          final referrerUrl = result['referrerUrl'] ?? '';
          await _onAttributionRead(referrerUrl, onReadCallback);
        } else {
          final error = result['error'] ?? 'Unknown error';
          onError(error);
        }
      } else {
        onError("Invalid Android attribution response");
      }
    } catch (e) {
      Metriqus.errorLog("❌ Error Reading Android Attribution: $e");
      onError("Error Reading Android Attribution: $e");
    }
  }

  /// Handle attribution read callback, similar to C# AttributionReadListener.onAttributionRead
  Future<void> _onAttributionRead(
    String referrerUrl,
    Function(MetriqusAttribution?) callback,
  ) async {
    try {
      Metriqus.verboseLog("Android referrer URL received: '$referrerUrl'");

      final attribution = MetriqusAttribution.fromReferrerUrl(referrerUrl);

      Metriqus.verboseLog("Android attribution parsed:");
      Metriqus.verboseLog("  - source: ${attribution.source}");
      Metriqus.verboseLog("  - medium: ${attribution.medium}");
      Metriqus.verboseLog("  - campaign: ${attribution.campaign}");
      Metriqus.verboseLog("  - term: ${attribution.term}");
      Metriqus.verboseLog("  - content: ${attribution.content}");
      Metriqus.verboseLog(
          "  - params count: ${attribution.params?.length ?? 0}");
      Metriqus.verboseLog("  - raw: ${attribution.raw}");

      if (MetaAttributionUtilities.isMetaUtm(attribution.source)) {
        Metriqus.verboseLog("🔍 Meta UTM detected, attempting decryption...");

        final decryptedReferrerUrl =
            await MetaAttributionUtilities.decryptMetaUtm(
          attribution.content,
        );

        if (decryptedReferrerUrl != null && decryptedReferrerUrl.isNotEmpty) {
          final metaAttribution = MetriqusAttribution.fromReferrerUrl(
            decryptedReferrerUrl,
          );
          Metriqus.verboseLog(
              "Meta attribution decrypted and parsed successfully");
          callback(metaAttribution);
        } else {
          Metriqus.verboseLog(
              "Meta UTM decryption failed, using original attribution");
          callback(attribution);
        }
      } else {
        Metriqus.verboseLog(
            "Standard attribution (not Meta UTM), returning parsed data");
        callback(attribution);
      }
    } catch (e) {
      Metriqus.errorLog("❌ Error processing attribution: $e");
      callback(null);
    }
  }

  @override
  void getInstallTime(Function(int) callback) async {
    try {
      // Try to get from storage first
      storage?.loadDataAsync(installTimeKey).then((storedTime) async {
        if (storedTime.isNotEmpty) {
          final installTime = int.tryParse(storedTime) ??
              MetriqusUtils.getCurrentUtcTimestampSeconds();
          Metriqus.verboseLog(
            "Android install time from storage: $installTime",
          );
          callback(installTime);
          return;
        }

        // Get install time via native Android code
        final platform = MethodChannel('metriqus_flutter_sdk/device_info');
        final result = await platform.invokeMethod('getInstallTime');

        if (result != null && result is Map) {
          final success = result['success'] ?? false;
          final installTime = result['installTime'] ??
              MetriqusUtils.getCurrentUtcTimestampSeconds();

          if (success) {
            Metriqus.verboseLog(
              "✅ Android install time obtained: $installTime",
            );
            callback(installTime);
          } else {
            Metriqus.verboseLog(
              "❌ Failed to get Android install time, using current time",
            );
            callback(MetriqusUtils.getCurrentUtcTimestampSeconds());
          }
        } else {
          Metriqus.verboseLog(
            "❌ Invalid Android install time response, using current time",
          );
          callback(MetriqusUtils.getCurrentUtcTimestampSeconds());
        }
      }).catchError((error) {
        Metriqus.errorLog(
          "Error reading install time from storage: $error",
        );
        callback(MetriqusUtils.getCurrentUtcTimestampSeconds());
      });
    } catch (e) {
      Metriqus.errorLog("Error getting Android install time: $e");
      callback(MetriqusUtils.getCurrentUtcTimestampSeconds());
    }
  }

  @override
  void onFirstLaunch() {
    try {
      Metriqus.infoLog("Android First Launch");
      // Android-specific first launch logic (empty like C# version)
      _setInstallTime();
    } catch (e) {
      Metriqus.errorLog("Error on Android first launch: $e");
    }
  }

  /// Set install time in storage
  void _setInstallTime() {
    try {
      final installTime = MetriqusUtils.getCurrentUtcTimestampSeconds();
      storage?.saveData(installTimeKey, installTime.toString());
      Metriqus.verboseLog("Android install time set: $installTime");
    } catch (e) {
      Metriqus.errorLog("Error setting Android install time: $e");
    }
  }
}

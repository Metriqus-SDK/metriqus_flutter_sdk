import 'dart:io' show Platform;
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
    if (!Platform.isAndroid) {
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
    Function(MetriqusAttribution) onReadCallback,
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
          Metriqus.verboseLog(
            "✅ Android attribution referrer URL obtained: $referrerUrl",
          );

          // Parse referrer URL into MetriqusAttribution
          final attribution = MetriqusAttribution.fromReferrerUrl(referrerUrl);

          // Check if this is Meta UTM and decrypt if needed
          if (MetaAttributionUtilities.isMetaUtm(attribution.source)) {
            Metriqus.verboseLog("🔍 Meta UTM detected, decrypting...");

            final decryptedReferrerUrl =
                await MetaAttributionUtilities.decryptMetaUtm(
                  attribution.content,
                );

            if (decryptedReferrerUrl != null &&
                decryptedReferrerUrl.isNotEmpty) {
              Metriqus.verboseLog("✅ Meta UTM decrypted successfully");
              final metaAttribution = MetriqusAttribution.fromReferrerUrl(
                decryptedReferrerUrl,
              );
              onReadCallback(metaAttribution);
            } else {
              Metriqus.verboseLog(
                "❌ Meta UTM decryption failed, using original attribution",
              );
              onReadCallback(attribution);
            }
          } else {
            onReadCallback(attribution);
          }
        } else {
          final error = result['error'] ?? 'Unknown error';
          Metriqus.errorLog("❌ Failed to get Android attribution: $error");
          onError("Failed to get Android attribution: $error");
        }
      } else {
        Metriqus.errorLog("❌ Invalid Android attribution response");
        onError("Invalid Android attribution response");
      }
    } catch (e) {
      Metriqus.errorLog("❌ Error Reading Android Attribution: $e");
      onError("Error Reading Android Attribution: $e");
    }
  }

  @override
  void getInstallTime(Function(int) callback) async {
    try {
      // Try to get from storage first
      storage
          ?.loadDataAsync(installTimeKey)
          .then((storedTime) async {
            if (storedTime.isNotEmpty) {
              final installTime =
                  int.tryParse(storedTime) ??
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
              final installTime =
                  result['installTime'] ??
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
          })
          .catchError((error) {
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

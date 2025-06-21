import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../MetriqusNative.dart';
import '../../MetriqusSettings.dart';
import '../../Utilities/MetriqusUtils.dart';
import '../../EventModels/Attribution/MetriqusAttribution.dart';
import '../../ThirdParty/SimpleJSON.dart';
import '../../Metriqus.dart';

/// iOS-specific implementation of MetriqusNative
class MetriqusIOS extends MetriqusNative {
  static const String installTimeKey = "MetriqusInstallTime";

  @override
  Future<void> initSdk(MetriqusSettings settings) async {
    // Platform kontrolü - MetriqusUtils helper fonksiyonu ile güvenli şekilde
    if (!MetriqusUtils.isIOS) {
      print("MetriqusIOS can only be used on iOS platform");
      return;
    }

    metriqusSettings = settings;

    try {
      // Read advertising ID and wait for completion
      await _readAdidAsync();

      // Call base InitSdk after getting AdId
      await super.initSdk(settings);
    } catch (e) {
      print("Error initializing iOS SDK: $e");
      rethrow;
    }
  }

  /// Read advertising ID asynchronously
  Future<void> _readAdidAsync() async {
    try {
      // If tracking disabled, directly return empty string
      if (metriqusSettings?.iOSUserTrackingDisabled == true) {
        isTrackingEnabled = false;
        adId = "";
        print("iOS Ad ID tracking disabled in settings");
        return;
      }

      // Request tracking permission and get IDFA via native code
      final platform = MethodChannel('metriqus_flutter_sdk/device_info');
      final result = await platform.invokeMethod('requestTrackingPermission');

      if (result != null && result is Map) {
        final success = result['success'] ?? false;
        final idfa = result['idfa'] ?? '';
        final authorized = result['authorized'] ?? false;

        isTrackingEnabled = authorized;

        if (success && authorized && idfa.isNotEmpty) {
          adId = idfa;
          print("iOS Ad ID: $idfa");
        } else {
          adId = "";
          print("iOS Ad ID: Empty (not authorized or not available)");
        }
      } else {
        adId = "";
        print("iOS Ad ID: Empty (invalid response)");
      }
    } catch (e) {
      print("Error fetching iOS Advertising ID: $e");
      adId = "";
    }
  }

  @override
  void readAdid(Function(String) callback) {
    // This method is kept for compatibility but deprecated
    // Use _readAdidAsync instead for new code
    callback(adId ?? "");
  }

  @override
  void readAttribution(
    Function(MetriqusAttribution?) onReadCallback,
    Function(String) onError,
  ) async {
    try {
      print("🔍 ReadAttribution iOS - Starting attribution token read");

      // Get attribution token via native code
      final platform = MethodChannel('metriqus_flutter_sdk/device_info');
      final result = await platform.invokeMethod('readAttributionToken');

      if (result != null && result is Map) {
        final success = result['success'] ?? false;

        if (success) {
          final token = result['token'] ?? '';

          if (token.isNotEmpty) {
            print(
                "✅ Attribution token obtained: ${token.substring(0, min<int>(50, token.length))}...");

            // Request attribution data from Apple with token
            final attribution = await _requestAttributionData(token);
            if (attribution != null) {
              print("🎯 [DEBUG] Attribution data received from Apple:");
              print("  - attribution: ${attribution.attribution}");
              print("  - orgId: ${attribution.orgId}");
              print("  - campaignId: ${attribution.campaignId}");
              print(
                  "  - raw: ${attribution.raw?.substring(0, min<int>(50, attribution.raw?.length ?? 0))}...");

              // Only call callback if we have meaningful attribution data
              // Check if it's not just test data that was filtered out
              if (attribution.raw != "Test data filtered out" ||
                  attribution.attribution == true) {
                onReadCallback(attribution);
              } else {
                print(
                    "🎯 [DEBUG] Test data filtered out, not calling callback");
              }
            } else {
              print("🎯 [DEBUG] Attribution data is NULL from Apple API");
              // Don't call callback when attribution data is null, similar to C# code
            }
          } else {
            print("❌ Attribution Token is null or empty");
            // Don't call callback when token is null/empty, similar to C# code
          }
        } else {
          final error = result['error'] ?? 'Unknown error';
          print("❌ Failed to get attribution token: $error");
          onError("Failed to get attribution token: $error");
        }
      } else {
        print("❌ Invalid attribution token response");
        onError("Invalid attribution token response");
      }
    } catch (e) {
      print("❌ Error Reading iOS Attribution: $e");
      onError("Error Reading iOS Attribution: $e");
    }
  }

  @override
  void getInstallTime(Function(int) callback) {
    try {
      // Try to get from storage first
      storage?.loadDataAsync(installTimeKey).then((storedTime) {
        if (storedTime.isNotEmpty) {
          final installTime = int.tryParse(storedTime) ??
              MetriqusUtils.getCurrentUtcTimestampSeconds();
          callback(installTime);
          return;
        }

        // If not in storage, use current time as fallback
        final installTime = MetriqusUtils.getCurrentUtcTimestampSeconds();
        print("GetInstallTime: $installTime");
        callback(installTime);
      }).catchError((error) {
        print("Error reading install time from storage: $error");
        callback(MetriqusUtils.getCurrentUtcTimestampSeconds());
      });
    } catch (e) {
      print("Error getting iOS install time: $e");
      callback(MetriqusUtils.getCurrentUtcTimestampSeconds());
    }
  }

  @override
  void updateIOSConversionValue(int value) async {
    try {
      print("🔄 Updating iOS conversion value: $value");

      // Update conversion value via native code
      final platform = MethodChannel('metriqus_flutter_sdk/device_info');
      final result = await platform.invokeMethod('updateConversionValue', {
        'value': value,
      });

      if (result != null && result is Map) {
        final success = result['success'] ?? false;
        final message = result['message'] ?? 'Unknown result';

        if (success) {
          print("✅ iOS conversion value updated successfully: $message");
        } else {
          print("❌ iOS conversion value update failed: $message");
        }
      } else {
        print("❌ Invalid conversion value update response");
      }
    } catch (e) {
      print("❌ Error updating iOS conversion value: $e");
    }
  }

  @override
  void onFirstLaunch() {
    try {
      print("iOS First Launch");
      _setInstallTime();
      _reportAdNetworkAttribution();
    } catch (e) {
      print("Error on iOS first launch: $e");
    }
  }

  /// Request attribution data from Apple Search Ads API using token
  Future<MetriqusAttribution?> _requestAttributionData(String token) async {
    int attempts = 0;
    bool requestSuccessful = false;

    while (attempts < 3 && !requestSuccessful) {
      attempts++;

      try {
        print("🔄 Attribution request attempt $attempts/3");

        // HTTP POST request to Apple Search Ads API
        final response = await http.post(
          Uri.parse('https://api-adservices.apple.com/api/v1/'),
          headers: {'Content-Type': 'text/plain'},
          body: token,
        );

        if (response.statusCode == 200) {
          final responseBody = response.body;
          print("✅ FULL Attribution Response Body: $responseBody");

          requestSuccessful = true;
          final attribution = MetriqusAttribution.parse(responseBody);

          // Log parsed attribution data
          if (attribution != null) {
            print("📊 Final Attribution Data (after filtering):");
            print("  - orgId: ${attribution.orgId}");
            print("  - campaignId: ${attribution.campaignId}");
            print("  - adGroupId: ${attribution.adGroupId}");
            print("  - adId: ${attribution.adId}");
            print("  - keywordId: ${attribution.keywordId}");
            print("  - attribution: ${attribution.attribution}");
            print("  - conversionType: ${attribution.conversionType}");
            print("  - clickDate: ${attribution.clickDate}");
            print("  - countryOrRegion: ${attribution.countryOrRegion}");
            print("  - raw: ${attribution.raw}");

            if (attribution.attribution == false &&
                attribution.raw == "Test data filtered out") {
              print("✅ Test data was successfully filtered out");
            } else if (attribution.attribution == true) {
              print("✅ Real attribution data detected");
            } else {
              print("ℹ️ No attribution available");
            }
          }

          return attribution;
        } else if (response.statusCode == 404) {
          print("⚠️ 404 Not Found. Retrying...");
          if (attempts < 3) {
            await Future.delayed(
              Duration(seconds: 5),
            ); // 5 sec between every try
          }
        } else if (response.statusCode == 400) {
          print("❌ Attribution Status code 400. The token is invalid.");
          break;
        } else if (response.statusCode == 500) {
          print(
            "❌ Attribution Status code 500. Apple Search Ads server is temporarily down or unreachable.",
          );
          break;
        } else {
          print("❌ Error: ${response.statusCode} - ${response.reasonPhrase}");
          break;
        }
      } catch (ex) {
        print("❌ Exception: ${ex.toString()}");
        break;
      }
    }

    if (!requestSuccessful) {
      print(
        "❌ Attribution Request failed to get a successful response after multiple attempts.",
      );
    }

    // Return null on failure, similar to C# code
    return null;
  }

  /// Set install time in storage
  void _setInstallTime() {
    try {
      final installTime = MetriqusUtils.getCurrentUtcTimestampSeconds();
      storage?.saveData(installTimeKey, installTime.toString());
    } catch (e) {
      print("Error setting install time: $e");
    }
  }

  /// Report ad network attribution to Apple
  void _reportAdNetworkAttribution() async {
    try {
      print("🚀 ReportAdNetworkAttribution - Starting SKAdNetwork attribution");

      // Native iOS SKAdNetwork attribution reporting via method channel
      final platform = MethodChannel('metriqus_flutter_sdk/device_info');
      final result = await platform.invokeMethod('reportAdNetworkAttribution');

      if (result != null && result is Map) {
        final success = result['success'] ?? false;
        final message = result['message'] ?? 'Unknown result';

        if (success) {
          print("✅ SKAdNetwork attribution reported successfully: $message");
        } else {
          print("❌ SKAdNetwork attribution reporting failed: $message");
        }
      } else {
        print("❌ SKAdNetwork attribution reporting failed: Invalid response");
      }
    } catch (e) {
      print("❌ Error reporting ad network attribution: $e");
    }
  }
}

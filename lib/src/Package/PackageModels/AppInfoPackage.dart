import 'dart:convert';
import '../../ThirdParty/SimpleJSON.dart';
import '../../Metriqus.dart';
import '../../MetriqusSettings.dart';

/// Represents application information package
class AppInfoPackage {
  static const String packageNameKey = "package_name";
  static const String appVersionKey = "app_version";

  String? packageName;
  String? appVersion;

  /// Constructor with package name and app version
  AppInfoPackage(String packageName, String appVersion) {
    this.packageName = packageName;
    this.appVersion = appVersion;
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      packageNameKey: packageName,
      appVersionKey: appVersion,
    };
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Parse from JSON node
  static AppInfoPackage? parseJson(JSONNode jsonNode) {
    try {
      final packageName = MetriqusJSON.getJsonString(jsonNode, packageNameKey);
      final appVersion = MetriqusJSON.getJsonString(jsonNode, appVersionKey);

      if (packageName != null && appVersion != null) {
        return AppInfoPackage(packageName, appVersion);
      }
      return null;
    } catch (e) {
      Metriqus.errorLog("AppInfoPackage parseJson failed: ${e.toString()}");
      return null;
    }
  }

  /// Get current app info
  static AppInfoPackage? getCurrentAppInfo() {
    try {
      // For now, return empty values since package info should come from platform
      return AppInfoPackage('', '');
    } catch (e) {
      Metriqus.errorLog("getCurrentAppInfo failed: ${e.toString()}");
      return null;
    }
  }

  /// Creates instance from JSON map
  factory AppInfoPackage.fromJson(Map<String, dynamic> json) {
    return AppInfoPackage(
      json[packageNameKey] ?? '',
      json[appVersionKey] ?? '',
    );
  }
}

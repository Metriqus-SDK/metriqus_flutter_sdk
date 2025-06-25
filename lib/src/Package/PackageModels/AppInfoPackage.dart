import 'package:package_info_plus/package_info_plus.dart';
import '../../Metriqus.dart';

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

  /// Get current app info
  static Future<AppInfoPackage?> getCurrentAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      return AppInfoPackage(
        packageInfo.packageName,
        packageInfo.version,
      );
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

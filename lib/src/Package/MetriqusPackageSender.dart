import '../EventModels/CustomEvents/MetriqusCustomEvent.dart';
import '../EventModels/MetriqusInAppRevenue.dart';
import '../EventModels/AdRevenue/MetriqusAdRevenue.dart';
import '../EventModels/Attribution/MetriqusAttribution.dart';
import '../EventLogger/MetriqusLogger.dart';
import '../Metriqus.dart';
import 'IPackageSender.dart';
import 'PackageBuilder.dart';

/// Implementation of package sender for Metriqus events
class MetriqusPackageSender implements IPackageSender {
  @override
  Future<void> sendCustomPackage(MetriqusCustomEvent customEvent) async {
    try {
      final settings = Metriqus.getMetriqusSettings();

      if (settings == null) {
        Metriqus.errorLog("Settings not available");
        return;
      }

      // During initialization, get device info directly from native
      final native = Metriqus.native;
      final deviceInfo = native?.getDeviceInfo;

      if (deviceInfo == null) {
        Metriqus.verboseLog(
          "Device info not yet available, skipping package send",
        );
        return;
      }

      final builder = PackageBuilder(settings, deviceInfo);
      final package = await builder.buildCustomEventPackage(customEvent);

      MetriqusLogger.logPackage(package);
    } catch (e) {
      Metriqus.errorLog("Error sending custom package: $e");
    }
  }

  @override
  Future<void> sendSessionStartPackage() async {
    try {
      final settings = Metriqus.getMetriqusSettings();

      if (settings == null) {
        Metriqus.errorLog("Settings not available");
        return;
      }

      // During initialization, get device info directly from native
      final native = Metriqus.native;
      final deviceInfo = native?.getDeviceInfo;

      if (deviceInfo == null) {
        Metriqus.verboseLog(
          "Device info not yet available, skipping package send",
        );
        return;
      }

      final builder = PackageBuilder(settings, deviceInfo);
      final package = await builder.buildSessionStartPackage();

      MetriqusLogger.logPackage(package);
    } catch (e) {
      Metriqus.errorLog("Error sending session start package: $e");
    }
  }

  @override
  Future<void> sendSessionBeatPackage() async {
    try {
      final settings = Metriqus.getMetriqusSettings();

      if (settings == null) {
        Metriqus.errorLog("Settings not available");
        return;
      }

      // During initialization, get device info directly from native
      final native = Metriqus.native;
      final deviceInfo = native?.getDeviceInfo;

      if (deviceInfo == null) {
        Metriqus.verboseLog(
          "Device info not yet available, skipping package send",
        );
        return;
      }

      final builder = PackageBuilder(settings, deviceInfo);
      final package = await builder.buildSessionBeatPackage();

      MetriqusLogger.logPackage(package);
    } catch (e) {
      Metriqus.errorLog("Error sending session beat package: $e");
    }
  }

  @override
  Future<void> sendIAPEventPackage(MetriqusInAppRevenue metriqusEvent) async {
    try {
      final settings = Metriqus.getMetriqusSettings();

      if (settings == null) {
        Metriqus.errorLog("Settings not available");
        return;
      }

      // During initialization, get device info directly from native
      final native = Metriqus.native;
      final deviceInfo = native?.getDeviceInfo;

      if (deviceInfo == null) {
        Metriqus.verboseLog(
          "Device info not yet available, skipping package send",
        );
        return;
      }

      final builder = PackageBuilder(settings, deviceInfo);
      final package = await builder.buildIAPEventPackage(metriqusEvent);

      MetriqusLogger.logPackage(package);
    } catch (e) {
      Metriqus.errorLog("Error sending IAP event package: $e");
    }
  }

  @override
  Future<void> sendAdRevenuePackage(MetriqusAdRevenue adRevenue) async {
    try {
      final settings = Metriqus.getMetriqusSettings();

      if (settings == null) {
        Metriqus.errorLog("Settings not available");
        return;
      }

      // During initialization, get device info directly from native
      final native = Metriqus.native;
      final deviceInfo = native?.getDeviceInfo;

      if (deviceInfo == null) {
        Metriqus.verboseLog(
          "Device info not yet available, skipping package send",
        );
        return;
      }

      final builder = PackageBuilder(settings, deviceInfo);
      final package = await builder.buildAdRevenueEventPackage(adRevenue);

      MetriqusLogger.logPackage(package);
    } catch (e) {
      Metriqus.errorLog("Error sending ad revenue package: $e");
    }
  }

  @override
  Future<void> sendAttributionPackage(MetriqusAttribution attribution) async {
    try {
      final settings = Metriqus.getMetriqusSettings();

      if (settings == null) {
        Metriqus.errorLog("Settings not available");
        return;
      }

      // During initialization, get device info directly from native
      final native = Metriqus.native;
      final deviceInfo = native?.getDeviceInfo;

      if (deviceInfo == null) {
        Metriqus.verboseLog(
          "Device info not yet available, skipping package send",
        );
        return;
      }

      final builder = PackageBuilder(settings, deviceInfo);
      final package = await builder.buildAttributionPackage(attribution);

      MetriqusLogger.logPackage(package, sendImmediately: true);
    } catch (e) {
      Metriqus.errorLog("Error sending attribution package: $e");
    }
  }

  @override
  void dispose() {
    // This class doesn't hold resources that need disposal,
    // but we implement the method to satisfy the interface.
  }
}

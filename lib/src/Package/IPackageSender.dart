import '../EventModels/CustomEvents/MetriqusCustomEvent.dart';
import '../EventModels/MetriqusInAppRevenue.dart';
import '../EventModels/AdRevenue/MetriqusAdRevenue.dart';
import '../EventModels/Attribution/MetriqusAttribution.dart';

/// Interface for package sender implementations
abstract class IPackageSender {
  Future<void> sendCustomPackage(MetriqusCustomEvent customEvent);
  Future<void> sendSessionStartPackage();
  Future<void> sendSessionBeatPackage();
  Future<void> sendIAPEventPackage(MetriqusInAppRevenue metriqusEvent);
  Future<void> sendAdRevenuePackage(MetriqusAdRevenue adRevenue);
  Future<void> sendAttributionPackage(MetriqusAttribution attribution);
  void dispose();
}

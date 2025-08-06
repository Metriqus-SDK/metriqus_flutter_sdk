/// Ad unit types for Metriqus
enum MetriqusAdUnit {
  banner,
  interstitial,
  rewarded,
  rewardedInterstitial,
  nativeAdvenced,
  appOpen;

  /// Converts enum to string value
  String get value {
    switch (this) {
      case MetriqusAdUnit.banner:
        return "banner";
      case MetriqusAdUnit.interstitial:
        return "interstitial";
      case MetriqusAdUnit.rewarded:
        return "rewarded";
      case MetriqusAdUnit.rewardedInterstitial:
        return "rewarded_interstitial";
      case MetriqusAdUnit.nativeAdvenced:
        return "native_advenced";
      case MetriqusAdUnit.appOpen:
        return "app_open";
    }
  }

  /// Creates enum from string value
  static MetriqusAdUnit? fromString(String? value) {
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'banner':
        return MetriqusAdUnit.banner;
      case 'interstitial':
        return MetriqusAdUnit.interstitial;
      case 'rewarded':
        return MetriqusAdUnit.rewarded;
      case 'rewarded_interstitial':
        return MetriqusAdUnit.rewardedInterstitial;
      case 'native_advenced':
        return MetriqusAdUnit.nativeAdvenced;
      case 'app_open':
        return MetriqusAdUnit.appOpen;
      default:
        return null;
    }
  }
}

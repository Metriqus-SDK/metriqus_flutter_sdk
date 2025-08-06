import 'MetriqusAdRevenue.dart';
import '../../Utilities/MetriqusAdUnit.dart';

/// Represents ad revenue from AdMob network, including source, earnings, currency, impressions, and network details.
class MetriqusAdmobAdRevenue extends MetriqusAdRevenue {
  static const String _source = "google admob";

  /// Default constructor
  MetriqusAdmobAdRevenue(MetriqusAdUnit adUnit)
      : super.withSource(_source, adUnit);

  /// Constructor with revenue and currency
  MetriqusAdmobAdRevenue.withRevenue(
      double revenue, String currency, MetriqusAdUnit adUnit)
      : super.withRevenue(revenue, currency, adUnit, source: _source);
}

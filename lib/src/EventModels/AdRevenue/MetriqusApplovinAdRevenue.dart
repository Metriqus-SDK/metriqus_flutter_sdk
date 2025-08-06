import 'MetriqusAdRevenue.dart';
import '../../Utilities/MetriqusAdUnit.dart';

/// Represents ad revenue from AppLovin network, including source, earnings, currency, impressions, and network details.
class MetriqusApplovinAdRevenue extends MetriqusAdRevenue {
  static const String _source = "applovin";

  /// Default constructor
  MetriqusApplovinAdRevenue(MetriqusAdUnit adUnit)
      : super.withSource(_source, adUnit);

  /// Constructor with revenue and currency
  MetriqusApplovinAdRevenue.withRevenue(
      double revenue, String currency, MetriqusAdUnit adUnit)
      : super.withRevenue(revenue, currency, adUnit, source: _source);
}

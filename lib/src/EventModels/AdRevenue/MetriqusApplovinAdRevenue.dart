import 'MetriqusAdRevenue.dart';

/// Represents ad revenue from AppLovin network, including source, earnings, currency, impressions, and network details.
class MetriqusApplovinAdRevenue extends MetriqusAdRevenue {
  static const String _source = "applovin";

  /// Default constructor
  MetriqusApplovinAdRevenue() : super.withSource(_source);

  /// Constructor with revenue and currency
  MetriqusApplovinAdRevenue.withRevenue(double revenue, String currency)
      : super.withRevenue(_source, revenue, currency);
}

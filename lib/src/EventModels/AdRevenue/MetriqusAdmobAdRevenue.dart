import 'MetriqusAdRevenue.dart';

/// Represents ad revenue from AdMob network, including source, earnings, currency, impressions, and network details.
class MetriqusAdmobAdRevenue extends MetriqusAdRevenue {
  static const String _source = "google admob";

  /// Default constructor
  MetriqusAdmobAdRevenue() : super.withSource(_source);

  /// Constructor with revenue and currency
  MetriqusAdmobAdRevenue.withRevenue(double revenue, String currency)
      : super.withRevenue(_source, revenue, currency);
}

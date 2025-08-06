import '../../Utilities/MetriqusAdUnit.dart';

/// Represents ad revenue data, including source, earnings, currency, impressions, and network details.
class MetriqusAdRevenue {
  /// The source of the ad revenue data (e.g., platform or provider).
  String? _source;

  /// The revenue generated from ads, if available.
  double? _revenue;

  /// The currency in which the revenue is reported.
  String? _currency;

  /// The total number of ad impressions recorded, if available.
  int? adImpressionsCount;

  /// The network through which the ad revenue was generated.
  String? adRevenueNetwork;

  /// The specific ad unit generating the revenue.
  MetriqusAdUnit? adRevenueUnit;

  /// The placement of the ad that contributed to the revenue.
  String? adRevenuePlacement;

  // Getters and Setters
  String? get source => _source;
  set source(String? value) => _source = value;

  double? get revenue => _revenue;
  String? get currency => _currency;

  /// Default constructor
  MetriqusAdRevenue();

  /// Initializes a new instance with the specified source.
  MetriqusAdRevenue.withSource(String source, MetriqusAdUnit adUnit) {
    _source = source;
    adRevenueUnit = adUnit;
  }

  /// Initializes a new instance with revenue details (source is optional parameter)
  MetriqusAdRevenue.withRevenue(
      double revenue, String currency, MetriqusAdUnit adUnit,
      {String? source}) {
    _source = source;
    _revenue = revenue;
    _currency = currency;
    adRevenueUnit = adUnit;
  }

  /// Gets the source of the ad revenue data.
  String? getSource() => _source;

  /// Sets or updates the revenue and currency for this ad revenue record.
  void setRevenue(double revenue, String currency) {
    _revenue = revenue;
    _currency = currency;
  }

  /// Sets the ad unit
  void setAdUnit(MetriqusAdUnit adUnit) {
    adRevenueUnit = adUnit;
  }

  /// Converts the ad revenue data to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'source': _source,
      'revenue': _revenue,
      'currency': _currency,
      'adImpressionsCount': adImpressionsCount,
      'adRevenueNetwork': adRevenueNetwork,
      'adRevenueUnit': adRevenueUnit?.value,
      'adRevenuePlacement': adRevenuePlacement,
    };
  }

  /// Creates an instance from a JSON map.
  factory MetriqusAdRevenue.fromJson(Map<String, dynamic> json) {
    final adRevenue = MetriqusAdRevenue();
    adRevenue._source = json['source'];
    adRevenue._revenue = json['revenue']?.toDouble();
    adRevenue._currency = json['currency'];
    adRevenue.adImpressionsCount = json['adImpressionsCount'];
    adRevenue.adRevenueNetwork = json['adRevenueNetwork'];
    adRevenue.adRevenueUnit = MetriqusAdUnit.fromString(json['adRevenueUnit']);
    adRevenue.adRevenuePlacement = json['adRevenuePlacement'];
    return adRevenue;
  }
}

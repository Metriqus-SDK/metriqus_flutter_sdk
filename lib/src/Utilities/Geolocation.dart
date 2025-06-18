/// Represents geolocation information
class Geolocation {
  String country;
  String countryCode;
  String city;
  String region;
  String regionName;

  Geolocation({
    required this.country,
    required this.countryCode,
    required this.city,
    required this.region,
    required this.regionName,
  });

  /// Create from JSON map
  static Geolocation fromJson(Map<String, dynamic> json) {
    return Geolocation(
      country: json['country'] ?? '',
      countryCode: json['countryCode'] ?? '',
      city: json['city'] ?? '',
      region: json['region'] ?? '',
      regionName: json['regionName'] ?? '',
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'countryCode': countryCode,
      'city': city,
      'region': region,
      'regionName': regionName,
    };
  }
}

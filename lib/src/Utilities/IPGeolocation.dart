import 'package:dio/dio.dart';
import '../Metriqus.dart';
import 'Geolocation.dart';

/// IP-based geolocation service
class IPGeolocation {
  static const String _apiUrl = 'http://ip-api.com/json/';

  /// Get geolocation data using IP API
  static Future<Geolocation?> getGeolocation() async {
    try {
      Metriqus.verboseLog('🌍 Attempting to fetch geolocation from: $_apiUrl');

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      // Make HTTP request to IP API
      final response = await dio.get(_apiUrl);

      if (response.statusCode == 200 && response.data != null) {
        Metriqus.verboseLog('🌍 API response status: ${response.statusCode}');

        final data = response.data;

        if (data['status'] == 'success') {
          return Geolocation(
            country: data['country'] ?? '',
            countryCode: data['countryCode'] ?? '',
            city: data['city'] ?? '',
            region: data['region'] ?? '',
            regionName: data['regionName'] ?? '',
          );
        }
      }
    } catch (e) {
      Metriqus.errorLog('❌ Error getting geolocation: $e');
    }

    return null;
  }
}

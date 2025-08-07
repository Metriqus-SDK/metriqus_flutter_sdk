import 'package:dio/dio.dart';
import '../Metriqus.dart';
import 'Geolocation.dart';

/// IP-based geolocation service
class IPGeolocation {
  static const String _apiUrl = 'https://sdk.metriqus.com/event/geo';

  /// Get geolocation data using IP API
  static Future<Geolocation?> getGeolocation() async {
    try {
      Metriqus.verboseLog('🌍 Attempting to fetch geolocation from: $_apiUrl');

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 60);
      dio.options.receiveTimeout = const Duration(seconds: 60);

      // Make HTTP request to IP API
      final response = await dio.get(_apiUrl);

      if (response.statusCode == 200 && response.data != null) {
        Metriqus.verboseLog('🌍 API response status: ${response.statusCode}');

        final data = response.data;

        if (data is Map && data.containsKey('data') && data['data'] is Map) {
          final geoData = data['data'] as Map<String, dynamic>;
          return Geolocation(
            country: geoData['country']?.toString() ?? '',
            countryCode: geoData['countryCode']?.toString() ?? '',
            city: geoData['city']?.toString() ?? '',
            region: geoData['region']?.toString() ?? '',
            regionName: geoData['regionName']?.toString() ?? '',
          );
        }
      }
    } catch (e) {
      Metriqus.errorLog('❌ Error getting geolocation: $e');
    }

    return null;
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../Metriqus.dart';

/// Checks internet connectivity status
class InternetConnectionChecker {
  static const String _testUrl = "https://www.google.com";

  void Function()? onConnectedToInternet;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  DateTime? _lastCheckTime;
  bool _lastResult = false;

  /// Check internet connection availability
  Future<bool> checkInternetConnection() async {
    try {
      if (_lastCheckTime != null &&
          DateTime.now().difference(_lastCheckTime!).inSeconds < 30) {
        return _lastResult;
      }

      // First check connectivity status
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        Metriqus.verboseLog("No Internet connection (device unreachable).");
        _lastResult = false;
        _lastCheckTime = DateTime.now();
        return false;
      } else {
        _isConnected = await _checkInternetConnectionViaRequest();

        // Cache the result
        _lastResult = _isConnected;
        _lastCheckTime = DateTime.now();

        if (_isConnected) {
          onConnectedToInternet?.call();
        }

        return _isConnected;
      }
    } catch (e) {
      Metriqus.errorLog("Error checking internet connection: $e");
      _lastResult = false;
      _lastCheckTime = DateTime.now();
      return false;
    }
  }

  /// Check internet connection by making an actual HTTP request
  Future<bool> _checkInternetConnectionViaRequest() async {
    try {
      final client = http.Client();
      final response =
          await client.head(Uri.parse(_testUrl)).timeout(Duration(seconds: 10));
      client.close();

      final isSuccess = response.statusCode >= 200 && response.statusCode < 400;
      return isSuccess;
    } catch (e) {
      Metriqus.errorLog("Internet connection check failed: $e");
      return false;
    }
  }

  /// Simple connectivity check without HTTP request
  static Future<bool> hasConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
}

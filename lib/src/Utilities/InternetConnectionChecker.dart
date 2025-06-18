import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../WebRequest/RequestSender.dart';
import '../WebRequest/Response.dart';
import '../Metriqus.dart';

/// Checks internet connectivity status
class InternetConnectionChecker {
  static const String _testUrl = "https://www.google.com";

  void Function()? onConnectedToInternet;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Check internet connection availability
  Future<bool> checkInternetConnection() async {
    try {
      // First check connectivity status
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        Metriqus.verboseLog("No Internet connection (device unreachable).");
        return false;
      } else {
        _isConnected = await _checkInternetConnectionViaRequest();

        if (_isConnected) {
          onConnectedToInternet?.call();
        }

        return _isConnected;
      }
    } catch (e) {
      Metriqus.errorLog("Error checking internet connection: $e");
      return false;
    }
  }

  /// Check internet connection by making an actual HTTP request
  Future<bool> _checkInternetConnectionViaRequest() async {
    try {
      final response = await RequestSender.getAsync(_testUrl);

      if (!response.isSuccess) {
        if (response.errorType == ErrorType.connectionError) {
          return false;
        }
      }

      return true;
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

import 'package:http/http.dart' as http;
import 'Response.dart';
import '../Metriqus.dart';

/// Wrapper class for sending web requests using HTTP package
class RequestSender {
  static const String contentTypeJson = "application/json";

  /// Send GET request
  static Future<Response> getAsync(String url, {Map<String, String>? headers, int timeout = 0}) async {
    try {
      final uri = Uri.parse(url);
      final client = http.Client();

      // Prepare headers with connection and user-agent hints for middleboxes/WAFs
      final requestHeaders = {
        'Connection': 'close',
        'User-Agent': 'MetriqusFlutterSDK',
        ...?headers,
      };

      http.Response response;
      if (timeout > 0) {
        response = await client.get(uri, headers: requestHeaders).timeout(Duration(seconds: timeout));
      } else {
        response = await client.get(uri, headers: requestHeaders);
      }

      client.close();

      List<String> errors = [];
      ErrorType errorType = ErrorType.noError;

      if (response.statusCode >= 400) {
        errorType = ErrorType.protocolError;
        errors.add('HTTP ${response.statusCode}: ${response.reasonPhrase}');

        Metriqus.errorLog("HTTP (protocol error) error: ${response.statusCode}, url: $url");
      }

      return Response(
        statusCode: response.statusCode,
        data: response.body,
        errors: errors.isNotEmpty ? errors : null,
        errorType: errorType,
      );
    } catch (e) {
      Metriqus.errorLog("Connection error: $e, url: $url");

      return Response(
        statusCode: 0,
        data: "",
        errors: [e.toString()],
        errorType: ErrorType.connectionError,
      );
    }
  }

  /// Send POST request
  static Future<Response> postAsync(String url, String jsonBody,
      {Map<String, String>? headers, int timeoutSeconds = 60}) async {
    try {
      // Log the outgoing request
      Metriqus.networkLog("POST_REQUEST", url, requestBody: jsonBody);

      final uri = Uri.parse(url);
      final client = http.Client();

      Map<String, String> requestHeaders = {
        'Content-Type': contentTypeJson,
        'Connection': 'close',
        'User-Agent': 'MetriqusFlutterSDK',
        ...?headers,
      };

      final response = await client
          .post(
            uri,
            headers: requestHeaders,
            body: jsonBody,
          )
          .timeout(Duration(seconds: timeoutSeconds));

      client.close();

      // Log the response
      Metriqus.networkLog("POST_RESPONSE", url, responseBody: response.body, statusCode: response.statusCode);

      List<String> errors = [];
      ErrorType errorType = ErrorType.noError;

      if (response.statusCode >= 400) {
        errorType = ErrorType.protocolError;
        errors.add('HTTP ${response.statusCode}: ${response.reasonPhrase}');

        Metriqus.errorLog("HTTP (protocol error) error: ${response.statusCode}, url: $url");
      }

      return Response(
        statusCode: response.statusCode,
        data: response.body,
        errors: errors.isNotEmpty ? errors : null,
        errorType: errorType,
      );
    } catch (e) {
      Metriqus.errorLog("Connection error: $e, url: $url");

      return Response(
        statusCode: 0,
        data: "",
        errors: [e.toString()],
        errorType: ErrorType.connectionError,
      );
    }
  }

  /// Add Authorization header with Bearer token
  static void addAuthorization(Map<String, String> headers, String token) {
    headers["Authorization"] = "Bearer $token";
  }

  /// Add Content-Type header
  static void addContentType(Map<String, String> headers, String contentType) {
    headers["Content-Type"] = contentType;
  }

  /// Add Accept header
  static void addAccept(Map<String, String> headers, String acceptType) {
    headers["Accept"] = acceptType;
  }

  /// Add custom header
  static void addCustomHeader(Map<String, String> headers, String key, String value) {
    headers[key] = value;
  }

  /// Add User-Agent header
  static void addUserAgent(Map<String, String> headers, String userAgent) {
    headers["User-Agent"] = userAgent;
  }
}

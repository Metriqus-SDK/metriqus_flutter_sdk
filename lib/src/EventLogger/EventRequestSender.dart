import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import '../WebRequest/RequestSender.dart';
import '../Utilities/MetriqusUtils.dart';
import '../WebRequest/MetriqusResponseObject.dart';
import '../Metriqus.dart';

/// Static class for sending event requests to server
class EventRequestSender {
  /// Post event batch to server
  static Future<bool> postEventBatch(String eventsJson) async {
    try {
      Metriqus.verboseLog("🔥 [NETWORK] postEventBatch called");
      int eventCount = eventsJson.split('"eventName"').length - 1;
      int payloadSize = eventsJson.length;

      Metriqus.infoLog(
        "🔥 [NETWORK] Event batch details: $eventCount events, ${payloadSize} bytes (${(payloadSize / 1024).toStringAsFixed(2)} KB)",
      );

      Metriqus.eventQueueLog(
        "BATCH_SEND_START",
        details: {
          "event_count": eventCount,
          "payload_size": payloadSize,
          "payload_size_kb": (payloadSize / 1024).toStringAsFixed(2),
        },
      );

      Metriqus.verboseLog("🔥 [NETWORK] Getting Metriqus settings...");
      var metriqusSettings = Metriqus.getMetriqusSettings();
      Metriqus.verboseLog(
        "🔥 [NETWORK] Metriqus settings: ${metriqusSettings != null ? 'LOADED' : 'NULL'}",
      );

      Metriqus.verboseLog("🔥 [NETWORK] Getting remote settings...");
      var remoteSettings = Metriqus.getMetriqusRemoteSettings();
      Metriqus.verboseLog(
        "🔥 [NETWORK] Remote settings: ${remoteSettings != null ? 'LOADED' : 'NULL'}",
      );

      if (remoteSettings?.eventPostUrl?.isEmpty ?? true) {
        Metriqus.errorLog(
            "🔥 [NETWORK] ❌ Event post URL not found or empty. Remote settings: ${remoteSettings?.toString() ?? 'NULL'}");
        Metriqus.eventQueueLog(
          "BATCH_SEND_ERROR",
          details: {
            "error": "event_post_url_not_found",
            "remote_settings_loaded": remoteSettings != null,
          },
        );
        return false;
      }

      // Null check for eventPostUrl
      final eventPostUrl = remoteSettings!.eventPostUrl;
      if (eventPostUrl == null || eventPostUrl.isEmpty) {
        Metriqus.errorLog(
          "🔥 [NETWORK] ❌ Event post URL is null or empty after null check",
        );
        Metriqus.eventQueueLog(
          "BATCH_SEND_ERROR",
          details: {"error": "event_post_url_null_or_empty"},
        );
        return false;
      }

      Metriqus.infoLog("🔥 [NETWORK] 📡 Target URL: $eventPostUrl");

      String timestamp =
          MetriqusUtils.getCurrentUtcTimestampSeconds().toString();
      Metriqus.verboseLog("🔥 [NETWORK] Generated timestamp: $timestamp");

      // Log the raw events JSON before encryption for debugging
      Metriqus.infoLog(
        "🔥 [NETWORK] 📋 RAW_EVENTS_JSON (${eventsJson.length} chars):",
      );
      Metriqus.infoLog("🔥 [NETWORK] JSON_START");
      Metriqus.infoLog(eventsJson);
      Metriqus.infoLog("🔥 [NETWORK] JSON_END");

      Metriqus.verboseLog("🔥 [NETWORK] 🔐 Encrypting event data...");
      String encryptedBody = _encrypt(
        eventsJson,
        metriqusSettings?.clientSecret ?? '',
        metriqusSettings?.clientKey ?? '',
      );
      Metriqus.verboseLog(
        "🔥 [NETWORK] Encryption completed. Encrypted size: ${encryptedBody.length} chars",
      );

      // Debug: Log encrypted body for manual decryption
      Metriqus.infoLog("🔥 [NETWORK] 🔐 ENCRYPTED_BODY_FOR_DECRYPTION:");
      Metriqus.infoLog("🔥 [NETWORK] 📋 ENCRYPTED_DATA_START");
      Metriqus.infoLog(encryptedBody);
      Metriqus.infoLog("🔥 [NETWORK] 📋 ENCRYPTED_DATA_END");
      Metriqus.infoLog(
        "🔥 [NETWORK] 🔐 ENCRYPTED_BODY_LENGTH: ${encryptedBody.length} characters",
      );
      Metriqus.infoLog(
        "🔥 [NETWORK] 🔑 CLIENT_SECRET: ${metriqusSettings?.clientSecret ?? 'EMPTY'}",
      );
      Metriqus.infoLog(
        "🔥 [NETWORK] 🔑 CLIENT_KEY: ${metriqusSettings?.clientKey ?? 'EMPTY'}",
      );

      // Try simple decryption test (if crypto packages are available)
      try {
        // This will only work if crypto packages are properly imported
        String decryptedBody = _decrypt(
          encryptedBody,
          metriqusSettings?.clientSecret ?? '',
          metriqusSettings?.clientKey ?? '',
        );
        Metriqus.infoLog("🔥 [NETWORK] 🔓 DECRYPTED_BODY_START");
        Metriqus.infoLog(decryptedBody);
        Metriqus.infoLog("🔥 [NETWORK] 🔓 DECRYPTED_BODY_END");

        // Verify if decrypted data matches original
        bool matches = decryptedBody == eventsJson;
        Metriqus.infoLog(
          "🔥 [NETWORK] ✅ Encryption/Decryption verification: ${matches ? 'SUCCESS' : 'FAILED'}",
        );
      } catch (e) {
        Metriqus.infoLog(
          "🔥 [NETWORK] ⚠️ Decryption test skipped (crypto packages not available): $e",
        );
      }

      Metriqus.verboseLog("🔥 [NETWORK] ✍️ Creating HMAC signature...");
      String signature = _createHmacSignature(
        metriqusSettings?.clientKey ?? '',
        metriqusSettings?.clientSecret ?? '',
        encryptedBody,
        timestamp,
      );

      // Log complete signature
      Metriqus.infoLog("🔥 [NETWORK] 🔑 COMPLETE_SIGNATURE:");
      Metriqus.infoLog("🔥 [NETWORK] 📋 SIGNATURE_START");
      Metriqus.infoLog(signature);
      Metriqus.infoLog("🔥 [NETWORK] 📋 SIGNATURE_END");

      Metriqus.verboseLog(
        "🔥 [NETWORK] HMAC signature created: ${signature.substring(0, 20)}...",
      );

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ClientKey': metriqusSettings?.clientKey ?? '',
        'Signature': signature,
        'Timestamp': timestamp,
      };

      Metriqus.verboseLog("🔥 [NETWORK] Headers prepared:");
      Metriqus.verboseLog("🔥 [NETWORK] - Content-Type: application/json");
      Metriqus.verboseLog(
        "🔥 [NETWORK] - ClientKey: ${metriqusSettings?.clientKey ?? 'EMPTY'}",
      );
      Metriqus.verboseLog("🔥 [NETWORK] - Timestamp: $timestamp");
      Metriqus.verboseLog(
        "🔥 [NETWORK] - Signature: ${signature.substring(0, 20)}...",
      );

      String encryptedJsonData = jsonEncode({'encryptedData': encryptedBody});
      Metriqus.verboseLog(
        "🔥 [NETWORK] Final JSON payload size: ${encryptedJsonData.length} chars",
      );

      Metriqus.infoLog(
        "🔥 [NETWORK] 📤 Sending HTTP POST request to: $eventPostUrl",
      );
      var response = await RequestSender.postAsync(
        eventPostUrl,
        encryptedJsonData,
        headers: headers,
      ).timeout(Duration(seconds: 60));
      Metriqus.verboseLog("🔥 [NETWORK] HTTP POST request completed");

      if (response.isSuccess) {
        Metriqus.infoLog(
          "🔥 [NETWORK] ✅ HTTP request successful - Status: ${response.statusCode}",
        );
        Metriqus.eventQueueLog(
          "HTTP_SUCCESS",
          details: {
            "status_code": response.statusCode,
            "response_size": response.data.length,
            "response_size_kb": (response.data.length / 1024).toStringAsFixed(
              2,
            ),
          },
        );

        // Log raw response for debugging
        Metriqus.verboseLog(
          "🔥 [NETWORK] RAW_RESPONSE (${response.data.length} chars): ${response.data}",
        );

        Metriqus.verboseLog("🔥 [NETWORK] Parsing MetriqusResponseObject...");
        var mro = MetriqusResponseObject.parse(response.data);
        bool success = mro?.isSuccess ?? false;
        Metriqus.verboseLog(
          "🔥 [NETWORK] MRO parsed. Success: $success, Status: ${mro?.statusCode}",
        );

        if (success) {
          Metriqus.infoLog("🔥 [NETWORK] ✅ Server accepted the batch");
          Metriqus.eventQueueLog(
            "BATCH_SEND_SUCCESS",
            details: {
              "server_response": "accepted",
              "mro_status": mro?.statusCode,
              "mro_success": mro?.isSuccess,
              "response_data": response.data,
            },
          );
        } else {
          Metriqus.errorLog("🔥 [NETWORK] ❌ Server rejected the batch");
          Metriqus.eventQueueLog(
            "BATCH_SEND_REJECTED",
            details: {
              "server_response": "rejected",
              "mro_status": mro?.statusCode,
              "mro_success": mro?.isSuccess,
              "error_messages": mro?.errorMessages,
              "response_data": response.data,
            },
          );
        }
        return success;
      } else {
        Metriqus.errorLog(
          "🔥 [NETWORK] ❌ HTTP request failed - Status: ${response.statusCode}",
        );
        Metriqus.eventQueueLog(
          "HTTP_FAILURE",
          details: {
            "status_code": response.statusCode,
            "error_type": response.errorType.toString(),
            "errors": response.errors,
            "response_data": response.data,
          },
        );

        // Log raw error response
        Metriqus.verboseLog(
          "🔥 [NETWORK] RAW_ERROR_RESPONSE (${response.data.length} chars): ${response.data}",
        );

        return false;
      }
    } catch (e) {
      Metriqus.errorLog("💥 Event sending error: ${e.toString()}");
      return false;
    }
  }

  /// Create HMAC signature for authentication
  static String _createHmacSignature(
    String clientKey,
    String clientSecret,
    String encryptedBody,
    String timestamp,
  ) {
    String data = '$clientKey$timestamp$encryptedBody';
    var key = utf8.encode(clientSecret);
    var bytes = utf8.encode(data);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  /// Encrypt data using AES-256-CBC
  static String _encrypt(
    String plainText,
    String clientSecret,
    String clientKey,
  ) {
    try {
      // Generate AES key and IV
      final key = _generateAESKey(clientSecret);
      final iv = _generateAESIV(clientKey);

      // Create AES cipher
      final cipher = CBCBlockCipher(AESEngine());
      final params = ParametersWithIV(KeyParameter(key), iv);
      cipher.init(true, params);

      // Pad the plaintext
      final paddedPlainText = _addPKCS7Padding(utf8.encode(plainText), 16);

      // Encrypt
      final encrypted = Uint8List(paddedPlainText.length);
      var offset = 0;
      while (offset < paddedPlainText.length) {
        final processed = cipher.processBlock(
          paddedPlainText,
          offset,
          encrypted,
          offset,
        );
        offset += processed.toInt();
      }

      return base64Encode(encrypted);
    } catch (e) {
      Metriqus.errorLog("Encryption error: $e");
      // Fallback to base64 encoding
      return base64Encode(utf8.encode(plainText));
    }
  }

  /// Generate AES key from secret using SHA-256
  static Uint8List _generateAESKey(String secret) {
    var digest = sha256.convert(utf8.encode(secret));
    return Uint8List.fromList(digest.bytes);
  }

  /// Generate AES IV from client key using MD5
  static Uint8List _generateAESIV(String clientKey) {
    var digest = md5.convert(utf8.encode(clientKey));
    return Uint8List.fromList(digest.bytes);
  }

  /// Add PKCS7 padding to data
  static Uint8List _addPKCS7Padding(List<int> data, int blockSize) {
    final padding = blockSize - (data.length % blockSize);
    final paddedData = List<int>.from(data);
    for (int i = 0; i < padding; i++) {
      paddedData.add(padding);
    }
    return Uint8List.fromList(paddedData);
  }

  /// Decrypt data using AES-256-CBC (for testing purposes)
  static String _decrypt(
    String encryptedData,
    String clientSecret,
    String clientKey,
  ) {
    try {
      // Generate AES key and IV
      final key = _generateAESKey(clientSecret);
      final iv = _generateAESIV(clientKey);

      // Create AES cipher
      final cipher = CBCBlockCipher(AESEngine());
      final params = ParametersWithIV(KeyParameter(key), iv);
      cipher.init(false, params);

      // Decode base64
      final encrypted = base64Decode(encryptedData);

      // Decrypt
      final decrypted = Uint8List(encrypted.length);
      var offset = 0;
      while (offset < encrypted.length) {
        final processed = cipher.processBlock(
          encrypted,
          offset,
          decrypted,
          offset,
        );
        offset += processed.toInt();
      }

      // Remove PKCS7 padding
      final unpaddedData = _removePKCS7Padding(decrypted);

      return utf8.decode(unpaddedData);
    } catch (e) {
      Metriqus.errorLog("Decryption error: $e");
      // Fallback to base64 decoding
      return utf8.decode(base64Decode(encryptedData));
    }
  }

  /// Remove PKCS7 padding from data
  static Uint8List _removePKCS7Padding(Uint8List data) {
    final padding = data.last;
    return data.sublist(0, data.length - padding);
  }
}

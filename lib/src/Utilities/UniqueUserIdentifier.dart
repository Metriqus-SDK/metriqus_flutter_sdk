import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../Storage/IStorage.dart';
import '../Metriqus.dart';

/// Unique user identifier generator and manager
class UniqueUserIdentifier {
  static const String _uniqueUserIdKey = "UniqueUserIdentifier";
  String? _id;

  /// Getter for the unique ID
  String? get id => _id;

  /// Constructor that creates or loads unique user ID
  UniqueUserIdentifier(IStorage storage, String adId, String deviceId) {
    // First try to read existing user ID directly
    String existingId = storage.loadData(_uniqueUserIdKey);

    if (existingId.isNotEmpty) {
      _id = existingId;
      Metriqus.verboseLog("👤 Existing user ID loaded: $_id");
    } else {
      // Generate new unique user ID using SHA256 hash
      String combined = "$adId:$deviceId";
      var bytes = utf8.encode(combined);
      var digest = sha256.convert(bytes);

      // Convert to uppercase hex string and take first 16 characters (like C# code)
      _id = digest.toString().toUpperCase().substring(0, 16);

      // Save to storage
      storage.saveData(_uniqueUserIdKey, _id!);
      Metriqus.infoLog("👤 New user ID created: $_id");
    }
  }

  /// Reset user ID (for testing or user logout)
  static Future<void> resetUserId(IStorage storage) async {
    try {
      if (storage.checkKeyExist(_uniqueUserIdKey)) {
        storage.deleteData(_uniqueUserIdKey);
        Metriqus.infoLog("👤 User ID reset");
      }
    } catch (e) {
      Metriqus.errorLog("❌ User ID reset error: $e");
    }
  }

  /// Check if user ID exists
  static bool hasUserId(IStorage storage) {
    try {
      return storage.checkKeyExist(_uniqueUserIdKey);
    } catch (e) {
      Metriqus.errorLog("❌ User ID check error: $e");
      return false;
    }
  }

  /// Validate user ID format (16 characters)
  static bool isValidUserId(String userId) {
    if (userId.isEmpty) return false;
    return userId.length == 16;
  }

  /// Extract timestamp from user ID
  static DateTime? getTimestampFromUserId(String userId) {
    try {
      if (!isValidUserId(userId)) return null;

      final parts = userId.split('_');
      if (parts.length >= 2) {
        final timestamp = int.parse(parts[1]);
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      Metriqus.errorLog("❌ User ID timestamp extraction error: $e");
    }
    return null;
  }
}

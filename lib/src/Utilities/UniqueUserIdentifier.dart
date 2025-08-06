import 'package:uuid/uuid.dart';
import '../Storage/IStorage.dart';
import '../Metriqus.dart';
import 'MetriqusUtils.dart';

/// Unique user identifier generator and manager
class UniqueUserIdentifier {
  static const String _uniqueUserIdKey = "UniqueUserIdentifier";
  String? _id;

  /// Getter for the unique ID
  String? get id => _id;

  /// Constructor that creates or loads unique user ID
  UniqueUserIdentifier(IStorage storage) {
    bool isUniqueUserIdentifierKeyExist =
        storage.checkKeyExist(_uniqueUserIdKey);

    if (isUniqueUserIdentifierKeyExist) {
      _id = storage.loadData(_uniqueUserIdKey);
      Metriqus.verboseLog("👤 Existing user ID loaded: $_id");
    } else {
      _id = const Uuid().v4();

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
        final timestampSeconds = int.parse(parts[1]);
        return MetriqusUtils.timestampSecondsToDateTime(timestampSeconds);
      }
    } catch (e) {
      Metriqus.errorLog("❌ User ID timestamp extraction error: $e");
    }
    return null;
  }
}

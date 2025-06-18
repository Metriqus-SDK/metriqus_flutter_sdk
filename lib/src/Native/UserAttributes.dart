import 'dart:convert';
import '../Storage/IStorage.dart';
import '../Metriqus.dart';

/// User attributes management class
class UserAttributes {
  static const String _userAttributesKey = "metriqus_user_attributes";

  final IStorage _storage;
  Map<String, dynamic> _attributes = {};

  UserAttributes(this._storage) {
    _loadAttributes();
  }

  /// Initialize user attributes asynchronously
  Future<void> initializeAsync() async {
    await _loadAttributesAsync();
  }

  /// Load attributes from storage asynchronously
  Future<void> _loadAttributesAsync() async {
    try {
      String attributesJson = await _storage.loadDataAsync(_userAttributesKey);
      if (attributesJson.isNotEmpty) {
        Map<String, dynamic> loadedAttributes = jsonDecode(attributesJson);
        _attributes = loadedAttributes;
        Metriqus.verboseLog(
            "👤 User attributes loaded async: ${_attributes.length} items");
      } else {
        _attributes = {};
        Metriqus.verboseLog("👤 New user attributes created async");
      }
    } catch (e) {
      Metriqus.errorLog("❌ User attributes async loading error: $e");
      _attributes = {};
    }
  }

  /// Set user attribute
  void setAttribute(String key, dynamic value) {
    try {
      _attributes[key] = value;
      _saveAttributes();
      Metriqus.verboseLog("👤 User attribute set: $key = $value");
    } catch (e) {
      Metriqus.errorLog("❌ User attribute setting error: $e");
    }
  }

  /// Get user attribute
  dynamic getAttribute(String key) {
    return _attributes[key];
  }

  /// Get all user attributes
  Map<String, dynamic> getAllAttributes() {
    return Map<String, dynamic>.from(_attributes);
  }

  /// Remove user attribute
  void removeAttribute(String key) {
    try {
      _attributes.remove(key);
      _saveAttributes();
      Metriqus.verboseLog("👤 User attribute removed: $key");
    } catch (e) {
      Metriqus.errorLog("❌ User attribute removal error: $e");
    }
  }

  /// Clear all user attributes
  void clearAllAttributes() {
    try {
      _attributes.clear();
      _saveAttributes();
      Metriqus.infoLog("👤 All user attributes cleared");
    } catch (e) {
      Metriqus.errorLog("❌ User attribute clearing error: $e");
    }
  }

  /// Check if attribute exists
  bool hasAttribute(String key) {
    return _attributes.containsKey(key);
  }

  /// Get attribute count
  int getAttributeCount() {
    return _attributes.length;
  }

  /// Load attributes from storage
  void _loadAttributes() {
    try {
      // Try to read data directly instead of checking key existence first
      String attributesJson = _storage.loadData(_userAttributesKey);
      if (attributesJson.isNotEmpty) {
        Map<String, dynamic> loadedAttributes = jsonDecode(attributesJson);
        _attributes = loadedAttributes;
        Metriqus.verboseLog(
            "👤 User attributes loaded: ${_attributes.length} items");
      } else {
        _attributes = {};
        Metriqus.verboseLog("👤 New user attributes created");
      }
    } catch (e) {
      Metriqus.errorLog("❌ User attributes loading error: $e");
      _attributes = {};
    }
  }

  /// Save attributes to storage
  void _saveAttributes() {
    try {
      String attributesJson = jsonEncode(_attributes);
      _storage.saveData(_userAttributesKey, attributesJson);
      // Also save async to ensure persistence
      _saveAttributesAsync();
    } catch (e) {
      Metriqus.errorLog("❌ User attributes saving error: $e");
    }
  }

  /// Save attributes to storage asynchronously
  Future<void> _saveAttributesAsync() async {
    try {
      String attributesJson = jsonEncode(_attributes);
      await _storage.saveDataAsync(_userAttributesKey, attributesJson);
    } catch (e) {
      Metriqus.errorLog("❌ User attributes async saving error: $e");
    }
  }

  /// Convert to JSON for event tracking
  Map<String, dynamic> toJson() {
    return getAllAttributes();
  }

  /// Create from JSON
  static UserAttributes fromJson(Map<String, dynamic> json, IStorage storage) {
    final userAttributes = UserAttributes(storage);
    userAttributes._attributes = Map<String, dynamic>.from(json);
    return userAttributes;
  }

  @override
  String toString() {
    return 'UserAttributes{count: ${_attributes.length}, attributes: $_attributes}';
  }
}

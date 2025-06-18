/// IStorage is an interface of Storage logic. It manages all saving and reading utilities.
/// Async and Sync options exist.
abstract class IStorage {
  // ASYNC FUNCTIONS
  /// Loads raw String data associated with the specified key asynchronously
  Future<String> loadDataAsync(String saveKey);

  /// Loads and parses a float value asynchronously from the stored data.
  Future<double> loadFloatDataAsync(String saveKey);

  /// Loads and parses a long value asynchronously from the stored data.
  Future<int> loadLongDataAsync(String saveKey);

  /// Loads and parses a double value asynchronously from the stored data.
  Future<double> loadDoubleDataAsync(String saveKey);

  /// Loads and parses an integer value asynchronously from the stored data.
  Future<int> loadIntDataAsync(String saveKey);

  /// Loads and parses a boolean value asynchronously from the stored data.
  Future<bool> loadBoolDataAsync(String saveKey);

  /// Saves data asynchronously using a specified key.
  Future<void> saveDataAsync(String saveKey, String saveData);

  // SYNC FUNCTIONS
  /// Loads raw String data associated with the specified key.
  String loadData(String saveKey);

  /// Loads and parses a float value from the stored data.
  double loadFloatData(String saveKey);

  /// Loads and parses a long value from the stored data.
  int loadLongData(String saveKey);

  /// Loads and parses a double value from the stored data.
  double loadDoubleData(String saveKey);

  /// Loads and parses an integer value from the stored data.
  int loadIntData(String saveKey);

  /// Loads and parses a boolean value from the stored data.
  bool loadBoolData(String saveKey);

  /// Saves data using a specified key.
  void saveData(String saveKey, String saveData);

  /// Deletes data associated with the specified key.
  void deleteData(String saveKey);

  /// Checks whether a given key exists in the stored data.
  bool checkKeyExist(String saveKey);

  /// Wait for cache initialization to complete (if supported by implementation)
  Future<void> waitForCacheInitialization();
}

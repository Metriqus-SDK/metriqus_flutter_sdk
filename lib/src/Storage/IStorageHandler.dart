/// Defines methods for storing, retrieving, and checking the existence of data in a storage system.
abstract class IStorageHandler {
  /// Saves data synchronously using a specified key.
  void saveFile(String saveKey, String saveData);

  /// Reads and retrieves stored data synchronously using a specified key.
  String readFile(String saveKey);

  /// Saves data asynchronously using a specified key.
  Future<void> saveFileAsync(String saveKey, String saveData);

  /// Reads and retrieves stored data asynchronously using a specified key.
  Future<String> readFileAsync(String saveKey);

  /// Deletes data using a specified key.
  void deleteFile(String saveKey);

  /// Checks whether a given key exists in the storage.
  bool checkKeyExist(String saveKey);
}

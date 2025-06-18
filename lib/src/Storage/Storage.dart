import 'IStorage.dart';
import 'IStorageHandler.dart';
import 'EncryptedStorageHandler.dart';

/// Storage is an instance of IStorage. Manages all storage related jobs.
/// You need to create an instance via a IStorageHandler to use.
class Storage implements IStorage {
  final IStorageHandler _handler;

  Storage(this._handler);

  // ASYNC FUNCTIONS
  @override
  Future<String> loadDataAsync(String saveKey) async {
    return await _handler.readFileAsync(saveKey);
  }

  @override
  Future<double> loadFloatDataAsync(String saveKey) async {
    String data = await loadDataAsync(saveKey);
    return double.tryParse(data) ?? 0.0;
  }

  @override
  Future<int> loadLongDataAsync(String saveKey) async {
    String data = await loadDataAsync(saveKey);
    return int.tryParse(data) ?? 0;
  }

  @override
  Future<double> loadDoubleDataAsync(String saveKey) async {
    String data = await loadDataAsync(saveKey);
    return double.tryParse(data) ?? 0.0;
  }

  @override
  Future<int> loadIntDataAsync(String saveKey) async {
    String data = await loadDataAsync(saveKey);
    return int.tryParse(data) ?? 0;
  }

  @override
  Future<bool> loadBoolDataAsync(String saveKey) async {
    String data = await loadDataAsync(saveKey);
    return data.toLowerCase() == 'true';
  }

  @override
  Future<void> saveDataAsync(String saveKey, String saveData) async {
    await _handler.saveFileAsync(saveKey, saveData);
  }

  // SYNC FUNCTIONS
  @override
  String loadData(String saveKey) {
    return _handler.readFile(saveKey);
  }

  @override
  double loadFloatData(String saveKey) {
    String data = loadData(saveKey);
    return double.tryParse(data) ?? 0.0;
  }

  @override
  int loadLongData(String saveKey) {
    String data = loadData(saveKey);
    return int.tryParse(data) ?? 0;
  }

  @override
  double loadDoubleData(String saveKey) {
    String data = loadData(saveKey);
    return double.tryParse(data) ?? 0.0;
  }

  @override
  int loadIntData(String saveKey) {
    String data = loadData(saveKey);
    return int.tryParse(data) ?? 0;
  }

  @override
  bool loadBoolData(String saveKey) {
    String data = loadData(saveKey);
    return data.toLowerCase() == 'true';
  }

  @override
  void saveData(String saveKey, String saveData) {
    _handler.saveFile(saveKey, saveData);
  }

  @override
  void deleteData(String saveKey) {
    _handler.deleteFile(saveKey);
  }

  @override
  bool checkKeyExist(String saveKey) {
    return _handler.checkKeyExist(saveKey);
  }

  /// Wait for cache initialization to complete (if handler supports it)
  @override
  Future<void> waitForCacheInitialization() async {
    if (_handler is EncryptedStorageHandler) {
      await (_handler as EncryptedStorageHandler).waitForCacheInitialization();
    }
  }
}

import 'package:data_repository/utils/extensions/index.dart';

import 'local_repository.dart';

/// An in-memory key/value [LocalRepository], useful for tests and for
/// callers that do not need cache to survive a restart.
class MapRepository implements LocalRepository {
  final Map<String, dynamic> cacheBox = {};
  final Map<String, int> cacheTimeBox = {};

  MapRepository() {
    init();
  }

  @override
  bool isInitialized = false;

  @override
  Future init() async {
    cacheBox.clear();
    cacheTimeBox.clear();
    isInitialized = true;
  }

  @override
  Future getData(String key) async => cacheBox.getKey(key);

  @override
  Future<dynamic> saveData(String key, String data) async =>
      cacheBox[key] = data;

  @override
  Future<bool> checkCache(String key) async {
    final time = cacheTimeBox.getKey<Object>(key)?.asInt;
    if (time == null) return false;
    return !time.isPast;
  }

  @override
  Future<int?> getTime(String key) async =>
      cacheTimeBox.getKey<Object>(key)?.asInt;

  @override
  void saveTime(String key, int duration) {
    if (key.isEmpty) return;
    cacheTimeBox[key] = duration;
  }

  @override
  void clearCache() {
    cacheBox.clear();
    cacheTimeBox.clear();
  }

  @override
  void removeData(String key) {
    cacheBox.remove(key);
    cacheTimeBox.remove(key);
  }
}

 

import 'package:data_repository/utils/extensions/index.dart';

import 'local_repository.dart';

// this is a local key value store
class MapRepository implements LocalRepository {
  late Map<String, dynamic> cacheBox = {};
  late Map<String, int> cacheTimeBox = {};
  MapRepository() {
    init();
  }

  @override
  Future init() async {
    cacheBox = {};
    cacheTimeBox = {};
    isInitialized = true;
  }

  @override
  Future getData(String key) async => cacheBox.getKey(key);

  @override
  Future<dynamic> saveData(String key, String data) async =>
      cacheBox.addAll({key: data});

  @override
  Future<bool> checkCache(String key) async {
    var time = cacheTimeBox.getKey<Object>(key)?.asInt;
    // print('cache: $key, $time');
    if (time == null) return false;
    return !time.isPast;
  }

  @override
  Future<int?> getTime(String key) async =>
      cacheTimeBox.getKey<Object>(key).asInt;

  @override
  void saveTime(String? key, int? duration) {
    if (key != null && key.isNotEmpty && duration != null && !duration.isNaN) {
      cacheTimeBox.addAll({key: duration});
    }
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

  @override
  late bool isInitialized;
}

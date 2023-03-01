import 'package:data_repository/data_repository.dart';
import 'package:hive/hive.dart';

class HiveRepository implements LocalRepository {
  late LazyBox cacheBox;
  late LazyBox cacheTimeBox;
  HiveRepository() {
    init();
  }

  @override
  Future init() async {
    cacheBox = await Hive.openLazyBox('cache-box');
    cacheTimeBox = await Hive.openLazyBox('cache-time-box');
    isInitialized = true;
  }

  @override
  Future getData(String key) async {
    if (!isInitialized) await init();

    return cacheBox.get(key);
  }

  @override
  Future<dynamic> saveData(String key, String data) async {
    if (!isInitialized) await init();
    cacheBox.put(key, data);
  }

  @override
  Future<bool> checkCache(String key) async {
    if (!isInitialized) await init();
    var time = await cacheTimeBox.get(key);
    print(
        'cache: $key, $time, ${await cacheTimeBox.get(key)} ${DateTime.fromMillisecondsSinceEpoch(time ?? 001)}');
    if (time == null) return false;
    // return
    try {
      return !(time as int).isPast;
    } catch (e) {
      return false;
    }
  }

  @override
  void saveTime(String? key, int? duration) async {
    if (!isInitialized) await init();
    // duration = duration?.secondsToMilliseconds;
    if (key != null && key.isNotEmpty && duration != null && !duration.isNaN) {
      cacheTimeBox.put(key, duration);
    }
  }

  @override
  void clearCache() async {
    if (!isInitialized) await init();
    cacheBox.clear();
    cacheTimeBox.clear();
  }

  @override
  Future<int?> getTime(String key) async {
    if (!isInitialized) await init();
    return cacheTimeBox.get(key).asInt;
  }

  @override
  void removeData(String key) async {
    if (!isInitialized) await init();
    cacheBox.delete(key);
    cacheTimeBox.delete(key);
  }

  @override
  bool isInitialized = false;
}

/// Interface for Local Repository
abstract class LocalRepository {
  /// initialize instance of database
  Future init();

  bool isInitialized = false;

  /// get stored data from local database.
  ///
  /// checks if the data was cached and returns the cached data if its not expired, otherwise it returns null
  ///
  /// [key] - the key used to store the data
  Future<dynamic> getData(String key);

  /// get stored data from local database
  /// [key] - the key used to store the data
  /// [data] - string version of the data to be stored
  Future<dynamic> saveData(String key, String data);

  /// save expiry time in milliseconds for this data
  /// [key] - the key used to store the data
  /// [duration] - duration of cache in seconds
  void saveTime(String key, int duration);
  Future<int?> getTime(String key);

  /// clear all content from cache
  void clearCache();

  /// remove a cached content from cache
  /// [key] - the key used to store the data
  void removeData(String key);

  /// check time storage if cached data exists and is valid
  /// [key] - the key used to store the data
  /// [data] - string version of the data to be stored
  Future<bool> checkCache(String key);
}

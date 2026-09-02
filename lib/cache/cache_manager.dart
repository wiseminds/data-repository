import 'dart:io';

import 'package:data_repository/utils/api_config.dart';
import 'package:path_provider/path_provider.dart';

/// Cache manager class that handles all the cache operations
class CacheManager {
  /// returns data stored in the cache for the given key
  Future<String?> getCachedData(String path) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${path.split('/').last}.json');
      if (!await file.exists()) return null;
      ApiConfig().log('cache hit for $path');
      return await file.readAsString();
    } catch (e) {
      ApiConfig().log('cache read failed for $path: $e');
      return null;
    }
  }

  /// stores data in the cache for the given key
  Future<bool> saveToCache(String path, String data) async {
    try {
      final tempDir = await getTemporaryDirectory();
      await File(
        '${tempDir.path}/${path.split('/').last}.json',
      ).writeAsString(data);
      return true;
    } catch (e) {
      ApiConfig().log('cache write failed for $path: $e');
      return false;
    }
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Cache manager class that handles all the cache operations
class CacheManager {
  /// returns data stored in the cache for the given key
  Future<dynamic> getCachedData(String path) async {
    Directory tempDir = await getTemporaryDirectory();
    try {
      // if(path.startsWith('/')) path = path.replaceFirst('/', '');
      path = path.split('/').last;
      if (kDebugMode) print('get cache.....$path.');
      bool isFound = await File('${tempDir.path}/$path.json').exists();
      if (kDebugMode) print('check temp finished $isFound');
      if (isFound) {
        String s = await File('${tempDir.path}/$path.json').readAsString();
        if (kDebugMode) print('cache.....$path.');
        return s;
      }
    } catch (e) {
      return null;
    }
  }

  /// stores data in the cache for the given key
  Future<bool> savToCache(String path, String data) async {
    Directory tempDir = await getTemporaryDirectory();
    try {
      path = path.split('/').last;
      if (kDebugMode) print('save to cache.....$path. $data');

      await File('${tempDir.path}/$path.json').writeAsString(data);
      return true;
    } catch (e) {
      if (kDebugMode) print(e);
      return false;
    }
  }
}

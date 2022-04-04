import 'package:data_repository/local/local_repository.dart';
import 'package:data_repository/remote/provider/api_response.dart';
import 'package:flutter/foundation.dart';

import 'cache_description.dart';

mixin CacheMixin {
  /// validate data to be saved to cache is not an empty list
  ResultType? validateData<ResultType, Item>(
      ApiResponse<ResultType, Item> response) {
    dynamic data = response.body;
    if (ResultType is Iterable<Item>) {
      if ((data as Iterable).isEmpty) return null;
    }
    return data;
  }

  Future<bool> shouldUseCache(
      LocalRepository repository, CacheDescription? cache) async {
    if (kDebugMode) print('cache $cache ${cache?.key} ${cache?.lifeSpan}');
    if (cache == null || cache.key.isEmpty) return false;
    if (cache.invalidateCache) return false;
    if (cache.overrideTime) return true;
    return await repository.checkCache(cache.key);
  }
}

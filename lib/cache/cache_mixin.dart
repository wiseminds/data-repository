import 'package:data_repository/local/local_repository.dart';
import 'package:data_repository/remote/index.dart';
import 'package:data_repository/utils/api_config.dart';

import 'cache_description.dart';

mixin CacheMixin {
  /// Returns the body to cache, or null when it should not be cached.
  ///
  /// Guards against storing an empty collection, which would otherwise be
  /// served back as a valid (but useless) cache hit.
  ResultType? validateData<ResultType, Item>(
    ApiResponse<ResultType, Item> response,
  ) {
    final data = response.body;
    // Checked on the value: `ResultType is Iterable<Item>` compares a type
    // argument against a type and is always false, so it never guarded
    // anything.
    if (data is Iterable && data.isEmpty) return null;
    return data;
  }

  Future<bool> shouldUseCache(
    LocalRepository repository,
    CacheDescription? cache,
  ) async {
    if (cache == null || cache.key.isEmpty) return false;
    ApiConfig().log('cache ${cache.key} lifeSpan=${cache.lifeSpan}');
    if (cache.invalidateCache) return false;
    if (cache.overrideTime) return true;
    return await repository.checkCache(cache.key);
  }
}

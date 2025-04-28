import 'package:data_repository/data_repository.dart';

import 'test_api.dart';

class TestRepository extends DataRepository {
  TestRepository(
      LocalRepository localRepository, RemoteRepository remoteRepository)
      : super(localRepository, remoteRepository);

  final _api = TestApi();

  Future<ApiResponse<Map<String, dynamic>, Map<String, dynamic>>> triggerError(String? errorType) async {
    return await handleRequest(_api.triggerError(errorType));
  }

  Future<ApiResponse<Map<String, dynamic>, Map<String, dynamic>>> testCache(
    String cacheKey,
    int cacheExpirationInMilliSeconds, {
    bool ignoreSave = false,
    bool invalidateCache = false,
    bool overrideTime = false,
  }) async {
    return await handleRequest(_api.testCache(),
        cache: CacheDescription(cacheKey,
            lifeSpan: cacheExpirationInMilliSeconds,
            ignoreSave: ignoreSave,
            invalidateCache: invalidateCache,
            overrideTime: overrideTime));
  }
}

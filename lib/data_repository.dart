import 'dart:async';

import 'package:data_repository/remote/api_request.dart';
import 'package:data_repository/remote/api_response.dart';

import 'cache/cache_description.dart';
import 'cache/cache_mixin.dart';
import 'local/local_repository.dart';
import 'remote/remote_repository.dart';
import 'remote/request_options.dart';
import 'utils/api_config.dart';
import 'utils/exception_formatter.dart';
import 'utils/json_utils.dart';

export 'cache/index.dart';
export 'local/index.dart';
export 'models/index.dart';
export 'utils/index.dart';
export 'remote/index.dart';

typedef NetworkCall<T> = Future<T> Function();

/// Data repository class that handles all the network calls an local data access
abstract class DataRepository with ExceptionFormatter, CacheMixin {
  final LocalRepository localRepository;
  final RemoteRepository remoteRepository;
  final String? defaultErrorMessage;

  DataRepository(
    this.localRepository,
    this.remoteRepository, [
    this.defaultErrorMessage,
  ]) {
    ApiConfig().defaultErrorMessage =
        defaultErrorMessage ?? ApiConfig().defaultErrorMessage;
  }

  /// manages fetching data, decides where to fetch data from
  ///
  /// [timeout] (seconds) overrides the request's own [ApiRequest.timeout].
  Future<ApiResponse<ResultType, Item>> handleRequest<ResultType, Item>(
    ApiRequest<ResultType, Item> request, {
    CacheDescription? cache,
    int? timeout,
    bool retryWithCache = false,
    RequestOptions options = const RequestOptions(),
  }) async {
    final useCache = await shouldUseCache(localRepository, cache);

    /// fetches data from cache if a valid cached data exists
    if (useCache) {
      final cached = await _readFromCache<ResultType, Item>(request, cache!);
      if (cached != null) return cached;
    }

    /// else fetches data from the remote source
    var response = await remoteRepository.handleRequest<ResultType, Item>(
      request,
      timeout: timeout,
      options: options,
    );

    if (!response.isSuccessful) {
      response = remoteRepository.handleError(response);
      if (retryWithCache && cache != null && !response.isCancelled) {
        return handleRequest(
          request,
          cache: cache.copyWith(overrideTime: true),
          options: options,
        );
      }
    }

    await _writeToCache<ResultType, Item>(response, cache);
    return response;
  }

  /// Returns a resolved response built from cached data, or null when there is
  /// no usable cache entry.
  Future<ApiResponse<ResultType, Item>?> _readFromCache<ResultType, Item>(
    ApiRequest<ResultType, Item> request,
    CacheDescription cache,
  ) async {
    try {
      // Runs the onRequest interceptors so request-scoped interceptor state
      // (timers, counters) stays consistent on the cache path too.
      request = await request.build;

      final data = await localRepository.getData(cache.key);
      if (data == null) return null;

      final decoded = JsonUtils.decode(data.toString());
      final response = await ApiResponse<ResultType, Item>(
        // ignore: deprecated_member_use_from_same_package
        request: request.copyWith(dataKey: '', nestedKey: ''),
        bodyString: decoded,
        headers: const {},
        statusCode: ApiResponse.cacheHit,
      ).resolve;

      if (response.body == null) return null;
      if (decoded is List && decoded.isEmpty) return null;
      ApiConfig().log('served ${cache.key} from cache');
      return response;
    } catch (e, trace) {
      ApiConfig().log('cache read failed for ${cache.key}: $e\n$trace');
      return null;
    }
  }

  Future<void> _writeToCache<ResultType, Item>(
    ApiResponse<ResultType, Item> response,
    CacheDescription? cache,
  ) async {
    if (cache == null || cache.ignoreSave || cache.key.isEmpty) return;
    if (response.body == null || response.isCancelled) return;

    final data = validateData<ResultType, Item>(response);
    if (data == null) return;

    try {
      final json = JsonUtils.convertToJson(data);
      await localRepository.saveData(cache.key, json);
      localRepository.saveTime(
        cache.key,
        DateTime.now()
            .add(Duration(milliseconds: cache.lifeSpan))
            .millisecondsSinceEpoch,
      );
    } on JsonSerializationException catch (e) {
      // Do not persist a placeholder the next read would have to discard.
      ApiConfig().log('not caching ${cache.key}: $e');
    }
  }
}

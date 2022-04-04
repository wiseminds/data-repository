import 'dart:async';

import 'package:flutter/foundation.dart';

import 'cache/cache_description.dart';
import 'cache/cache_mixin.dart';
import 'local/local_repository.dart';
import 'remote/provider/api_request.dart';
import 'remote/provider/api_response.dart';
import 'remote/remote_repository.dart';
import 'utils/api_config.dart';
import 'utils/exception_formater.dart';
import 'utils/json_utlis.dart';

typedef NetworkCall<T> = Future<T> Function();

/// Data repository class that handles all the network calls an local data access
abstract class DataRepository with ExceptionFormater, CacheMixin {
  final LocalRepository localRepository;
  final RemoteRepository remoteRepository;
  final String? defaultErrorMessage;

  DataRepository(this.localRepository, this.remoteRepository,
      [this.defaultErrorMessage]) {
    ApiConfig().defaultErrorMessage =
        defaultErrorMessage ?? ApiConfig().defaultErrorMessage;
  }

  /// manages fetching data, decides where to fetch data from
  Future<ApiResponse<ResultType, Item>> handleRequest<ResultType, Item>(
      NetworkCall<ApiResponse<ResultType, Item>> networkCall,
      {CacheDescription? cache,
      int timeout = 50,
      bool retryWithCache = false,
      bool retry = false}) async {
    bool _useCache = await shouldUseCache(localRepository, cache);

    /// fetches data from cache if a valid cached data exists
    if (_useCache) {
      if (kDebugMode) print('fetching data from cache');
      var data = await localRepository.getData(cache!.key);
      // data = JsonInterceptor.convertFromJson<ResultType, Item>(data);
      // print('${data != null && data is ResultType}');
      // if (kDebugMode) print('fetching data from cache $data');
      if (data != null && data is ResultType) {
        return ApiResponse<ResultType, Item>(
            request: ApiRequest.dummy(),
            bodyString: data.toString(),
            // body: data,
            headers: {},
            statusCode: 210).resolve;
      }
    }

    /// else fetches data from the remote source
    ApiResponse<ResultType, Item> response = await remoteRepository
        .handleRequest<ResultType, Item>(networkCall, timeout: timeout);

    // print('headers: ${response.request.headers}');

    if (!response.isSuccessful) {
      response = remoteRepository.handleError(response);
      if (retryWithCache && cache != null) {
        return handleRequest(networkCall,
            cache: cache.copyWith(overrideTime: true));
      }
    }

    if (kDebugMode) print(response.error);
    if (kDebugMode) print(' finished request');

    if (cache != null &&
        !cache.ignoreSave &&
        cache.key.isNotEmpty &&
        response.body != null) {
      var data = validateData<ResultType, Item>(response);
      if (data != null) {
        String json = Jsonutils.convertToJson(data);
        localRepository.saveData(cache.key, json);
        localRepository.saveTime(
            cache.key,
            DateTime.now()
                .add(Duration(milliseconds: cache.lifeSpan))
                .millisecondsSinceEpoch);
      }
    }
    return response;
  }
}

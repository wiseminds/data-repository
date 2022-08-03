import 'dart:async';

import 'package:data_repository/remote/api_request.dart';
import 'package:data_repository/remote/api_response.dart';
import 'package:flutter/foundation.dart';

import 'cache/cache_description.dart';
import 'cache/cache_mixin.dart';
import 'local/local_repository.dart';
import 'remote/remote_repository.dart';
import 'utils/api_config.dart';
import 'utils/exception_formater.dart';
import 'utils/json_utils.dart';

export 'cache/index.dart';
export 'local/index.dart';
export 'models/index.dart';
export 'utils/index.dart';
export 'remote/index.dart';

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
      // NetworkCall<ApiResponse<ResultType, Item>> networkCall,
      ApiRequest<ResultType, Item> request,
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
      if (kDebugMode) print('fetching data from cache $data');
      var d = Jsonutils.decode(data);
      var res = ApiResponse<ResultType, Item>(
              request: request.copyWith(dataKey: '', nestedKey: ''),
              bodyString: d,
              // body: data,
              headers: {},
              statusCode: 210)
          .resolve;
      if (res.body != null && (d is! List || (d).isNotEmpty)) return res;
    }

    /// else fetches data from the remote source
    ApiResponse<ResultType, Item> response = await remoteRepository
        .handleRequest<ResultType, Item>(request, timeout: timeout);

    // print('headers: ${response.request.headers}');

    if (!response.isSuccessful) {
      response = remoteRepository.handleError(response);
      if (retryWithCache && cache != null) {
        return handleRequest(request,
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

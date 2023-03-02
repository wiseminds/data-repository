import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data_repository.dart';
// import 'api_request.dart';
// import 'api_response.dart';

///  for Remote Repository
class RemoteRepository with ExceptionFormater {
  final String? defaultErrorMessage;
  final ApiProvider provider;

  RemoteRepository(this.provider, [this.defaultErrorMessage]);

  /// makes a network request
  Future<ApiResponse<ResultType, Item>> handleRequest<ResultType, Item>(
      ApiRequest<ResultType, Item> request,
      {int timeout = 50,
      bool retry = false}) async {
    ApiResponse<ResultType, Item> response;
    try {
      response = await provider
          .send<ResultType, Item>(request)
          .timeout(Duration(seconds: timeout), onTimeout: () {
        throw (TimeoutException('Connection timed out'));
      });
    } catch (e) {
      if (kDebugMode) print(' error in request ');
      if (kDebugMode) print(e.toString());
      response = ApiResponse<ResultType, Item>(
          bodyString: null,
          request: request,
          error: (e is ApiError)
              ? e
              : formatErrorMessage(e, defaultErrorMessage ?? ''),
          headers: {},
          statusCode: 200);
    }
    return response;
  }

  ApiResponse<ResultType, Item> handleError<ResultType, Item>(
      ApiResponse<ResultType, Item> response) {
    ApiError? error;
    if (response.error is ApiError) {
      error = (response.error as ApiError);
    } else {
      error = formatErrorMessage(response.error, defaultErrorMessage ?? '');
    }

    error = error; // ??
    // ApiError((b) => b
    //   ..statusCode = response.statusCode ?? 400
    //   ..message = Strings.DEFAULT_ERROR_MESSAGE);
    if ((response.statusCode) > 490) {
      error = ApiError(defaultErrorMessage ?? '', response.statusCode);

      // error.statusCode = response.statusCode ?? 400;
    }
    return response.copyWith(error: error);
  }
}

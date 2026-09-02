import 'dart:async';

import '../data_repository.dart';

///  for Remote Repository
class RemoteRepository with ExceptionFormatter {
  final String? defaultErrorMessage;
  final ApiProvider provider;

  RemoteRepository(this.provider, [this.defaultErrorMessage]);

  /// makes a network request
  ///
  /// [timeout] overrides the request's own [ApiRequest.timeout] when supplied.
  Future<ApiResponse<ResultType, Item>> handleRequest<ResultType, Item>(
    ApiRequest<ResultType, Item> request, {
    int? timeout,
  }) async {
    final seconds = timeout ?? request.timeout;
    try {
      return await provider
          .send<ResultType, Item>(request)
          .timeout(
            Duration(seconds: seconds),
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    } catch (e, stackTrace) {
      ApiConfig().log(
        '${request.method} ${request.path} failed: $e\n$stackTrace',
      );

      final error = formatErrorMessage(e, defaultErrorMessage ?? '');

      return ApiResponse<ResultType, Item>(
        request: request,
        error: error,
        // Retain the throwable itself so a caller can recover a custom
        // exception type that formatErrorMessage would otherwise flatten.
        cause: e,
        stackTrace: stackTrace,
        headers: const {},
        // A status the caller supplied on the thrown error wins over the
        // generic transport-failure marker, so `throw ApiError('...', 401)`
        // from an interceptor still arrives as a 401.
        statusCode: error.hasHttpStatusCode
            ? error.code
            : ApiResponse.transportFailure,
        // Resolve so onError interceptors still run on the failure path.
      ).resolve;
    }
  }

  ApiResponse<ResultType, Item> handleError<ResultType, Item>(
    ApiResponse<ResultType, Item> response,
  ) {
    var error = response.error is ApiError
        ? response.error as ApiError
        : formatErrorMessage(response.error, defaultErrorMessage ?? '');

    /// When the caller has opted out of surfacing server-side failures, replace
    /// the upstream error with the generic message.
    if (response.statusCode > 490 &&
        response.request.override500Error == false) {
      error = ApiError(
        defaultErrorMessage ?? ApiConfig().defaultErrorMessage,
        response.statusCode,
      );
    }

    return response.copyWith(error: error);
  }
}

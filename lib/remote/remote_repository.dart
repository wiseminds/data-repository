import 'dart:async';

import '../data_repository.dart';

///  for Remote Repository
///
/// Owns everything between a described request and a resolved response:
/// retries, de-duplication, cancellation and error normalisation. The
/// transport itself is injected as an [ApiProvider], so this class works
/// unchanged over http, a mock, or any other implementation.
class RemoteRepository with ExceptionFormatter {
  final String? defaultErrorMessage;
  final ApiProvider provider;

  /// Applied when a call supplies no [RequestOptions.retry] and the request
  /// carries no [ApiRequest.retryPolicy] of its own.
  final RetryPolicy defaultRetryPolicy;

  /// Whether identical in-flight requests share one network call.
  final bool deduplicate;

  final Map<String, Future<ApiResponse>> _inFlight = {};

  RemoteRepository(
    this.provider, [
    this.defaultErrorMessage,
    this.defaultRetryPolicy = RetryPolicy.none,
    this.deduplicate = true,
  ]);

  /// makes a network request
  Future<ApiResponse<ResultType, Item>> handleRequest<ResultType, Item>(
    ApiRequest<ResultType, Item> request, {
    int? timeout,
    RequestOptions options = const RequestOptions(),
  }) {
    if (timeout != null) {
      options = RequestOptions(
        cancelToken: options.cancelToken,
        retry: options.retry,
        onSendProgress: options.onSendProgress,
        onReceiveProgress: options.onReceiveProgress,
        timeout: timeout,
        skipDeduplication: options.skipDeduplication,
      );
    }

    // De-duplication is only safe for calls with no per-caller streaming or
    // cancellation, and only for methods that are safe to share.
    final key = _deduplicationKey<ResultType, Item>(request, options);
    if (key == null) return _attempt<ResultType, Item>(request, options);

    final existing = _inFlight[key];
    if (existing != null) {
      ApiConfig().log('joining in-flight request $key');
      return existing.then((r) => r as ApiResponse<ResultType, Item>);
    }

    final future = _attempt<ResultType, Item>(request, options);
    _inFlight[key] = future;
    return future.whenComplete(() => _inFlight.remove(key));
  }

  String? _deduplicationKey<ResultType, Item>(
    ApiRequest<ResultType, Item> request,
    RequestOptions options,
  ) {
    if (!deduplicate || options.skipDeduplication) return null;
    if (!options.isPlain) return null;
    if (request.method != ApiMethods.get && request.method != ApiMethods.head) {
      return null;
    }
    // The type arguments are part of the key: two call sites may request the
    // same URL as different models, and they must not share a decoded body.
    return '${request.method} ${request.uri} $ResultType/$Item';
  }

  /// Runs the request, re-attempting it while the retry policy says to.
  Future<ApiResponse<ResultType, Item>> _attempt<ResultType, Item>(
    ApiRequest<ResultType, Item> request,
    RequestOptions options,
  ) async {
    final policy = options.retry ?? request.retryPolicy ?? defaultRetryPolicy;

    var attempt = 1;
    while (true) {
      final response = await _sendOnce<ResultType, Item>(request, options);

      final canRetry =
          attempt < policy.maxAttempts &&
          !response.isSuccessful &&
          !response.isCancelled &&
          policy.retryIf(response, attempt);
      if (!canRetry) return response;

      final delay = policy.delayFor(attempt);
      ApiConfig().log(
        'retrying ${request.method} ${request.path} in ${delay.inMilliseconds}ms '
        '(attempt ${attempt + 1}/${policy.maxAttempts}, was ${response.statusCode})',
      );

      await Future.delayed(delay);
      if (options.cancelToken?.isCancelled ?? false) {
        return _cancelledResponse<ResultType, Item>(
          request,
          options.cancelToken!.cause!,
        );
      }
      attempt++;
      // The request is rebuilt by the provider on every attempt, so an
      // interceptor that refreshed a token in onError is picked up here.
    }
  }

  Future<ApiResponse<ResultType, Item>> _sendOnce<ResultType, Item>(
    ApiRequest<ResultType, Item> request,
    RequestOptions options,
  ) async {
    try {
      return await provider.send<ResultType, Item>(request, options);
    } on RequestCancelledException catch (e) {
      ApiConfig().log('${request.method} ${request.path} cancelled: $e');
      return _cancelledResponse<ResultType, Item>(request, e);
    } catch (e, stackTrace) {
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

  Future<ApiResponse<ResultType, Item>> _cancelledResponse<ResultType, Item>(
    ApiRequest<ResultType, Item> request,
    RequestCancelledException cause,
  ) => ApiResponse<ResultType, Item>(
    request: request,
    error: ApiError(
      cause.reason ?? 'Request cancelled',
      ApiConfig.cancelledCode,
    ),
    cause: cause,
    headers: const {},
    statusCode: ApiResponse.cancelled,
  ).resolve;

  ApiResponse<ResultType, Item> handleError<ResultType, Item>(
    ApiResponse<ResultType, Item> response,
  ) {
    var error = response.error is ApiError
        ? response.error as ApiError
        : formatErrorMessage(response.error, defaultErrorMessage ?? '');

    /// When the caller has opted out of surfacing server-side failures,
    /// replace the upstream error with the generic message.
    if (response.statusCode > 490 &&
        response.request.override500Error == false) {
      error = ApiError(
        defaultErrorMessage ?? ApiConfig().defaultErrorMessage,
        response.statusCode,
      );
    }

    return response.copyWith(error: error);
  }

  /// Releases the transport.
  void close() => provider.close();
}

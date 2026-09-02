import 'package:data_repository/models/api_error.dart';
import 'package:data_repository/models/pagination.dart';
import 'package:data_repository/utils/api_config.dart';

import 'api_request.dart';

/// Sentinel distinguishing "argument omitted" from "argument explicitly null"
/// in [ApiResponse.copyWith]. Without it, `copyWith(body: null)` silently
/// preserves the previous body.
const Object _unset = Object();

class ApiResponse<BodyType, InnerType> {
  /// Status code used when a response is served from the local cache.
  static const int cacheHit = 210;

  /// Status code used when the request never produced an HTTP response at all
  /// (transport failure, or an interceptor threw during `onRequest`).
  static const int transportFailure = 0;

  /// Status code used when the call was cancelled via its [CancellationToken].
  static const int cancelled = -1;

  /// True when this response is the result of a cancellation rather than a
  /// failure worth reporting to the user.
  bool get isCancelled => statusCode == ApiResponse.cancelled;

  final int statusCode;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? extra;
  final dynamic bodyString;
  final BodyType? body;
  final Pagination? pagination;
  final ApiRequest<BodyType, InnerType> request;

  /// Body of response if [isSuccessful] is false
  final Object? error;

  /// The original throwable behind [error], when this response was produced by
  /// an exception rather than an HTTP status.
  ///
  /// Lets callers recover a custom exception type that would otherwise be
  /// flattened into a generic [ApiError]:
  /// `if (response.cause is SessionExpiredException) ...`
  final Object? cause;

  /// Stack trace captured where [cause] was thrown, when available.
  final StackTrace? stackTrace;

  /// true if the status code is >= 200 && < 300 and nothing set an [error].
  ///
  /// The [error] clause matters when an interceptor throws while resolving an
  /// otherwise-2xx response: the body was never produced, so reporting success
  /// would hand the caller a null body.
  bool get isSuccessful =>
      statusCode >= 200 && statusCode < 300 && error == null;

  ApiResponse({
    this.bodyString,
    this.pagination,
    this.statusCode = 500,
    this.headers,
    this.body,
    this.error,
    this.extra,
    this.cause,
    this.stackTrace,
    required this.request,
  });

  ApiResponse<BodyType, InnerType> copyWith({
    int? statusCode,
    Object? error = _unset,
    Map<String, dynamic>? headers,
    dynamic bodyString = _unset,
    Object? body = _unset,
    Object? pagination = _unset,
    Map<String, dynamic>? extra,
    Object? cause = _unset,
    StackTrace? stackTrace,
    ApiRequest<BodyType, InnerType>? request,
  }) => ApiResponse<BodyType, InnerType>(
    bodyString: identical(bodyString, _unset) ? this.bodyString : bodyString,
    statusCode: statusCode ?? this.statusCode,
    pagination: identical(pagination, _unset)
        ? this.pagination
        : pagination as Pagination?,
    headers: headers ?? this.headers,
    body: identical(body, _unset) ? this.body : body as BodyType?,
    error: identical(error, _unset) ? this.error : error,
    extra: extra ?? this.extra,
    cause: identical(cause, _unset) ? this.cause : cause,
    stackTrace: stackTrace ?? this.stackTrace,
    request: request ?? this.request,
  );

  @override
  String toString() =>
      '''
  body: $body,
  bodyString: $bodyString,
  headers: $headers,
  statusCode: $statusCode,
  error: $error,
  extra: $extra
  ''';

  /// Runs the request's interceptors over this response.
  ///
  /// An interceptor that throws no longer disappears: the chain stops, the
  /// failure is logged, and the returned response carries the exception on
  /// [error]/[cause] so callers can see that resolution was incomplete.
  Future<ApiResponse<BodyType, InnerType>> get resolve async {
    var response = this;
    for (final interceptor in request.interceptors) {
      try {
        response = await (isSuccessful
            ? interceptor.onResponse(response)
            : interceptor.onError(response));
      } catch (e, trace) {
        ApiConfig().log(
          'interceptor ${interceptor.runtimeType} threw while resolving '
          '${request.method} ${request.path}: $e\n$trace',
        );
        return response.copyWith(
          error:
              response.error ??
              ApiError('$e', ApiConfig.interceptorFailureCode),
          cause: e,
          stackTrace: trace,
        );
      }
    }
    return response;
  }
}

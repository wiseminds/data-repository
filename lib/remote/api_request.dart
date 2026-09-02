import 'package:data_repository/remote/interceptors/api_interceptor.dart';
import 'package:flutter/foundation.dart';

import 'api_methods.dart';
import 'retry_policy.dart';

/// Sentinel distinguishing "argument omitted" from "argument explicitly null".
const Object _unset = Object();

class ApiRequest<ResponseType, InnerType> {
  /// an ID used to track individual requests
  final String requestId;
  final String? method, nestedKey;
  final String path;
  final int timeout;
  final String dataKey;
  final String baseUrl;
  final bool hasPagination;
  final bool? override500Error;
  final Map<String, dynamic>? body;
  final Map<String, String> headers;
  final Map<String, dynamic> query;
  final List<ApiInterceptor> interceptors;
  final RetryPolicy? retryPolicy;
  final ErrorDescription? error;
  final bool isMultipart;

  ApiRequest({
    String? requestId,
    this.hasPagination = false,
    this.isMultipart = false,
    this.retryPolicy,
    this.override500Error = true,
    this.headers = const {},
    this.query = const {},
    this.error,
    this.nestedKey,
    this.method = ApiMethods.get,
    this.dataKey = '',
    this.interceptors = const [],
    this.path = '',
    required this.baseUrl,
    this.timeout = 50,
    this.body,
  }) : requestId = requestId ?? UniqueKey().toString();

  factory ApiRequest.dummy() => ApiRequest<ResponseType, InnerType>(
    hasPagination: false,
    headers: {},
    query: {},
    method: ApiMethods.get,
    dataKey: '',
    isMultipart: false,
    path: '',
    baseUrl: '',
  );

  /// Note: [interceptors] are *appended* to the existing chain rather than
  /// replacing it, so an interceptor can add another without discarding the
  /// ones already configured on the request.
  ApiRequest<ResponseType, InnerType> copyWith({
    String? method,
    String? path,
    String? dataKey,
    String? baseUrl,
    bool? hasPagination,
    RetryPolicy? retryPolicy,
    int? timeout,
    bool? override500Error,
    bool? isMultipart,
    Object? body = _unset,
    Map<String, String>? headers,
    List<ApiInterceptor>? interceptors,
    Object? error = _unset,
    Object? nestedKey = _unset,
    Map<String, dynamic>? query,
  }) => ApiRequest<ResponseType, InnerType>(
    requestId: requestId,
    hasPagination: hasPagination ?? this.hasPagination,
    headers: headers ?? this.headers,
    query: query ?? this.query,
    method: method ?? this.method,
    dataKey: dataKey ?? this.dataKey,
    nestedKey: identical(nestedKey, _unset)
        ? this.nestedKey
        : nestedKey as String?,
    isMultipart: isMultipart ?? this.isMultipart,
    path: path ?? this.path,
    retryPolicy: retryPolicy ?? this.retryPolicy,
    error: identical(error, _unset) ? this.error : error as ErrorDescription?,
    timeout: timeout ?? this.timeout,
    override500Error: override500Error ?? this.override500Error,
    baseUrl: baseUrl ?? this.baseUrl,
    interceptors: [...?interceptors, ...this.interceptors],
    body: identical(body, _unset) ? this.body : body as Map<String, dynamic>?,
  );

  /// Runs the `onRequest` interceptors and returns the resulting request.
  ///
  /// Awaits each hook, so an interceptor may refresh a token or read from
  /// storage before the request goes out.
  ///
  /// Interceptor exceptions are intentionally not caught here — callers run
  /// this inside their own error handling so a throwing interceptor is
  /// reported rather than silently skipped.
  Future<ApiRequest<ResponseType, InnerType>> get build async {
    var request = this;
    for (final interceptor in interceptors) {
      request = await interceptor.onRequest(request);
    }
    return request;
  }

  Uri get uri {
    final parsed = Uri.parse('$baseUrl/$path').normalizePath();

    /// The explicit [query] is applied last so it wins over any parameters
    /// already embedded in [path].
    final merged = <String, String>{
      ...parsed.queryParameters,
      ...query.map((key, value) => MapEntry(key, '$value')),
    };

    return parsed.replace(
      pathSegments: parsed.pathSegments
          .where((element) => element.isNotEmpty)
          .toList(),
      // Passing an empty map would append a bare '?' to every URL that has no
      // query parameters; null leaves the (empty) query untouched.
      queryParameters: merged.isEmpty ? null : merged,
    );
  }
}

class ErrorDescription {
  final String key;

  ErrorDescription({this.key = 'error'});
}

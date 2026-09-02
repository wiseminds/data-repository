import 'dart:async';

import 'package:data_repository/remote/index.dart';

/// Api interceptor interface.
///
/// Every hook returns `FutureOr`, so an interceptor may be synchronous — just
/// return the value — or asynchronous, which is what makes an in-band token
/// refresh possible:
///
/// ```dart
/// @override
/// Future<ApiRequest<R, I>> onRequest<R, I>(ApiRequest<R, I> request) async {
///   final token = await _store.readToken();
///   return request.copyWith(headers: {'Authorization': 'Bearer $token'});
/// }
/// ```
abstract class ApiInterceptor {
  /// Intercepts the request and returns the modified request
  FutureOr<ApiRequest<ResponseType, InnerType>> onRequest<
    ResponseType,
    InnerType
  >(ApiRequest<ResponseType, InnerType> request) => request;

  /// Intercepts the response and returns the modified response
  FutureOr<ApiResponse<ResponseType, InnerType>> onResponse<
    ResponseType,
    InnerType
  >(ApiResponse<ResponseType, InnerType> response) => response;

  /// Intercepts the error and returns the modified response
  FutureOr<ApiResponse<ResponseType, InnerType>> onError<
    ResponseType,
    InnerType
  >(ApiResponse<ResponseType, InnerType> response) => response;
}

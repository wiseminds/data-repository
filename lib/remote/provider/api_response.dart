 

import 'package:data_repository/models/pagination.dart';

import 'api_request.dart';

class ApiResponse<BodyType, InnerType> {
  final int statusCode;
  final Map<String, dynamic>? headers;
  Map<String, dynamic>? extra;
  final dynamic bodyString;
  final BodyType? body;
  final Pagination? pagination;
  final ApiRequest<BodyType, InnerType> request;

  /// Body of response if [isSuccessful] is false
  final Object? error;

  /// true if status code is >= 200 && <3
  /// if false, [error] will contains the response
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  ApiResponse(
      {this.bodyString,
      this.pagination,
      this.statusCode = 500,
      this.headers,
      this.body,
      this.error,
      this.extra,
      required this.request});

  ApiResponse<BodyType, InnerType> copyWith(
          {int? statusCode,
          Object? error,
          Map<String, dynamic>? headers,
          dynamic? bodyString,
          BodyType? body,
          Pagination? pagination,
          Map<String, dynamic>? extra,
          ApiRequest<BodyType, InnerType>? request}) =>
      ApiResponse<BodyType, InnerType>(
          bodyString: bodyString ?? this.bodyString,
          statusCode: statusCode ?? this.statusCode,
          pagination: pagination ?? this.pagination,
          headers: headers ?? this.headers,
          body: body ?? this.body,
          error: error ?? this.error,
          extra: extra ?? this.extra,
          request: request ?? this.request);

  @override
  String toString() => '''
  body: $body,
  bodyString: $bodyString,
  headers: $headers,
  statusCode: $statusCode,
  error: $error,
  extra: $extra
  ''';

  ApiResponse<BodyType, InnerType> get resolve {
    // Log.i('running interceptors');
    var response = this;
    try {
      if (isSuccessful) {
        for (var e in request.interceptors) {
          response = e.onResponse(response);
        }
      } else {
        for (var e in request.interceptors) {
          response = e.onError(response);
        }
      }
    } catch (e) {
      // print(e);
    }
    return response;
  }
}

import 'package:data_repository/models/pagination.dart';
import 'package:data_repository/remote/interceptors/api_interceptor.dart';

import 'api_methods.dart';

class ApiRequest<ResponseType, InnerType> {
  final String? method, nestedKey;
  final String path;
  final int timeout;
  final String dataKey;
  final String baseUrl;
  final bool hasPagination;
  final Map<String, dynamic>? body;
  final Map<String, String> headers;
  final Map<String, dynamic> query;
  final List<ApiInterceptor> interceptors;
  final List<Extra>? extra;
  final ErrorDescription? error;
  final bool isMultipart;

  ApiRequest(
      {this.hasPagination = false,
      this.isMultipart = false,
      this.extra,
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
      this.body});

  factory ApiRequest.dummy() => ApiRequest<ResponseType, InnerType>(
      hasPagination: false,
      headers: {},
      query: {},
      method: ApiMethods.get,
      dataKey: '',
      isMultipart: false,
      path: '',
      baseUrl: '');

  ApiRequest<ResponseType, InnerType> copyWith(
          {String? method,
          String? path,
          String? dataKey,
          String? baseUrl,
          bool? hasPagination,
          Pagination? pagination,
          List<Extra>? extra,
          int? timeout,
          bool? isMultipart,
          Map<String, dynamic>? body,
          Map<String, String>? headers,
          List<ApiInterceptor>? interceptors,
          ErrorDescription? error,
          String? nestedKey,
          Map<String, dynamic>? query}) =>
      ApiRequest<ResponseType, InnerType>(
          hasPagination: hasPagination ?? this.hasPagination,
          headers: headers ?? this.headers,
          query: query ?? this.query,
          method: method ?? this.method,
          dataKey: dataKey ?? this.dataKey,
          nestedKey: nestedKey ?? this.nestedKey,
          isMultipart: isMultipart ?? this.isMultipart,
          path: path ?? this.path,
          extra: extra ?? this.extra,
          error: error ?? this.error,
          timeout: timeout ?? this.timeout,
          baseUrl: baseUrl ?? this.baseUrl,
          interceptors: [...?interceptors, ...this.interceptors],
          body: body ?? this.body);

  ApiRequest<ResponseType, InnerType> get build {
    // print('Building request: ${this.isMultipart}, url: $path');
    // Log.v('Building request: ${isMultipart}, url: $path,  ');
    var request = this;
    for (var e in request.interceptors) {
      request = e.onRequest(request);
    }
    return request;
  }

  Uri get uri {
    var u = Uri.parse('$baseUrl/$path').normalizePath();
   return u.replace(queryParameters: {
      ...query.map<String, String>((key, value) => MapEntry(key, '$headers')),
      ...u.queryParameters
    });
    // return u;
    // '$baseUrl/$path';
    // if (!url.contains('?'))
    //   url += '?';
    // else if (!url.endsWith('&')) {
    //   url += '&';
    // }
    // url += buildQuery;
    // return Uri.parse(url.normalizeUrl);
  }

  // String get buildQuery {
  //   String q = '';
  //   query.forEach((key, value) {
  //     if (value != null) q += '$key=$value&';
  //   });
  //   // print('Building query $q, $query');
  //   return q;
  // }
}

class ErrorDescription {
  final String key;

  ErrorDescription({this.key = 'error'});
}

class Extra<T> {
  final String key;

  Extra(this.key);
}

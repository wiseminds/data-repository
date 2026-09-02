import 'dart:convert';

import 'package:data_repository/models/json_factory.dart';
import 'package:data_repository/models/pagination.dart';
import 'package:data_repository/remote/api_response.dart';
import 'package:data_repository/utils/api_config.dart';

import 'api_interceptor.dart';

/// Decodes response bodies into typed models using a registry of factories.
///
/// ```dart
/// JsonInterceptor<ErrorModel>(
///   {Post: Post.fromJson, ErrorModel: ErrorModel.fromJson},
///   paginationFactory: PaginationModel.fromJson,
/// )
/// ```
///
/// [ErrorType] is the model an unsuccessful response's body is decoded into;
/// register a factory for it in [jsonFactories] as well.
class JsonInterceptor<ErrorType> extends ApiInterceptor {
  /// Maps a model type to the function that builds it from a JSON map.
  final Map<Type, JsonFactory> jsonFactories;

  /// Builds the [Pagination] for requests declaring `hasPagination: true`.
  final JsonFactory<Pagination>? paginationFactory;

  JsonInterceptor(this.jsonFactories, {this.paginationFactory});

  @override
  ApiResponse<ResponseType, InnerType> onResponse<ResponseType, InnerType>(
    ApiResponse<ResponseType, InnerType> response,
  ) {
    var decoded = _tryDecodeJson(response.bodyString);

    final nestedKey = response.request.nestedKey;
    if (nestedKey != null && nestedKey.isNotEmpty) {
      decoded = _getBody(decoded, nestedKey);
    }

    Pagination? pagination;
    if (response.request.hasPagination && paginationFactory != null) {
      final source = _getBody(decoded);
      if (source is Map<String, dynamic>) {
        pagination = paginationFactory!(source);
      }
    }

    final body = _decode<InnerType>(
      _getBody(decoded, response.request.dataKey),
    );
    return response.copyWith(body: body, pagination: pagination);
  }

  @override
  ApiResponse<ResponseType, InnerType> onError<ResponseType, InnerType>(
    ApiResponse<ResponseType, InnerType> response,
  ) {
    // An error already set by a lower layer (a transport failure, or an
    // interceptor that threw) is authoritative — do not overwrite it with a
    // decode of the body.
    if (response.error != null) return response;

    try {
      final decoded = _getBody(
        _tryDecodeJson(response.bodyString),
        response.request.error?.key,
      );
      return response.copyWith(error: _decode<ErrorType>(decoded));
    } catch (e, trace) {
      // The original implementation referenced `json` here — dart:convert's
      // top-level codec object, not the decoded body — and silently produced
      // a meaningless error. Report and leave the response untouched instead.
      ApiConfig().log('failed to decode error body: $e\n$trace');
      return response;
    }
  }

  dynamic _decode<T>(dynamic entity) {
    if (entity is Iterable) return _decodeList<T>(entity);
    if (entity is Map) return _decodeMap<T>(Map<String, dynamic>.from(entity));
    return entity;
  }

  List<T> _decodeList<T>(Iterable values) =>
      values.where((v) => v != null).map<T>((v) => _decode<T>(v) as T).toList();

  T? _decodeMap<T>(Map<String, dynamic> values) {
    final factory = jsonFactories[T];
    if (factory == null) {
      ApiConfig().log('no JsonFactory registered for $T');
      return null;
    }
    return factory(values) as T?;
  }

  dynamic _getBody(dynamic body, [String? key]) {
    if (key == null || key.isEmpty) return body;
    if (body is Map && body.containsKey(key)) return body[key];
    return body;
  }

  dynamic _tryDecodeJson(dynamic data) {
    if (data == null) return null;
    if (data is Map || data is Iterable) return data;
    try {
      return jsonDecode(data.toString());
    } catch (e) {
      ApiConfig().log('response body was not JSON: $e');
      return data;
    }
  }
}

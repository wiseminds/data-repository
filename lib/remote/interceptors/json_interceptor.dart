import 'dart:convert';

import 'package:data_repository/models/json_factory.dart';
import 'package:data_repository/models/pagination.dart';
import 'package:data_repository/remote/api_response.dart';
import 'package:data_repository/utils/api_config.dart';
import 'package:data_repository/utils/json_path.dart';

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
    final decoded = _tryDecodeJson(response.bodyString);

    // The envelope is where pagination lives; the data path is resolved
    // relative to it, so the two anchors stay independent.
    final envelope = _resolve(decoded, response.request.nestedKey, 'nestedKey');

    Pagination? pagination;
    if (response.request.hasPagination && paginationFactory != null) {
      if (envelope is Map<String, dynamic>) {
        pagination = paginationFactory!(envelope);
      }
    }

    final body = _decode<InnerType>(
      _resolve(envelope, response.request.dataKey, 'dataKey'),
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
      final decoded = _resolve(
        _tryDecodeJson(response.bodyString),
        response.request.error?.key,
        'error',
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

  /// Resolves a dotted [path] against [body].
  ///
  /// An empty or absent path selects [body] itself. A path that does not
  /// resolve yields null and logs the segment that failed, rather than
  /// silently handing back the whole body for a typo.
  dynamic _resolve(dynamic body, String? path, String label) {
    if (path == null || path.isEmpty) return body;

    final result = JsonPath.parse(path).resolve(body);
    if (result.found) return result.value;

    ApiConfig().log(
      '$label "$path" did not resolve: nothing at "${result.missingAt}"',
    );
    return null;
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

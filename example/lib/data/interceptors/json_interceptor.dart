// ignore_for_file: avoid_print

import 'dart:convert';

// import 'package:common/models/error_model.dart';
import 'package:example/models/pagination/pagination.dart' as m;
import 'package:data_repository/data_repository.dart';
import 'package:flutter/foundation.dart';

abstract class ToJson {
  Map<String, dynamic> toJson();
}

typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

class JsonInterceptor<ErrorType extends ApiError> implements ApiInterceptor {
  final Map<Type, dynamic Function(Map<String, dynamic>)> jsonFactories;

  JsonInterceptor(this.jsonFactories);

  ///convert a value to a json encoded string
  dynamic convertToJson<T>(dynamic data) {
    return json.encode(_encode<T>(data));
  }

  dynamic _serialize<T>(T value) {
    if ((value is Map<String, dynamic>)) return value;
    if (value is ToJson) return value.toJson();
    return value;
  }

  List<T> _serializeListOf<T>(List value) => List.castFrom(
        value.map((value) => _serialize<T>(value)).toList(),
      );

  dynamic _encode<T>(entity) {
    /// handle case when we want to access to Map<String, dynamic> directly
    /// getResource or getMapResource
    /// Avoid dynamic or unconverted value, this could lead to several issues
    if (entity is String) return entity;

    try {
      if (entity is List) return _serializeListOf<T>(entity);
      return _serialize<T>(entity);
    } catch (e) {
      if (kDebugMode) print(e);
      return null;
    }
  }

  T? _decodeMap<T>(Map<String, dynamic> values) {
    /// Get jsonFactory using Type parameters
    /// if not found or invalid, throw error or return null
    final jsonFactory = jsonFactories[T];
    if (jsonFactory == null || jsonFactory is! JsonFactory<T>) {
      /// throw serializer not found error;
      return null;
    }
    return jsonFactory(values);
  }

  List<T> _decodeList<T>(List values) =>
      values.where((v) => v != null).map<T>((v) => _decode<T>(v)).toList();

  dynamic _decode<T>(entity) {
    if (entity is Iterable) return _decodeList<T>(entity as List);

    if (entity is Map) return _decodeMap<T>(entity as Map<String, dynamic>);

    return entity;
  }

  dynamic _getBody(dynamic body, [String? key = '']) {
    if (kDebugMode) print('get body, $key, ${body.runtimeType}, $body');
    try {
      if (key == '') return body;
      return body[key] ?? body;
    } catch (e) {
      if (kDebugMode) print('get body error, $key, ${body.runtimeType}, $body');
      return body;
    }
  }

  ///convert a  json string  to a builtvalue  with type [ResultType]
  ResultType? convertFromJson<ResultType, Item>(dynamic data, [String? key]) {
    try {
      if (data is String) data = json.decode(data);
      if (data is String) data = json.decode(data);
    } catch (e) {
      if (kDebugMode) {
        print(
            'in convert fromjson error $e, $key, ${data?.runtimeType}, $data');
      }
    }
    try {
      return _decode<Item>(_getBody(data, key));
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  ApiResponse<ResponseType, InnerType> onResponse<ResponseType, InnerType>(
      ApiResponse<ResponseType, InnerType> response) {
    Pagination? pagination;

    if (kDebugMode) {
      print(
          'in convert response ${response.statusCode} ${response.bodyString.runtimeType}, ${response.bodyString}');
    }
    var jsn = _tryDecodeJson(response.bodyString);
    // if (jsn['status'] == false) return onError(response);
    if (response.request.nestedKey != null &&
        (response.request.nestedKey?.isNotEmpty ?? false)) {
      jsn = _getBody(jsn, response.request.nestedKey);
    }
    if (kDebugMode) print('in convert response ${jsn.runtimeType}, $jsn');

    if (response.request.hasPagination) {
      pagination = _decode<m.Pagination>(_getBody(jsn));
    }

    try {
      final body = _decode<InnerType>(_getBody(jsn, response.request.dataKey));
      if (kDebugMode) print(body?.toString());
      return response.copyWith(body: body, pagination: pagination);
    } catch (e, _) {
      print(e);
      print('error, $_');
      return response.copyWith(body: null, pagination: pagination);
    }
    // pagination: pagination);
  }

  dynamic _tryDecodeJson(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (kDebugMode) print(data.runtimeType);
    try {
      return jsonDecode(data.toString());
    } catch (e) {
      if (kDebugMode) print(e.toString());
      return data;
    }
  }

  @override
  ApiResponse<ResponseType, InnerType> onError<ResponseType, InnerType>(
      ApiResponse<ResponseType, InnerType> response) {
    try {
      if (kDebugMode) {
        // print(
        //     'in convert error ${response.bodyString}, ${response.error?.runtimeType}, ${response.error?.runtimeType is ErrorModel}');
      }

      if (response.error != null) {
        return response.copyWith(error: response.error);
      }

      var json = _tryDecodeJson(response.bodyString);

      json = _getBody(json, response.request.error?.key);

      // if ((json as Map<String, dynamic>?)?.getKey('message') is List) {
      var body = _decode<ErrorType>(json);
      return response.copyWith(error: body);
      // }

      // return response.copyWith(error: Error());
    } catch (e) {
      var body = _decode<ErrorType>(json);
      return response.copyWith(error: body);
    }
  }

  @override
  ApiRequest<ResponseType, InnerType> onRequest<ResponseType, InnerType>(
      ApiRequest<ResponseType, InnerType> request) {
    return request;
  }
}

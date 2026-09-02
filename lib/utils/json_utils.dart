import 'dart:convert';

import 'api_config.dart';

/// Thrown by [JsonUtils.convertToJson] when a value cannot be serialised.
class JsonSerializationException implements Exception {
  final Object? value;

  JsonSerializationException(this.value);

  @override
  String toString() =>
      'JsonSerializationException: ${value.runtimeType} has no toJson()';
}

class JsonUtils {
  static String encode(dynamic json) => jsonEncode(json);

  static dynamic decode(String json) => jsonDecode(json);

  /// Serialises [data] to a JSON string.
  ///
  /// Throws [JsonSerializationException] when a value cannot be serialised,
  /// rather than returning the string "null" for the caller to cache.
  static String convertToJson(dynamic data) => json.encode(_encode(data));

  static dynamic _serialize(dynamic value) {
    if (value is Map || value is String || value is num || value is bool) {
      return value;
    }
    if (value == null) return null;
    try {
      // Deliberately dynamic: any type exposing toJson() is supported.
      return value.toJson();
    } on NoSuchMethodError {
      ApiConfig().log('cannot serialise ${value.runtimeType}: no toJson()');
      throw JsonSerializationException(value);
    }
  }

  static List _serializeListOf(Iterable value) =>
      value.map(_serialize).toList(growable: false);

  static dynamic _encode(dynamic entity) {
    /// handle case when we want to access to Map<String, dynamic> directly
    /// getResource or getMapResource
    /// Avoid dynamic or unconverted value, this could lead to several issues
    if (entity is String) return entity;
    if (entity is Iterable) return _serializeListOf(entity);
    return _serialize(entity);
  }
}

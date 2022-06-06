import 'dart:convert';

import 'package:flutter/foundation.dart';

class Jsonutils {
  static String encode(dynamic json) {
    return jsonEncode(json);
  }

  static dynamic decode(String json) {
    return jsonDecode(json);
  }

  static dynamic convertToJson(dynamic data) {
    return json.encode(_encode(data));
  }

  static dynamic _serialize<T>(dynamic value) {
    if (value is Map<String, dynamic> || value is String) return value;
    try {
      if (value.toJson != null) return value.toJson();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  static List<T> _serializeListOf<T>(Iterable value) => List.castFrom(
        value.map((value) => _serialize<T>(value)).toList(growable: false),
      );

  static dynamic _encode<T>(entity) {
    /// handle case when we want to access to Map<String, dynamic> directly
    /// getResource or getMapResource
    /// Avoid dynamic or unconverted value, this could lead to several issues
    if (entity is String) return entity;

    try {
      if (entity is Iterable) return _serializeListOf<T>(entity);
      return _serialize<T>(entity);
    } catch (e) {
      if (kDebugMode) print(e);
      return null;
    }
  }
}

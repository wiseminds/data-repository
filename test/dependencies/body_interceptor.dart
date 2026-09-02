import 'dart:convert';

import 'package:data_repository/data_repository.dart';

/// Minimal interceptor that promotes the decoded [ApiResponse.bodyString] to
/// [ApiResponse.body], so cache tests exercise caching rather than decoding.
class BodyInterceptor extends ApiInterceptor {
  @override
  ApiResponse<R, I> onResponse<R, I>(ApiResponse<R, I> response) {
    final raw = response.bodyString;
    final decoded = raw is String ? jsonDecode(raw) : raw;
    return response.copyWith(body: decoded);
  }
}

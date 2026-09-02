import 'package:data_repository/remote/api_request.dart';
import 'package:data_repository/remote/api_response.dart';
import 'package:data_repository/utils/api_config.dart';

import 'api_interceptor.dart';

/// Logs each request and its outcome through `ApiConfig().logger`.
///
/// Nothing is emitted unless a logger is configured, so adding this to a
/// request chain is inert in production by default:
///
/// ```dart
/// ApiConfig().logger = debugPrint;
/// // ...
/// interceptors: [LoggingInterceptor()]
/// ```
class LoggingInterceptor extends ApiInterceptor {
  /// Whether to log request and response headers.
  final bool logHeaders;

  /// Whether to log request and response bodies.
  final bool logBody;

  /// Maximum number of body characters to log before truncating.
  final int maxBodyLength;

  /// Header names replaced with `***` in the output, matched case-insensitively.
  final Set<String> redactHeaders;

  final Map<String, int> _startedAt = {};

  LoggingInterceptor({
    this.logHeaders = true,
    this.logBody = true,
    this.maxBodyLength = 1000,
    Set<String>? redactHeaders,
  }) : redactHeaders =
           (redactHeaders ??
                   const {'authorization', 'cookie', 'set-cookie', 'x-api-key'})
               .map((h) => h.toLowerCase())
               .toSet();

  @override
  ApiRequest<R, I> onRequest<R, I>(ApiRequest<R, I> request) {
    _startedAt[request.requestId] = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer('--> ${request.method} ${request.uri}');
    if (logHeaders && request.headers.isNotEmpty) {
      buffer.write('\n    headers: ${_redact(request.headers)}');
    }
    if (logBody && request.body != null) {
      buffer.write('\n    body: ${_truncate(request.body.toString())}');
    }
    ApiConfig().log(buffer.toString());
    return request;
  }

  @override
  ApiResponse<R, I> onResponse<R, I>(ApiResponse<R, I> response) =>
      _logOutcome(response);

  @override
  ApiResponse<R, I> onError<R, I>(ApiResponse<R, I> response) =>
      _logOutcome(response);

  ApiResponse<R, I> _logOutcome<R, I>(ApiResponse<R, I> response) {
    final started = _startedAt.remove(response.request.requestId);
    final ms = started == null
        ? null
        : DateTime.now().millisecondsSinceEpoch - started;

    final buffer = StringBuffer(
      '<-- ${response.statusCode} '
      '${response.request.method} ${response.request.uri}'
      '${ms == null ? '' : ' (${ms}ms)'}',
    );
    if (response.error != null) buffer.write('\n    error: ${response.error}');
    if (logHeaders && (response.headers?.isNotEmpty ?? false)) {
      buffer.write('\n    headers: ${_redact(response.headers!)}');
    }
    if (logBody && response.bodyString != null) {
      buffer.write('\n    body: ${_truncate(response.bodyString.toString())}');
    }
    ApiConfig().log(buffer.toString());
    return response;
  }

  Map<String, dynamic> _redact(Map<String, dynamic> headers) => {
    for (final e in headers.entries)
      e.key: redactHeaders.contains(e.key.toLowerCase()) ? '***' : e.value,
  };

  String _truncate(String value) => value.length <= maxBodyLength
      ? value
      : '${value.substring(0, maxBodyLength)}... (${value.length} chars)';
}

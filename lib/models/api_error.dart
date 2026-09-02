/// The normalised error type surfaced on [ApiResponse.error].
///
/// This type is deliberately minimal: consumers commonly declare their own
/// error model with `implements ApiError`, so every member added here becomes
/// a breaking change for them. The original throwable and its stack trace are
/// carried on [ApiResponse.cause] / [ApiResponse.stackTrace] instead.
class ApiError {
  final String message;
  final int code;

  ApiError(this.message, this.code);

  @override
  String toString() => 'ApiError(message: $message, code: $code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiError && other.message == message && other.code == code;

  @override
  int get hashCode => Object.hash(message, code);
}

extension ApiErrorStatus on ApiError {
  /// True when [ApiError.code] falls in the range of a real HTTP status code,
  /// meaning it can meaningfully be surfaced as `ApiResponse.statusCode`.
  ///
  /// Declared as an extension rather than a member so that adding it does not
  /// oblige every `implements ApiError` consumer to supply it.
  bool get hasHttpStatusCode => code >= 100 && code <= 599;
}

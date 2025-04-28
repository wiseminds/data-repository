class ApiError {
  final String message;
  final int code;

  ApiError(this.message, this.code);

  @override
  String toString() {
    return 'ApiError(message: $message, code: $code)';
  }
}

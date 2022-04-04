class ApiError<T> {
  final String message;
  final int code;
  final T? error;

  ApiError(this.message, this.code, [this.error]);
}

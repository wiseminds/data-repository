/// Process-wide configuration for the package.
class ApiConfig {
  static final ApiConfig _singleton = ApiConfig._internal();

  factory ApiConfig() => _singleton;

  ApiConfig._internal();

  /// Error code reported when an interceptor throws while resolving a response.
  static const int interceptorFailureCode = 7013;

  String defaultErrorMessage = 'Something went wrong';

  /// Sink for the package's diagnostic output.
  ///
  /// Null (the default) means silent — the package will not write to the
  /// console of an app that did not ask for it. Opt in with:
  ///
  /// ```dart
  /// ApiConfig().logger = debugPrint;
  /// ```
  void Function(String message)? logger;

  /// Emits [message] to [logger] when one is configured, and does nothing
  /// otherwise.
  void log(String message) => logger?.call(message);
}

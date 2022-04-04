class ApiConfig {
  String defaultErrorMessage = 'Something went wrong';
  static final ApiConfig _singleton = ApiConfig._internal();

  factory ApiConfig() {
    return _singleton;
  }

  ApiConfig._internal();
}

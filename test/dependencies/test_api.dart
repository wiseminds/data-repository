import 'package:data_repository/remote/index.dart';

class TestApi {
  ApiRequest<Map<String, dynamic>, Map<String, dynamic>> triggerError(
      String? errorType) {
    return ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
        path: '/error',
        baseUrl: '',
        query: {'type': errorType},
        method: ApiMethods.get,
        dataKey: '',
        error: ErrorDescription(),
        interceptors: [
          HeaderInterceptor({
            // 'Authorization': 'Bearer $token',
            "Content-Type": "application/json",
            "Accept": "application/json",
          }),
        ]);
  }

  ApiRequest<Map<String, dynamic>, Map<String, dynamic>> testCache() {
    return ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
        baseUrl: '',
        path: '/cache',
        method: ApiMethods.get,
        dataKey: '',
        error: ErrorDescription(),
        interceptors: [
          HeaderInterceptor({
            // 'Authorization': 'Bearer $token',
            "Content-Type": "application/json",
            "Accept": "application/json",
          }),
        ]);
  }
}

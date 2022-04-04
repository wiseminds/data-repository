import 'package:data_repository/remote/provider/api_request.dart';

import '../provider/api_response.dart';

/// Api interceptor interface
abstract class ApiInterceptor {
  /// Intercepts the request and returns the modified request
  ApiRequest<ResponseType, InnerType> onRequest<ResponseType, InnerType>(
          ApiRequest<ResponseType, InnerType> request) =>
      request;

  /// Intercepts the response and returns the modified response
  ApiResponse<ResponseType, InnerType> onResponse<ResponseType, InnerType>(
          ApiResponse<ResponseType, InnerType> response) =>
      response;

  /// Intercepts the error and returns the modified error
  ApiResponse<ResponseType, InnerType> onError<ResponseType, InnerType>(
          ApiResponse<ResponseType, InnerType> response) =>
      response;
}

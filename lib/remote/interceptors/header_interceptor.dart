import 'package:data_repository/remote/api_request.dart';

import 'api_interceptor.dart';

/// an interceptor to add headers to a request before initiating it
class HeaderInterceptor extends ApiInterceptor {
  final Map<String, String> headers;

  HeaderInterceptor(this.headers);

  @override
  ApiRequest<ResponseType, InnerType> onRequest<ResponseType, InnerType>(
    ApiRequest<ResponseType, InnerType> request,
  ) {
    // Headers already on the request win, so a per-call override beats the
    // defaults configured on this interceptor.
    return request.copyWith(headers: {...headers, ...request.headers});
  }
}

import "dart:async";

import 'package:data_repository/remote/api_request.dart';
import 'package:data_repository/remote/api_response.dart';
import 'package:data_repository/remote/request_options.dart';
import 'package:data_repository/utils/exception_formatter.dart';

/// The transport seam.
///
/// Everything above this interface — repositories, caching, retries,
/// interceptors — is transport agnostic. Implement it to run requests over
/// something other than `package:http` (a Dio client, a gRPC gateway, an
/// in-memory fake for tests) and inject that implementation into
/// [RemoteRepository]; nothing else in the stack has to change.
abstract class ApiProvider with ExceptionFormatter {
  Future<ApiResponse<ResponseType, InnerType>> send<ResponseType, InnerType>(
    ApiRequest<ResponseType, InnerType> request, [
    RequestOptions options,
  ]);

  /// Releases any resources the provider holds. Safe to call more than once.
  void close() {}
}

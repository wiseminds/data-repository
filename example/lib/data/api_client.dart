import 'package:data_repository/data_repository.dart';
import 'package:get_it/get_it.dart';

import '../env.dart';

class ApiClient {
  static var env = GetIt.I.get<Env>();
  static ApiRequest<ResponseType, InnerType>
      baseRequest<ResponseType, InnerType>() =>
          ApiRequest<ResponseType, InnerType>(
            baseUrl: env.baseUrl,
            error: ErrorDescription(),
            dataKey: 'data',
            interceptors: [
              HeaderInterceptor({
                // 'Authorization': 'Bearer ${GetIt.I<AuthBloc>().state.token}',
                "Content-Type": "application/json",
                "Accept": "application/json",
              }),
              // AuthInterceptor(),
            ],
          );
  static ApiRequest<ResponseType, InnerType>
      baseRequestNoAuth<ResponseType, InnerType>() =>
          ApiRequest<ResponseType, InnerType>(
            error: ErrorDescription(),
            baseUrl: env.baseUrl,
            dataKey: 'data',
            interceptors: [
              HeaderInterceptor({
                "Content-Type": "application/json",
                "Accept": "application/json",
              }),
              // AuthInterceptor(),
            ],
          );
}

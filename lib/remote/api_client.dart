// import 'dart:io';

// import 'provider/api_request.dart';

// class ApiClient {
//   static get kTestMode => false; // ?? (GetIt.instance<Env>() is Test);

//   static var env = GetIt.I.get<Env>();
//   static ApiRequest<ResponseType, InnerType>
//       baseRequest<ResponseType, InnerType>([String? token]) =>
//           ApiRequest<ResponseType, InnerType>(
//             baseUrl:
//                 kTestMode ? 'http://localhost:4041' : (env.baseUrl + '/api'),
//             dataKey: 'data',
//             interceptors: [
//               HeaderInterceptor({
//                 'Authorization':
//                     'Bearer ${kTestMode ? '' : token ?? Auth.state.token}',
//                 "Content-Type": "application/json",
//                 "Accept": "application/json",
//                 "operating-system": Platform.isIOS ? 'ios' : 'android',
//                 "source": "mobile",
//                 "version-build":
//                     GetIt.I<VersionsManager>().versionInfo?.buildNumber ?? '',
//                 "version-code":
//                     GetIt.I<VersionsManager>().versionInfo?.version ?? '',
//               }),
//             ],
//           );
// }

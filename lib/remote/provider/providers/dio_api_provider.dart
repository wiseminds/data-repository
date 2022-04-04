// import "dart:async";
// import 'dart:io'; 
// import 'package:flutter/foundation.dart';

// import '../../file_field.dart';
// import '../api_provider.dart';
// import '../api_request.dart';
// import '../api_response.dart';

// class DioApiProvider extends ApiProvider {
//   @override
//   Future<ApiResponse<ResulType, InnerType>> send<ResulType, InnerType>(
//       ApiRequest<ResulType, InnerType> request) async {
//     request = request.build;
//     var client = Dio(BaseOptions(
//         baseUrl: request.baseUrl,
//         // connectTimeout: request.timeout,
//         headers: request.headers,
//         // sendTimeout: request.timeout,
//         method: request.method,
//         queryParameters: request.query));

//     (client.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
//         (HttpClient client) {
//       client.badCertificateCallback =
//           (X509Certificate cert, String host, int port) => true;
//       return client;
//     };

//     Response response;
//     try {
//       if (kDebugMode)
//         print(
//             'handling request ${request.isMultipart} ${request.body} ${request.path}');
//       if (request.isMultipart) {
//         Map<String, dynamic> parts = <String, dynamic>{};
//         request.body?.forEach((key, value) async {
//           if (value is FileFormField) {
//             MultipartFile file = MultipartFile.fromFileSync(value.path);
//             parts.putIfAbsent(key, () => file);
//           } else
//             parts.putIfAbsent(key, () => value);
//           // if (kDebugMode)
//           //   print('multipart request: $parts ${FormData.fromMap(parts)}');
//         });

//         response = await client
//             .request('/${request.path}',
//                 data: FormData.fromMap(parts), queryParameters: request.query)
//             .timeout(Duration(seconds: request.timeout), onTimeout: () {
//           throw (TimeoutException('Connection timed out'));
//         });
//       } else
//         response = await client
//             .request('/${request.path}',
//                 data: request.body, queryParameters: request.query)
//             .timeout(Duration(seconds: request.timeout), onTimeout: () {
//           throw (TimeoutException('Connection timed out'));
//         });
//     } on DioError catch (e) {
//       if (kDebugMode) print(' error in request ');
//       if (kDebugMode) print(e.toString());
//       if (kDebugMode)
//         print(
//             'message: ${e.message}, error: ${e.error}, data: ${e.response?.data}, type:${e.type}');
//       return ApiResponse<ResulType, InnerType>(
//         request: request,
//         headers: e.response?.headers.map,
//         statusCode: e.response?.statusCode ?? 400,
//         bodyString: e.response?.data,
//         // error: (e is ErrorModel) ? e : formatErrorMessage(e)
//       ).resolve;
//     }
//     client.close();
//     return ApiResponse<ResulType, InnerType>(
//             request: request,
//             bodyString: response.data,
//             headers: response.headers.map,
//             statusCode: response.statusCode ?? 500)
//         .resolve;
//   }
// }

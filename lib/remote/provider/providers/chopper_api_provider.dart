// import "dart:async";
// import 'dart:convert';
// import 'package:chopper/chopper.dart';
// import 'package:mobile/data/remote/provider/api_request.dart';
// import 'package:mobile/models/error_model.dart';
// import 'package:flutter/foundation.dart';

// import '../../file_field.dart';
// import '../api_provider.dart';
// import '../api_response.dart';

// class ChopperApiProvider extends ApiProvider {
//   @override
//   Future<ApiResponse<ResponseType, InnerType>> send<ResponseType, InnerType>(
//       ApiRequest<ResponseType, InnerType> request) async {
//     request = request.build;
//     var client = ChopperClient(
//       interceptors: [
//         if (kDebugMode) HttpLoggingInterceptor(),
//       ],
//     );
//     Request _request;
//     if (request.isMultipart) {
//       List<PartValue<dynamic>> parts = [];
//       request.body.forEach((key, value) {
//         if (value is FileFormField)
//           parts.add(PartValueFile<String>(key, value.path));
//         else
//           parts.add(PartValue(value.key, value));
//       });
//       _request = Request(request.method, request.path, request.baseUrl,
//           // body: json.encode(request.body),
//           headers: request.headers,
//           multipart: true,
//           parts: parts,
//           parameters: request.query);
//     } else
//       _request = Request(request.method, request.path, request.baseUrl,
//           body: json.encode(request.body),
//           headers: request.headers,
//           multipart: false,
//           parameters: request.query);

//     Response response;
//     try {
//       response = await client
//           .send(_request)
//           .timeout(Duration(seconds: request.timeout), onTimeout: () {
//         throw (TimeoutException('Connection timed out'));
//       });

//       client.dispose();
//       return ApiResponse<ResponseType, InnerType>(
//               request: request,
//               bodyString: response?.bodyString,
//               headers: response?.headers,
//               statusCode: response?.statusCode,
//               error: response?.error)
//           ?.resolve;
//     } catch (e) {
//       if (kDebugMode) print(' error in request ');
//       if (kDebugMode) print(e?.toString());
//       return ApiResponse<ResponseType, InnerType>(
//               request: request,
//               bodyString: null,
//               headers: {},
//               statusCode: 400,
//               error: (e is ErrorModel) ? e : formatErrorMessage(e))
//           ?.resolve;
//     }
//   }
// }

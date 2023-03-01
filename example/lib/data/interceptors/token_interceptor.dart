// import 'package:customer/models/index.dart';
// import 'package:data_repository/data_repository.dart';
// import 'package:flutter/foundation.dart';

// import 'json_interceptor.dart';

// class TokenInterceptor extends ApiInterceptor {
//   static const accessToken = 'token';
//   // static const refreshToken = 'refresh';

//   @override
//   ApiResponse<ResponseType, InnerType> onResponse<ResponseType, InnerType>(
//       ApiResponse<ResponseType, InnerType> response) {
//     if (kDebugMode) print('in TokenInterceptor ${response.statusCode}');
//     if (response.isSuccessful) {
//       // var data = JsonInterceptor(Models.factories)
//       //     .convertFromJson<Map<String, dynamic>, Map<String, dynamic>>(
//       //   response.bodyString,
//       // );
//       var token = JsonInterceptor(Models.factories)
//           .convertFromJson<String, String>(response.bodyString, accessToken);
//       // var refresh = data?.getKey(refreshToken);

//       if (kDebugMode) {
//         print('in TokenInterceptor    $token,  ');
//       }

//       return response.copyWith(extra: <String, dynamic>{
//         // refreshToken: refresh,
//         accessToken: token,
//         ...?response.extra
//       });
//     }

//     return response;
//   }
// }

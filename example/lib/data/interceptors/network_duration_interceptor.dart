import 'package:data_repository/data_repository.dart';
import 'package:flutter/foundation.dart';

class NetworkDurationInterceptor extends ApiInterceptor {
  Map<String, int> timestamp = {};

  @override
  ApiResponse<ResponseType, InnerType> onResponse<ResponseType, InnerType>(
      ApiResponse<ResponseType, InnerType> response) {
    if (kDebugMode) {
      print(
          'NetworkDurationInterceptor ${response.statusCode}, ${response.request.requestId}, $timestamp ${timestamp[response.request.requestId]}');
    }

    var duration = DateTime.now().millisecondsSinceEpoch -
        (timestamp.remove(response.request.requestId) ?? 00);

    if (kDebugMode) {
      print('request completed in $duration milliseconds');
    }

    return response.copyWith(extra: {...?response.extra, 'duration': duration});
  }

  @override
  ApiRequest<ResponseType, InnerType> onRequest<ResponseType, InnerType>(
      ApiRequest<ResponseType, InnerType> request) {
    timestamp
        .addAll({request.requestId: DateTime.now().millisecondsSinceEpoch});
    return request; //.copyWith(: );
  }

  @override
  ApiResponse<ResponseType, InnerType> onError<ResponseType, InnerType>(
      ApiResponse<ResponseType, InnerType> response) {
    var duration = DateTime.now().millisecondsSinceEpoch -
        (timestamp.remove(response.request.requestId) ?? 00);

    if (kDebugMode) {
      print('request completed with error in $duration milliseconds');
    }

    return response.copyWith(extra: {...?response.extra, 'duration': duration});
  }
}

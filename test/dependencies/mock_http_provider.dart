import 'package:data_repository/data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:mockito/mockito.dart';

class MockHttpApiProvider extends Mock implements ApiProvider {
  // You can override the send method to return a mock response
  @override
  Future<ApiResponse<ResultType, InnerType>> send<ResultType, InnerType>(
      ApiRequest<ResultType, InnerType> request) {
    if (kDebugMode) {
      print('handling request, ${request.path}, ${request.query}');
    }
    // Mock implementation: return a fake ApiResponse based on the request
    switch (request.path) {
      case '/cache':
        return Future.value(ApiResponse<ResultType, InnerType>(
          request: request,
          bodyString: '{"data": "mock data"}', // Example mock response body
          headers: {"Content-Type": "application/json"},
          statusCode: 200, // Mock status code
        ));
      case '/error':
        // print(ExceptionFormater.errorToObject);
        var error =
            ExceptionFormater.errorToObject[request.query['type'].toString()];
        throw error!;
      default:
        return Future.value(ApiResponse<ResultType, InnerType>(
          request: request,
          bodyString: '{"data": "mock data"}', // Example mock response body
          headers: {"Content-Type": "application/json"},
          statusCode: 200, // Mock status code
        ));
    }
  }
}

import 'package:data_repository/data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dependencies/mock_http_provider.dart';
import 'dependencies/test_repository.dart';

void main() {
  group('HttpApiProvider Tests', () {
    late LocalRepository localRepository;
    late RemoteRepository remoteRepository;
    late TestRepository repository;

    setUp(() {
      remoteRepository = RemoteRepository(MockHttpApiProvider());
      localRepository = MapRepository();
      repository = TestRepository(localRepository, remoteRepository);
    });

    test('Test Exception Formater', () async {
      for (var type in ExceptionFormater.errorToObject.keys) {
        if (kDebugMode) {
          print('testing $type');
        }
        var response = await repository.triggerError(type);
        expect(response.error, isA<ApiError>());
        expect(
            (response.error as ApiError).message,
            repository
                .formatErrorMessage(ExceptionFormater.errorToObject[type], '')
                .message);
      }
    });

    // test('testCache method returns mock response', () async {
    //   // Prepare a mock request
    //   final request = ApiRequest<String, String>(
    //     baseUrl: 'https://example.com',
    //     path: '/data',
    //     method: 'GET',
    //   );

    //   // Use the mock provider
    //   final response = await repository.testCache('testCache', 1000);

    //   // Assert that the mock response is returned
    //   expect(response.statusCode, 200);
    //   expect(response.bodyString, '{"data": "mock data"}');
    // });
  });
}

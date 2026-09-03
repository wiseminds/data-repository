import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final request = ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
    baseUrl: 'https://example.com',
    path: 'posts',
  );

  group('ApiResponse.copyWith', () {
    final response = ApiResponse<Map<String, dynamic>, Map<String, dynamic>>(
      request: request,
      statusCode: 200,
      body: const {'a': 1},
      error: 'boom',
    );

    test('omitted arguments preserve the current value', () {
      expect(response.copyWith(statusCode: 201).body, {'a': 1});
      expect(response.copyWith(statusCode: 201).error, 'boom');
    });

    test('an explicit null clears the field', () {
      // Regression: `x ?? this.x` made copyWith(body: null) a silent no-op,
      // so a decode failure returned the previous body.
      expect(response.copyWith(body: null).body, isNull);
      expect(response.copyWith(error: null).error, isNull);
    });

    test('replaces a non-null value', () {
      expect(response.copyWith(body: const {'b': 2}).body, {'b': 2});
    });

    test('accepts a dynamically keyed map', () {
      // Regression: `body` is typed Object? for the sentinel, so a
      // Map<dynamic, dynamic> from an interceptor reached a cast that threw.
      final dynamic decoded = Map<dynamic, dynamic>.from({'b': 2});
      expect(response.copyWith(body: decoded).body, {'b': 2});
    });
  });

  group('ApiRequest.copyWith', () {
    test('preserves requestId so a request stays traceable', () {
      expect(request.copyWith(path: 'other').requestId, request.requestId);
    });

    test('an explicit null clears a nullable field', () {
      final withBody = request.copyWith(body: {'a': 1});
      expect(withBody.body, {'a': 1});
      expect(withBody.copyWith(body: null).body, isNull);
    });

    test('a dynamically keyed body map is re-keyed, not rejected', () {
      // Regression: the sentinel types `body` as Object?, so a map built
      // without a context type (`Map.from`, a platform channel, a bare `{}`)
      // slipped past the analyzer and blew up on `as Map<String, dynamic>?`.
      final dynamic decoded = Map<dynamic, dynamic>.from({'a': 1});
      expect(request.copyWith(body: decoded).body, {'a': 1});
    });

    test('a body that is not a map is reported as a bad argument', () {
      expect(
        () => request.copyWith(body: 'not a map'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('interceptors are appended to the existing chain, not replaced', () {
      final base = request.copyWith(
        interceptors: [HeaderInterceptor(const {})],
      );
      final extended = base.copyWith(
        interceptors: [
          HeaderInterceptor(const {'a': 'b'}),
        ],
      );
      expect(extended.interceptors, hasLength(2));
    });
  });
}

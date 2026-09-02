import 'dart:async';

import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  ApiRequest<Map<String, dynamic>, Map<String, dynamic>> request() =>
      ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
        baseUrl: 'https://example.com',
        path: 'things',
      );

  test('a cancelled call completes as cancelled, not as an error', () async {
    final token = CancellationToken();
    final client = MockClient((_) async {
      // Never resolves on its own; the token must end the wait.
      await Completer<void>().future;
      return http.Response('{}', 200);
    });

    final future = RemoteRepository(
      HttpApiProvider(client: client),
    ).handleRequest(request(), options: RequestOptions(cancelToken: token));

    token.cancel('user navigated away');
    final response = await future;

    expect(response.isCancelled, isTrue);
    expect(response.statusCode, ApiResponse.cancelled);
    expect(response.isSuccessful, isFalse);
    expect(response.cause, isA<RequestCancelledException>());
    expect((response.error as ApiError).message, 'user navigated away');
  });

  test('cancelling before the call starts short-circuits it', () async {
    var hit = false;
    final token = CancellationToken()..cancel();
    final client = MockClient((_) async {
      hit = true;
      return http.Response('{}', 200);
    });

    final response = await RemoteRepository(
      HttpApiProvider(client: client),
    ).handleRequest(request(), options: RequestOptions(cancelToken: token));

    expect(response.isCancelled, isTrue);
    expect(hit, isFalse, reason: 'no request should reach the transport');
  });

  test('a token reports its state and is idempotent', () {
    final token = CancellationToken();
    expect(token.isCancelled, isFalse);

    token.cancel('first');
    token.cancel('second');

    expect(token.isCancelled, isTrue);
    expect(token.cause?.reason, 'first');
    expect(
      () => token.throwIfCancelled(),
      throwsA(isA<RequestCancelledException>()),
    );
  });

  test('an uncancelled call is unaffected', () async {
    final client = MockClient((_) async => http.Response('{}', 200));
    final response = await RemoteRepository(HttpApiProvider(client: client))
        .handleRequest(
          request(),
          options: RequestOptions(cancelToken: CancellationToken()),
        );

    expect(response.statusCode, 200);
    expect(response.isCancelled, isFalse);
  });
}

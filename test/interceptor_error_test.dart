import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// An exception type the package knows nothing about.
class SessionExpiredException implements Exception {
  final String refreshToken;
  SessionExpiredException(this.refreshToken);
}

class ThrowingRequestInterceptor extends ApiInterceptor {
  final Object error;
  ThrowingRequestInterceptor(this.error);

  @override
  ApiRequest<R, I> onRequest<R, I>(ApiRequest<R, I> request) => throw error;
}

class ThrowingResponseInterceptor extends ApiInterceptor {
  @override
  ApiResponse<R, I> onResponse<R, I>(ApiResponse<R, I> response) =>
      throw StateError('decode blew up');
}

class RecordingInterceptor extends ApiInterceptor {
  bool sawError = false;

  @override
  ApiResponse<R, I> onError<R, I>(ApiResponse<R, I> response) {
    sawError = true;
    return response;
  }
}

void main() {
  late RemoteRepository remote;

  ApiRequest<Map<String, dynamic>, Map<String, dynamic>> requestWith(
    List<ApiInterceptor> interceptors,
  ) => ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
    baseUrl: 'https://example.com',
    path: 'things',
    interceptors: interceptors,
  );

  setUp(() {
    // Never actually reached by these tests: the interceptors throw first.
    final client = MockClient((_) async => http.Response('{}', 200));
    remote = RemoteRepository(HttpApiProvider(client: client));
  });

  group('an interceptor throwing during onRequest', () {
    test('preserves an HTTP status carried on the thrown ApiError', () async {
      final response = await remote.handleRequest(
        requestWith([
          ThrowingRequestInterceptor(ApiError('Unauthorized', 401)),
        ]),
      );

      // Regression: this used to be stamped 420 regardless, so callers
      // branching on 401 to refresh a token never fired.
      expect(response.statusCode, 401);
      expect(response.isSuccessful, isFalse);
      expect(response.error, ApiError('Unauthorized', 401));
    });

    test('retains a custom exception instead of flattening it', () async {
      final thrown = SessionExpiredException('refresh-me');
      final response = await remote.handleRequest(
        requestWith([ThrowingRequestInterceptor(thrown)]),
      );

      // The original throwable is recoverable...
      expect(response.cause, same(thrown));
      expect(
        (response.cause as SessionExpiredException).refreshToken,
        'refresh-me',
      );
      // ...alongside the normalised error the rest of the app can render.
      expect(response.error, isA<ApiError>());
      expect(response.stackTrace, isNotNull);
    });

    test(
      'falls back to a transport marker when the code is not an HTTP status',
      () async {
        final response = await remote.handleRequest(
          requestWith([ThrowingRequestInterceptor(ApiError('boom', 7000))]),
        );

        expect(response.statusCode, ApiResponse.transportFailure);
        expect(response.isSuccessful, isFalse);
      },
    );

    test('still runs onError interceptors', () async {
      final recorder = RecordingInterceptor();
      await remote.handleRequest(
        requestWith([
          ThrowingRequestInterceptor(ApiError('nope', 400)),
          recorder,
        ]),
      );

      expect(recorder.sawError, isTrue);
    });
  });

  group('an interceptor throwing during onResponse', () {
    test(
      'surfaces the failure rather than returning a partial response',
      () async {
        final response = await remote.handleRequest(
          requestWith([ThrowingResponseInterceptor()]),
        );

        // Previously a bare `catch {}` swallowed this and handed back a
        // half-resolved response with no signal at all.
        expect(response.error, isNotNull);
        expect(response.cause, isA<StateError>());
        expect(response.stackTrace, isNotNull);
        // The body was never produced, so this must not report success even
        // though the transport returned 200.
        expect(response.isSuccessful, isFalse);
      },
    );
  });
}

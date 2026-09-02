import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class TracingInterceptor extends ApiInterceptor {
  final String name;
  final List<String> trace;
  TracingInterceptor(this.name, this.trace);

  @override
  ApiRequest<R, I> onRequest<R, I>(ApiRequest<R, I> request) {
    trace.add('$name.onRequest');
    return request;
  }

  @override
  ApiResponse<R, I> onResponse<R, I>(ApiResponse<R, I> response) {
    trace.add('$name.onResponse');
    return response;
  }

  @override
  ApiResponse<R, I> onError<R, I>(ApiResponse<R, I> response) {
    trace.add('$name.onError');
    return response;
  }
}

void main() {
  late List<String> trace;

  Future<ApiResponse<Map<String, dynamic>, Map<String, dynamic>>> send(
    int status,
  ) {
    final client = MockClient((_) async => http.Response('{}', status));
    return RemoteRepository(HttpApiProvider(client: client)).handleRequest(
      ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
        baseUrl: 'https://example.com',
        path: 'things',
        interceptors: [
          TracingInterceptor('first', trace),
          TracingInterceptor('second', trace),
        ],
      ),
    );
  }

  setUp(() => trace = []);

  test('onRequest then onResponse, each in declaration order', () async {
    await send(200);
    expect(trace, [
      'first.onRequest',
      'second.onRequest',
      'first.onResponse',
      'second.onResponse',
    ]);
  });

  test(
    'an unsuccessful status routes through onError, not onResponse',
    () async {
      await send(500);
      expect(trace, [
        'first.onRequest',
        'second.onRequest',
        'first.onError',
        'second.onError',
      ]);
    },
  );

  test(
    'HeaderInterceptor merges defaults without dropping request headers',
    () async {
      late Map<String, String> sent;
      final client = MockClient((request) async {
        sent = request.headers;
        return http.Response('{}', 200);
      });

      await RemoteRepository(HttpApiProvider(client: client)).handleRequest(
        ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
          baseUrl: 'https://example.com',
          path: 'things',
          headers: const {'Accept': 'application/json'},
          interceptors: [
            HeaderInterceptor(const {'Authorization': 'Bearer t'}),
          ],
        ),
      );

      expect(sent['Authorization'], 'Bearer t');
      expect(sent['Accept'], 'application/json');
    },
  );
}

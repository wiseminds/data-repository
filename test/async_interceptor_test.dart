import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The flow this whole feature exists for: an expired token is refreshed
/// asynchronously in onError, and the retried attempt picks up the new one.
class RefreshingAuthInterceptor extends ApiInterceptor {
  final Future<String> Function() refresh;
  String token;
  int refreshes = 0;

  RefreshingAuthInterceptor(this.token, this.refresh);

  @override
  Future<ApiRequest<R, I>> onRequest<R, I>(ApiRequest<R, I> request) async {
    return request.copyWith(headers: {'Authorization': 'Bearer $token'});
  }

  @override
  Future<ApiResponse<R, I>> onError<R, I>(ApiResponse<R, I> response) async {
    if (response.statusCode != 401) return response;
    refreshes++;
    token = await refresh();
    return response;
  }
}

void main() {
  test('a sync interceptor still satisfies the FutureOr signature', () async {
    final client = MockClient((_) async => http.Response('{}', 200));
    final response = await RemoteRepository(HttpApiProvider(client: client))
        .handleRequest(
          ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
            baseUrl: 'https://example.com',
            path: 'things',
            interceptors: [
              HeaderInterceptor(const {'Accept': 'application/json'}),
            ],
          ),
        );

    expect(response.statusCode, 200);
  });

  test('onRequest can await before the request goes out', () async {
    late String sentAuth;
    final client = MockClient((request) async {
      sentAuth = request.headers['Authorization'] ?? '';
      return http.Response('{}', 200);
    });

    final auth = RefreshingAuthInterceptor('initial', () async => 'unused');

    await RemoteRepository(HttpApiProvider(client: client)).handleRequest(
      ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
        baseUrl: 'https://example.com',
        path: 'things',
        interceptors: [auth],
      ),
    );

    expect(sentAuth, 'Bearer initial');
  });

  test('401 refreshes the token and the retry replays with it', () async {
    final sent = <String>[];
    final client = MockClient((request) async {
      sent.add(request.headers['Authorization'] ?? '');
      // Reject the stale token once, then accept the refreshed one.
      return sent.length == 1
          ? http.Response('{"message":"expired"}', 401)
          : http.Response('{}', 200);
    });

    final auth = RefreshingAuthInterceptor('stale', () async {
      await Future.delayed(const Duration(milliseconds: 1));
      return 'fresh';
    });

    final response = await RemoteRepository(HttpApiProvider(client: client))
        .handleRequest(
          ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
            baseUrl: 'https://example.com',
            path: 'things',
            interceptors: [auth],
          ),
          options: const RequestOptions(
            retry: RetryPolicy(
              maxAttempts: 2,
              initialDelay: Duration(milliseconds: 1),
              jitter: 0,
              retryIf: _retryUnauthorized,
            ),
          ),
        );

    expect(auth.refreshes, 1);
    expect(sent, ['Bearer stale', 'Bearer fresh']);
    expect(response.statusCode, 200);
  });
}

bool _retryUnauthorized(ApiResponse response, int attempt) =>
    response.statusCode == 401;

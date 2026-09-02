import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late int calls;

  /// Fast policy so tests do not actually wait out a backoff.
  const fast = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 1),
    jitter: 0,
  );

  RemoteRepository repoReturning(List<int> statuses) {
    calls = 0;
    final client = MockClient((_) async {
      final status = statuses[calls.clamp(0, statuses.length - 1)];
      calls++;
      return http.Response('{}', status);
    });
    return RemoteRepository(HttpApiProvider(client: client));
  }

  ApiRequest<Map<String, dynamic>, Map<String, dynamic>> get1() =>
      ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
        baseUrl: 'https://example.com',
        path: 'things',
      );

  test('retries a 500 and returns the eventual success', () async {
    final repo = repoReturning([500, 500, 200]);
    final response = await repo.handleRequest(
      get1(),
      options: const RequestOptions(retry: fast),
    );

    expect(calls, 3);
    expect(response.statusCode, 200);
  });

  test('gives up after maxAttempts and returns the last failure', () async {
    final repo = repoReturning([503]);
    final response = await repo.handleRequest(
      get1(),
      options: const RequestOptions(retry: fast),
    );

    expect(calls, 3);
    expect(response.statusCode, 503);
  });

  test('does not retry a 4xx', () async {
    final repo = repoReturning([404]);
    await repo.handleRequest(
      get1(),
      options: const RequestOptions(retry: fast),
    );

    expect(calls, 1);
  });

  test('does not retry a non-idempotent method by default', () async {
    final repo = repoReturning([500]);
    final post = ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
      baseUrl: 'https://example.com',
      path: 'things',
      method: ApiMethods.post,
    );

    await repo.handleRequest(post, options: const RequestOptions(retry: fast));
    expect(calls, 1, reason: 'replaying a POST can duplicate work');
  });

  test('a custom predicate can opt a POST in', () async {
    final repo = repoReturning([500, 200]);
    final post = ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
      baseUrl: 'https://example.com',
      path: 'things',
      method: ApiMethods.post,
    );

    await repo.handleRequest(
      post,
      options: RequestOptions(
        retry: RetryPolicy(
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 1),
          jitter: 0,
          retryIf: (response, _) => response.statusCode >= 500,
        ),
      ),
    );

    expect(calls, 2);
  });

  test('no retrying happens by default', () async {
    final repo = repoReturning([500]);
    await repo.handleRequest(get1());
    expect(calls, 1);
  });

  test('backoff grows and is capped', () {
    const policy = RetryPolicy(
      initialDelay: Duration(milliseconds: 100),
      backoffFactor: 2,
      maxDelay: Duration(milliseconds: 250),
      jitter: 0,
    );

    expect(policy.delayFor(1).inMilliseconds, 100);
    expect(policy.delayFor(2).inMilliseconds, 200);
    expect(policy.delayFor(3).inMilliseconds, 250, reason: 'capped');
  });
}

import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'dependencies/body_interceptor.dart';

class _Repo extends DataRepository {
  _Repo(super.local, super.remote);
}

void main() {
  late MapRepository local;
  late _Repo repo;
  late int calls;
  String payload = '{"a":1}';

  ApiRequest<Map<String, dynamic>, Map<String, dynamic>> request() =>
      ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
        baseUrl: 'https://example.com',
        path: 'things',
        interceptors: [BodyInterceptor()],
      );

  ApiRequest<List<dynamic>, dynamic> listRequest() =>
      ApiRequest<List<dynamic>, dynamic>(
        baseUrl: 'https://example.com',
        path: 'things',
        interceptors: [BodyInterceptor()],
      );

  setUp(() {
    calls = 0;
    payload = '{"a":1}';
    local = MapRepository();
    final client = MockClient((_) async {
      calls++;
      return http.Response(payload, 200);
    });
    repo = _Repo(local, RemoteRepository(HttpApiProvider(client: client)));
  });

  test('a second request within the lifespan is served from cache', () async {
    final cache = CacheDescription(
      'things',
      lifeSpan: CacheDescription.oneMinute,
    );

    final first = await repo.handleRequest(request(), cache: cache);
    expect(first.statusCode, 200);
    expect(calls, 1);

    final second = await repo.handleRequest(request(), cache: cache);
    expect(second.statusCode, ApiResponse.cacheHit);
    expect(second.body, {'a': 1});
    expect(calls, 1, reason: 'the network should not be hit again');
  });

  test('an expired entry falls through to the network', () async {
    final cache = CacheDescription(
      'things',
      lifeSpan: CacheDescription.oneMinute,
    );
    await repo.handleRequest(request(), cache: cache);

    // Expire the entry rather than waiting for it.
    local.saveTime(
      'things',
      DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
    );

    final response = await repo.handleRequest(request(), cache: cache);
    expect(response.statusCode, 200);
    expect(calls, 2);
  });

  test('invalidateCache bypasses a live entry', () async {
    final cache = CacheDescription(
      'things',
      lifeSpan: CacheDescription.oneMinute,
    );
    await repo.handleRequest(request(), cache: cache);

    await repo.handleRequest(
      request(),
      cache: cache.copyWith(invalidateCache: true),
    );
    expect(calls, 2);
  });

  test('ignoreSave keeps the response out of the cache', () async {
    final cache = CacheDescription(
      'things',
      lifeSpan: CacheDescription.oneMinute,
      ignoreSave: true,
    );

    await repo.handleRequest(request(), cache: cache);
    expect(local.cacheBox.containsKey('things'), isFalse);
  });

  test('an empty collection is not cached', () async {
    // Regression: the guard read `ResultType is Iterable<Item>`, comparing a
    // type argument against a type, which is always false.
    payload = '[]';
    final cache = CacheDescription(
      'empty',
      lifeSpan: CacheDescription.oneMinute,
    );

    await repo.handleRequest(listRequest(), cache: cache);
    expect(local.cacheBox.containsKey('empty'), isFalse);
  });

  test('a non-empty collection is cached', () async {
    payload = '[1,2]';
    final cache = CacheDescription(
      'full',
      lifeSpan: CacheDescription.oneMinute,
    );

    await repo.handleRequest(listRequest(), cache: cache);
    expect(local.cacheBox.containsKey('full'), isTrue);
  });

  test('an unserialisable body is not cached', () async {
    // JsonUtils throws rather than writing the string "null", which a later
    // read would have to discard anyway.
    expect(
      () => JsonUtils.convertToJson(Object()),
      throwsA(isA<JsonSerializationException>()),
    );
  });
}

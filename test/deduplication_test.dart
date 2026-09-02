import 'dart:async';

import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late int calls;
  late Completer<void> gate;

  RemoteRepository build({bool deduplicate = true}) {
    calls = 0;
    gate = Completer<void>();
    final client = MockClient((_) async {
      calls++;
      await gate.future; // hold both callers in flight together
      return http.Response('{"v":1}', 200);
    });
    return RemoteRepository(
      HttpApiProvider(client: client),
      null,
      RetryPolicy.none,
      deduplicate,
    );
  }

  ApiRequest<Map<String, dynamic>, Map<String, dynamic>> get1([
    String path = 'things',
  ]) => ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
    baseUrl: 'https://example.com',
    path: path,
  );

  test('two identical in-flight GETs share one network call', () async {
    final repo = build();
    final a = repo.handleRequest(get1());
    final b = repo.handleRequest(get1());

    gate.complete();
    final results = await Future.wait([a, b]);

    expect(calls, 1);
    expect(results[0].statusCode, 200);
    expect(results[1].statusCode, 200);
  });

  test('different paths are not shared', () async {
    final repo = build();
    final a = repo.handleRequest(get1('things'));
    final b = repo.handleRequest(get1('others'));

    gate.complete();
    await Future.wait([a, b]);

    expect(calls, 2);
  });

  test('the entry is released so a later call hits the network', () async {
    final repo = build();
    final first = repo.handleRequest(get1());
    gate.complete();
    await first;

    gate = Completer<void>()..complete();
    await repo.handleRequest(get1());

    expect(calls, 2);
  });

  test('skipDeduplication forces a fresh call', () async {
    final repo = build();
    final a = repo.handleRequest(get1());
    final b = repo.handleRequest(
      get1(),
      options: const RequestOptions(skipDeduplication: true),
    );

    gate.complete();
    await Future.wait([a, b]);

    expect(calls, 2);
  });

  test('POSTs are never shared', () async {
    final repo = build();
    final post = ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
      baseUrl: 'https://example.com',
      path: 'things',
      method: ApiMethods.post,
    );

    final a = repo.handleRequest(post);
    final b = repo.handleRequest(post);
    gate.complete();
    await Future.wait([a, b]);

    expect(calls, 2);
  });

  test('deduplication can be turned off', () async {
    final repo = build(deduplicate: false);
    final a = repo.handleRequest(get1());
    final b = repo.handleRequest(get1());

    gate.complete();
    await Future.wait([a, b]);

    expect(calls, 2);
  });
}

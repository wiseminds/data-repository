import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<String> logs;

  setUp(() {
    logs = [];
    ApiConfig().logger = logs.add;
  });

  tearDown(() => ApiConfig().logger = null);

  Future<void> call({int status = 200}) async {
    final client = MockClient(
      (_) async => http.Response('{"ok":true}', status),
    );
    await RemoteRepository(HttpApiProvider(client: client)).handleRequest(
      ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
        baseUrl: 'https://example.com',
        path: 'things',
        headers: const {'Authorization': 'Bearer secret-token'},
        interceptors: [LoggingInterceptor()],
      ),
    );
  }

  test('logs the request and the outcome with a duration', () async {
    await call();

    expect(logs.any((l) => l.startsWith('--> GET')), isTrue);
    expect(logs.any((l) => l.contains('<-- 200')), isTrue);
    expect(logs.any((l) => RegExp(r'\(\d+ms\)').hasMatch(l)), isTrue);
  });

  test('redacts sensitive headers', () async {
    await call();

    expect(
      logs.any((l) => l.contains('secret-token')),
      isFalse,
      reason: 'the token must never reach the log',
    );
    expect(logs.any((l) => l.contains('***')), isTrue);
  });

  test('a failure is logged through onError', () async {
    await call(status: 500);
    expect(logs.any((l) => l.contains('<-- 500')), isTrue);
  });

  test('nothing is emitted when no logger is configured', () async {
    ApiConfig().logger = null;
    await call();
    expect(logs, isEmpty);
  });

  test('long bodies are truncated', () {
    final interceptor = LoggingInterceptor(maxBodyLength: 10);
    final request = ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
      baseUrl: 'https://example.com',
      path: 'x',
      body: {'value': 'a' * 500},
    );

    interceptor.onRequest(request);
    expect(logs.any((l) => l.contains('chars)')), isTrue);
  });
}

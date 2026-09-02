import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('download progress is reported against Content-Length', () async {
    const payload = '0123456789';
    final client = MockClient(
      (_) async => http.Response(
        payload,
        200,
        headers: {'content-length': '${payload.length}'},
      ),
    );

    final seen = <List<int>>[];
    final response = await RemoteRepository(HttpApiProvider(client: client))
        .handleRequest(
          ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
            baseUrl: 'https://example.com',
            path: 'file',
          ),
          options: RequestOptions(
            onReceiveProgress: (received, total) => seen.add([received, total]),
          ),
        );

    expect(response.statusCode, 200);
    expect(response.bodyString, payload);
    expect(seen, isNotEmpty);
    expect(seen.last[0], payload.length, reason: 'ends at the full length');
    expect(seen.last[1], payload.length);
  });

  test('upload progress is reported while a multipart body is sent', () async {
    final client = MockClient((_) async => http.Response('{}', 200));

    final seen = <List<int>>[];
    await RemoteRepository(HttpApiProvider(client: client)).handleRequest(
      ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
        baseUrl: 'https://example.com',
        path: 'upload',
        method: ApiMethods.post,
        isMultipart: true,
        body: {
          'file': FileFormField(
            bytes: List<int>.filled(2048, 7),
            path: 'blob.bin',
          ),
        },
      ),
      options: RequestOptions(
        onSendProgress: (sent, total) => seen.add([sent, total]),
      ),
    );

    expect(seen, isNotEmpty);
    expect(seen.last[0], greaterThan(2000));
    expect(
      seen.last[0],
      equals(seen.last[1]),
      reason: 'the final callback reports the whole body sent',
    );
  });

  test('a request without progress callbacks still works', () async {
    final client = MockClient((_) async => http.Response('hello', 200));
    final response = await RemoteRepository(HttpApiProvider(client: client))
        .handleRequest(
          ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
            baseUrl: 'https://example.com',
            path: 'file',
          ),
        );

    expect(response.bodyString, 'hello');
  });
}

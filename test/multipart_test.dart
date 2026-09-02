import 'dart:io';

import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory tempDir;
  late File imageFile;
  late File unknownFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('multipart_test');
    imageFile = File('${tempDir.path}/avatar.png')..writeAsBytesSync([1, 2, 3]);
    unknownFile = File('${tempDir.path}/blob.zzzz')
      ..writeAsStringSync('opaque');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  /// Sends a multipart request and returns the raw encoded body.
  Future<String> sendMultipart(Map<String, dynamic> body) async {
    late String captured;
    final client = MockClient((request) async {
      captured = request.body;
      return http.Response('{}', 200);
    });

    final request = ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
      baseUrl: 'https://example.com',
      path: 'upload',
      method: ApiMethods.post,
      isMultipart: true,
      body: body,
    );

    await RemoteRepository(
      HttpApiProvider(client: client),
    ).handleRequest(request);
    return captured;
  }

  test('every file part is attached before the request is sent', () async {
    // Regression: file parts were added from an async callback passed to
    // Map.forEach, which discards the futures — a part read from disk could
    // resolve after send() and be dropped entirely.
    final body = await sendMultipart({
      'fromPath': FileFormField(path: imageFile.path),
      'fromBytes': FileFormField(bytes: [4, 5, 6], path: 'raw.png'),
      'fromString': FileFormField(stringFile: 'hello', path: 'note.txt'),
      'plainField': 'a value',
    });

    expect(body, contains('name="fromPath"'));
    expect(body, contains('name="fromBytes"'));
    expect(body, contains('name="fromString"'));
    expect(body, contains('name="plainField"'));
    expect(body, contains('a value'));
  });

  test('an unknown extension falls back to application/octet-stream', () async {
    // Regression: MediaType.parse('') threw a FormatException and failed the
    // whole upload whenever lookupMimeType returned null.
    final body = await sendMultipart({
      'file': FileFormField(path: unknownFile.path),
    });

    expect(body, contains('application/octet-stream'));
  });

  test('a known extension keeps its detected content type', () async {
    final body = await sendMultipart({
      'file': FileFormField(path: imageFile.path),
    });

    expect(body, contains('image/png'));
  });
}

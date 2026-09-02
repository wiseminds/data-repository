import "dart:async";
import 'dart:convert';

import 'package:data_repository/remote/api_methods.dart';
import 'package:data_repository/remote/api_request.dart';
import 'package:data_repository/remote/api_response.dart';
import 'package:data_repository/remote/cancellation_token.dart';
import 'package:data_repository/remote/file_field.dart';
import 'package:data_repository/remote/request_options.dart';
import 'package:data_repository/utils/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../api_provider.dart';

/// Content type used when a file's type cannot be inferred from its path.
final _fallbackMediaType = MediaType('application', 'octet-stream');

class HttpApiProvider extends ApiProvider {
  final http.Client _client;
  final bool _ownsClient;

  /// Pass a [client] to reuse connections across requests, or to substitute a
  /// `MockClient` from `package:http/testing.dart` in tests. When omitted a
  /// private client is created and owned by this provider.
  HttpApiProvider({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  /// Releases the underlying client, unless one was injected.
  @override
  void close() {
    if (_ownsClient) _client.close();
  }

  @override
  Future<ApiResponse<ResultType, InnerType>> send<ResultType, InnerType>(
    ApiRequest<ResultType, InnerType> request, [
    RequestOptions options = const RequestOptions(),
  ]) async {
    try {
      options.cancelToken?.throwIfCancelled();

      // Inside the try: building runs the onRequest interceptors, and an
      // interceptor that throws must take the same handled path as a
      // transport failure rather than escaping this provider.
      request = await request.build;

      final http.BaseRequest baseRequest = request.isMultipart
          ? await _buildMultipart(request, options)
          : _buildPlain(request);

      final seconds = options.timeout ?? request.timeout;
      final streamed = await _race(
        _client
            .send(baseRequest)
            .timeout(
              Duration(seconds: seconds),
              onTimeout: () => throw TimeoutException('Connection timed out'),
            ),
        options.cancelToken,
      );

      final body = await _race(
        _readBody(streamed, options.onReceiveProgress),
        options.cancelToken,
      );

      return await ApiResponse<ResultType, InnerType>(
        request: request,
        bodyString: body,
        headers: streamed.headers,
        statusCode: streamed.statusCode,
      ).resolve;
    } catch (e, stackTrace) {
      ApiConfig().log(
        '${request.method} ${request.uri} failed: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Completes with whichever finishes first: the work, or cancellation.
  Future<T> _race<T>(Future<T> work, CancellationToken? token) {
    if (token == null) return work;
    return Future.any<T>([
      work,
      token.whenCancelled.then((cause) => throw cause),
    ]);
  }

  http.Request _buildPlain(ApiRequest request) {
    final req = http.Request(request.method ?? ApiMethods.get, request.uri)
      ..headers.addAll(request.headers);
    // Send no body at all when there is none, rather than the literal "null".
    if (request.body != null) req.body = jsonEncode(request.body);
    return req;
  }

  Future<http.BaseRequest> _buildMultipart(
    ApiRequest request,
    RequestOptions options,
  ) async {
    final req = http.MultipartRequest(
      request.method ?? ApiMethods.post,
      request.uri,
    );

    // A sequential loop, not Map.forEach with an async callback: forEach
    // discards the returned futures, so file parts read from disk could
    // resolve after the request was sent and be dropped.
    for (final entry in (request.body ?? const {}).entries) {
      final value = entry.value;
      if (value is! FileFormField) {
        req.fields[entry.key] = value.toString();
        continue;
      }

      if (value.bytes != null) {
        req.files.add(
          http.MultipartFile.fromBytes(
            entry.key,
            value.bytes!,
            filename: value.path,
            contentType: _mediaTypeFor(value.path),
          ),
        );
      } else if (value.stringFile != null) {
        req.files.add(
          http.MultipartFile.fromString(
            entry.key,
            value.stringFile!,
            filename: value.path,
            contentType: _mediaTypeFor(value.path),
          ),
        );
      } else {
        req.files.add(
          await http.MultipartFile.fromPath(
            entry.key,
            value.path ?? '',
            contentType: _mediaTypeFor(value.path),
          ),
        );
      }
    }

    req.headers.addAll(request.headers);
    if (options.onSendProgress == null) return req;
    return _ProgressRequest(req, options.onSendProgress!);
  }

  /// Reads the response body, reporting progress against Content-Length.
  Future<String> _readBody(
    http.StreamedResponse response,
    ProgressCallback? onProgress,
  ) async {
    if (onProgress == null) return response.stream.bytesToString();

    final total = response.contentLength ?? -1;
    var received = 0;
    final chunks = <List<int>>[];
    await for (final chunk in response.stream) {
      chunks.add(chunk);
      received += chunk.length;
      onProgress(received, total);
    }
    return utf8.decode(chunks.expand((c) => c).toList(), allowMalformed: true);
  }

  /// Resolves a part's content type, falling back to
  /// `application/octet-stream` — `MediaType.parse('')` throws, so an
  /// unrecognised extension used to crash the whole upload.
  MediaType _mediaTypeFor(String? path) {
    final mime = path == null ? null : lookupMimeType(path);
    if (mime == null) return _fallbackMediaType;
    try {
      return MediaType.parse(mime);
    } on FormatException {
      return _fallbackMediaType;
    }
  }
}

/// Wraps a request so its outgoing bytes are counted as they are sent.
class _ProgressRequest extends http.BaseRequest {
  final http.BaseRequest _inner;
  final ProgressCallback _onProgress;

  _ProgressRequest(this._inner, this._onProgress)
    : super(_inner.method, _inner.url) {
    headers.addAll(_inner.headers);
    followRedirects = _inner.followRedirects;
    maxRedirects = _inner.maxRedirects;
    persistentConnection = _inner.persistentConnection;
  }

  @override
  int? get contentLength => _inner.contentLength;

  @override
  http.ByteStream finalize() {
    super.finalize();
    final total = _inner.contentLength ?? -1;
    var sent = 0;
    final source = _inner.finalize();
    return http.ByteStream(
      source.map((chunk) {
        sent += chunk.length;
        _onProgress(sent, total);
        return chunk;
      }),
    );
  }
}

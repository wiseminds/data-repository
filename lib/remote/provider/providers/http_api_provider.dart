import "dart:async";
import 'dart:convert';

import 'package:data_repository/remote/api_methods.dart';
import 'package:data_repository/remote/api_request.dart';
import 'package:data_repository/remote/api_response.dart';
import 'package:data_repository/utils/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../file_field.dart';
import '../api_provider.dart';

/// Content type used when a file's type cannot be inferred from its path.
final _fallbackMediaType = MediaType('application', 'octet-stream');

class HttpApiProvider extends ApiProvider {
  final http.Client _client;

  /// Pass a [client] to reuse connections across requests, or to substitute a
  /// `MockClient` from `package:http/testing.dart` in tests. When omitted a
  /// private client is created and owned by this provider.
  HttpApiProvider({http.Client? client}) : _client = client ?? http.Client();

  /// Releases the underlying client. Only call this if the provider owns it.
  void close() => _client.close();

  @override
  Future<ApiResponse<ResultType, InnerType>> send<ResultType, InnerType>(
    ApiRequest<ResultType, InnerType> request,
  ) async {
    try {
      // Inside the try: building runs the onRequest interceptors, and an
      // interceptor that throws must take the same handled path as a
      // transport failure rather than escaping this provider.
      request = request.build;

      if (request.isMultipart) {
        final res = await _sendMultipart(request);
        return ApiResponse<ResultType, InnerType>(
          request: request,
          bodyString: await res.stream.bytesToString(),
          headers: res.headers,
          statusCode: res.statusCode,
        ).resolve;
      }

      final response = await runRequest(request).timeout(
        Duration(seconds: request.timeout),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );

      return ApiResponse<ResultType, InnerType>(
        request: request,
        bodyString: response.body,
        headers: response.headers,
        statusCode: response.statusCode,
      ).resolve;
    } catch (e, stackTrace) {
      ApiConfig().log(
        '${request.method} ${request.uri} failed: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<http.Response> runRequest(ApiRequest request) {
    final uri = request.uri;
    final headers = request.headers;
    // Send no body at all when there is none, rather than the literal "null".
    final body = request.body == null ? null : jsonEncode(request.body);

    switch (request.method) {
      case ApiMethods.delete:
        return _client.delete(uri, headers: headers, body: body);
      case ApiMethods.patch:
        return _client.patch(uri, headers: headers, body: body);
      case ApiMethods.head:
        return _client.head(uri, headers: headers);
      case ApiMethods.post:
        return _client.post(uri, headers: headers, body: body);
      case ApiMethods.put:
        return _client.put(uri, headers: headers, body: body);
      default:
        return _client.get(uri, headers: headers);
    }
  }

  Future<http.StreamedResponse> _sendMultipart(ApiRequest request) async {
    final req = http.MultipartRequest(
      request.method ?? ApiMethods.get,
      request.uri,
    );

    // A sequential loop, not Map.forEach with an async callback: forEach
    // discards the returned futures, so file parts read from disk could
    // resolve after send() had already been called and be dropped.
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
    return _client.send(req);
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

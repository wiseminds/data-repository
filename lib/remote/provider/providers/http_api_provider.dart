import "dart:async";
import 'dart:convert';

import 'package:data_repository/models/api_error.dart';
import 'package:data_repository/remote/api_methods.dart';
import 'package:data_repository/remote/api_request.dart';
import 'package:data_repository/remote/api_response.dart';
import 'package:data_repository/utils/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../file_field.dart';
import '../api_provider.dart';

class HttpApiProvider extends ApiProvider {
  @override
  Future<ApiResponse<ResultType, InnerType>> send<ResultType, InnerType>(
      ApiRequest<ResultType, InnerType> request) async {
    request = request.build;

    http.Response response;
    // print('handling request ${request.baseUrl}');
    try {
      if (request.isMultipart) {
        var res = await handleMultipart(request);
        return ApiResponse<ResultType, InnerType>(
                request: request,
                bodyString: await res.stream.bytesToString(),
                headers: res.headers,
                statusCode: res.statusCode)
            .resolve;
      }
      response = await runRequest(request)
          .timeout(Duration(seconds: request.timeout), onTimeout: () {
        throw (TimeoutException('Connection timed out'));
      });
    } catch (e) {
      if (kDebugMode) print(' error in request ');
      if (kDebugMode) print(e.toString());
      return ApiResponse<ResultType, InnerType>(
              request: request,
              headers: {},
              statusCode: 400,
              error: (e is ApiError)
                  ? e
                  : formatErrorMessage(e, ApiConfig().defaultErrorMessage))
          .resolve;
    }

    // print(response?.bodyBytes);

    return ApiResponse<ResultType, InnerType>(
            request: request,
            bodyString: response.body,
            headers: response.headers,
            statusCode: response.statusCode)
        .resolve;
  }

  Future<http.Response> runRequest(ApiRequest request) {
    var uri = _buildUri(request);
    // print('rrrrrrrrrrrr $uri');
    switch (request.method) {
      case ApiMethods.delete:
        return http.delete(uri,
            headers: request.headers, body: jsonEncode(request.body));
      case ApiMethods.patch:
        return http.patch(uri,
            headers: request.headers, body: jsonEncode(request.body));
      case ApiMethods.head:
        return http.head(uri, headers: request.headers);
      case ApiMethods.post:
        return http.post(uri,
            headers: request.headers, body: jsonEncode(request.body));
      case ApiMethods.put:
        return http.put(uri,
            headers: request.headers, body: jsonEncode(request.body));
      default:
        return http.get(uri, headers: request.headers);
    }
  }

  Uri _buildUri(ApiRequest request) {
    // var url = '${request.baseUrl}/${request.path}';
    // var uri = Uri.parse(url);
    return request.uri;
  }

  Future<http.StreamedResponse> handleMultipart(ApiRequest request) {
    var uri = _buildUri(request);
    http.MultipartRequest req = http.MultipartRequest(
      request.method ?? ApiMethods.get,
      uri,
    );

    request.body?.forEach((key, value) async {
      if (value is FileFormField) {
        if (value.bytes != null) {
          req.files.add(http.MultipartFile.fromBytes(key, value.bytes!,
              filename: value.path));
        } else if (value.stringFile != null) {
          req.files.add(http.MultipartFile.fromString(key, value.stringFile!,
              filename: value.path));
        } else {
          req.files.add(await http.MultipartFile.fromPath(key, value.path ?? '',
              // filename: value.path?.split('/').last ?? '',
              contentType:
                  MediaType.parse(lookupMimeType(value.path ?? '') ?? '')));
        }
      } else {
        req.fields[key] = value.toString();
      }
    });
    request.headers.forEach((key, value) {
      req.headers[key] = value;
    });
    return req.send();
  }
}

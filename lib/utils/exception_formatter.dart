import 'dart:async';
import 'dart:io';

import 'package:data_repository/models/api_error.dart';
import 'package:flutter/painting.dart' show NetworkImageLoadException;
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:http/http.dart';

import 'api_config.dart';

/// Error codes reported by [ExceptionFormatter.formatErrorMessage].
class ErrorCodes {
  const ErrorCodes._();

  static const int network = 7000;
  static const int format = 7001;
  static const int missingPlugin = 7002;
  static const int imageLoad = 7003;
  static const int handshake = 7004;
  static const int certificate = 7005;
  static const int fileSystem = 7006;
  static const int tls = 7007;
  static const int timeout = 7009;
  static const int client = 7012;
  static const int unknown = 7011;
}

mixin ExceptionFormatter {
  @Deprecated('Use ErrorCodes.network')
  static const networkError = ErrorCodes.network;

  @Deprecated('Use ErrorCodes.format')
  static const formatError = ErrorCodes.format;

  /// Normalises an arbitrary throwable into an [ApiError].
  ///
  /// Matching is done with `is` checks rather than on
  /// `runtimeType.toString()`: the latter silently stops matching under
  /// release obfuscation (`--obfuscate`) and never matches subclasses.
  ///
  /// An [error] that is already an [ApiError] is returned unchanged, so a
  /// custom error thrown by an interceptor keeps its own message and code.
  ApiError formatErrorMessage(dynamic error, String defaultErrorMessage) {
    if (error is ApiError) return error;

    final String message;
    final int code;

    if (error is SocketException ||
        error is HttpException ||
        error is RedirectException ||
        error is WebSocketException) {
      message = 'Please check your internet connection and try again';
      code = ErrorCodes.network;
    } else if (error is HandshakeException) {
      message = 'Could not establish secure connection with the server';
      code = ErrorCodes.handshake;
    } else if (error is CertificateException) {
      message = 'An error occurred, could not verify server certificate';
      code = ErrorCodes.certificate;
    } else if (error is FileSystemException) {
      message = 'A filesystem exception has occurred';
      code = ErrorCodes.fileSystem;
    } else if (error is TlsException) {
      message = 'SSL error occurred ${error.message}';
      code = ErrorCodes.tls;
    } else if (error is ClientException) {
      message = 'Client exception occurred, could not connect to the server';
      code = ErrorCodes.client;
    } else if (error is TimeoutException) {
      message = 'Connection Timed out please check your internet connection';
      code = ErrorCodes.timeout;
    } else if (error is FormatException) {
      message = 'Improperly formatted value';
      code = ErrorCodes.format;
    } else if (error is MissingPluginException) {
      message = 'Plugin not found';
      code = ErrorCodes.missingPlugin;
    } else if (error is NetworkImageLoadException) {
      message = 'Could not load the image';
      code = ErrorCodes.imageLoad;
    } else if (error.toString().contains('SocketException')) {
      // Some platforms wrap the socket failure in an opaque type.
      message = 'Please check your internet connection and try again';
      code = ErrorCodes.network;
    } else {
      ApiConfig().log('unmapped error ${error.runtimeType}: $error');
      message = defaultErrorMessage.isNotEmpty
          ? defaultErrorMessage
          : ApiConfig().defaultErrorMessage;
      code = ErrorCodes.unknown;
    }

    return ApiError(message, code);
  }

  /// Sample throwables keyed by type name, used by the package's tests to
  /// exercise every branch of [formatErrorMessage].
  static Map<String, Exception> get errorToObject => {
    'ClientException': ClientException(''),
    'SocketException': const SocketException(''),
    'HttpException': const HttpException(''),
    'RedirectException': const RedirectException('', []),
    'WebSocketException': const WebSocketException(''),
    'FileSystemException': const FileSystemException(''),
    'TlsException': const TlsException(''),
    'TimeoutException': TimeoutException(''),
    'MissingPluginException': MissingPluginException(''),
    'NetworkImageLoadException': NetworkImageLoadException(
      statusCode: 500,
      uri: Uri.https('google.com'),
    ),
    'CertificateException': const CertificateException(''),
  };
}

import 'dart:async';
import 'dart:io';

import 'package:data_repository/models/api_error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExceptionFormater {
  static const networkError = 7000;
  static const formatError = 7000;

  ApiError formatErrorMessage<E>(dynamic error, String defaultErrorMessage) {
    String? message;
    int? code;
    // if (kDebugMode) print(error is ApiError);
    if (kDebugMode) print(error?.runtimeType);
    switch (error.runtimeType) {
      case ApiError:
        message = error.message ?? defaultErrorMessage;
        code = error.code.toInt() ?? 1000;
        break;
      case SocketException:
      case HttpException:
      case RedirectException:
      case WebSocketException:
        message =
            'Could not connect to the server please check your internet connection';
        code = 7000;
        break;
      case FormatException:
        message = 'Improperly formatted value';
        code = 7001;
        break;
      case MissingPluginException:
        message = 'Plugin not found';
        code = 7002;
        break;
      case NetworkImageLoadException:
        message = 'Could not load the image image';
        code = 7003;
        break;
      case HandshakeException:
        message = 'Could not establish secure connection with the server';
        code = 7004;
        break;
      case CertificateException:
        message = 'An error ocurred could not verify server certificate';
        code = 7005;
        break;
      case FileSystemException:
        message = 'A filesystem exception has occurred';
        code = 7006;
        break;
      case TlsException:
        message = 'SSL error occurred ${error?.message ?? ''}';
        code = 7007;
        break;

      case TimeoutException:
        message = 'Connection Timed out please check your internet connection';
        code = 7009;
        break;
      default:
        message = message ?? defaultErrorMessage;
        code = code ?? 7011;
    }
    if (error.toString().contains('SocketException')) {
      message =
          'Could not connect to the server please check your internet connection';
      code = 7000;
    }
    return (error is ApiError) ? error : ApiError(message!, code!);
  }
}

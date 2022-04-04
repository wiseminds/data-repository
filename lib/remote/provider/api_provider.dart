import "dart:async"; 
import 'package:data_repository/remote/api_request.dart';
import 'package:data_repository/remote/api_response.dart';
import 'package:data_repository/utils/exception_formater.dart';
import 'package:flutter/material.dart';

 

/// Api Provider class

abstract class ApiProvider with ExceptionFormater {
  @mustCallSuper
  Future<ApiResponse<ResponseType, InnerType>> send<ResponseType, InnerType>(
      ApiRequest<ResponseType, InnerType> request);
}

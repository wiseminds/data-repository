import 'package:data_repository/models/api_error.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'content.dart';
// import 'errors.dart';

part 'error_model.freezed.dart';
part 'error_model.g.dart';

@freezed
class ErrorModel extends ApiError with _$ErrorModel {
  factory ErrorModel({
    @Default('An error occured') String message,
    @Default(400) int code,
    Map<String, Content>? errors,
  }) = _ErrorModel;

  factory ErrorModel.fromJson(Map<String, dynamic> json) =>
      _$ErrorModelFromJson(json);
}

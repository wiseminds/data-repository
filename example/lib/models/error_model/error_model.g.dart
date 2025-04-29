// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ErrorModel _$ErrorModelFromJson(Map<String, dynamic> json) => _ErrorModel(
      message: json['message'] as String? ?? 'An error occured',
      code: (json['code'] as num?)?.toInt() ?? 400,
      errors: (json['errors'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, Content.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$ErrorModelToJson(_ErrorModel instance) =>
    <String, dynamic>{
      'message': instance.message,
      'code': instance.code,
      'errors': instance.errors,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagination.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_Pagination _$$_PaginationFromJson(Map<String, dynamic> json) =>
    _$_Pagination(
      pages: json['pages'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      order: json['order'] as String?,
      query: json['query'] as String?,
    );

Map<String, dynamic> _$$_PaginationToJson(_$_Pagination instance) =>
    <String, dynamic>{
      'pages': instance.pages,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'order': instance.order,
      'query': instance.query,
    };

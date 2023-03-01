import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:data_repository/data_repository.dart' as d;

part 'pagination.freezed.dart';
part 'pagination.g.dart';

@freezed
class Pagination extends d.Pagination with _$Pagination {
  factory Pagination(
      {@Default(1) int pages,
      @Default(0) int total,
      @Default(1) int page,
      @Default(10) int chunkCount,
      @Default(10) int limit,
      String? order,
      String? query}) = _Pagination;

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
}

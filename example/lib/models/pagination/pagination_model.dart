import 'package:data_repository/data_repository.dart' as d;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_model.freezed.dart';
part 'pagination_model.g.dart';

@freezed
abstract  class PaginationModel with _$PaginationModel implements d.Pagination {
  factory PaginationModel(
      {@Default(1) int pages,
      @Default(0) int total,
      @Default(1) int page,
      @Default(10) int limit,
      String? order,
      String? query}) = _Pagination;

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
}

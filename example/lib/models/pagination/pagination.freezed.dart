// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pagination.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Pagination {
  int get pages;
  int get total;
  int get page;
  int get limit;
  String? get order;
  String? get query;

  /// Create a copy of Pagination
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PaginationCopyWith<Pagination> get copyWith =>
      _$PaginationCopyWithImpl<Pagination>(this as Pagination, _$identity);

  /// Serializes this Pagination to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Pagination &&
            (identical(other.pages, pages) || other.pages == pages) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.query, query) || other.query == query));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, pages, total, page, limit, order, query);

  @override
  String toString() {
    return 'Pagination(pages: $pages, total: $total, page: $page, limit: $limit, order: $order, query: $query)';
  }
}

/// @nodoc
abstract mixin class $PaginationCopyWith<$Res> {
  factory $PaginationCopyWith(
          Pagination value, $Res Function(Pagination) _then) =
      _$PaginationCopyWithImpl;
  @useResult
  $Res call(
      {int pages,
      int total,
      int page,
      int limit,
      String? order,
      String? query});
}

/// @nodoc
class _$PaginationCopyWithImpl<$Res> implements $PaginationCopyWith<$Res> {
  _$PaginationCopyWithImpl(this._self, this._then);

  final Pagination _self;
  final $Res Function(Pagination) _then;

  /// Create a copy of Pagination
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pages = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? order = freezed,
    Object? query = freezed,
  }) {
    return _then(_self.copyWith(
      pages: null == pages
          ? _self.pages
          : pages // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _self.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      order: freezed == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as String?,
      query: freezed == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _Pagination implements Pagination {
  _Pagination(
      {this.pages = 1,
      this.total = 0,
      this.page = 1,
      this.limit = 10,
      this.order,
      this.query});
  factory _Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);

  @override
  @JsonKey()
  final int pages;
  @override
  @JsonKey()
  final int total;
  @override
  @JsonKey()
  final int page;
  @override
  @JsonKey()
  final int limit;
  @override
  final String? order;
  @override
  final String? query;

  /// Create a copy of Pagination
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PaginationCopyWith<_Pagination> get copyWith =>
      __$PaginationCopyWithImpl<_Pagination>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PaginationToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Pagination &&
            (identical(other.pages, pages) || other.pages == pages) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.query, query) || other.query == query));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, pages, total, page, limit, order, query);

  @override
  String toString() {
    return 'Pagination(pages: $pages, total: $total, page: $page, limit: $limit, order: $order, query: $query)';
  }
}

/// @nodoc
abstract mixin class _$PaginationCopyWith<$Res>
    implements $PaginationCopyWith<$Res> {
  factory _$PaginationCopyWith(
          _Pagination value, $Res Function(_Pagination) _then) =
      __$PaginationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int pages,
      int total,
      int page,
      int limit,
      String? order,
      String? query});
}

/// @nodoc
class __$PaginationCopyWithImpl<$Res> implements _$PaginationCopyWith<$Res> {
  __$PaginationCopyWithImpl(this._self, this._then);

  final _Pagination _self;
  final $Res Function(_Pagination) _then;

  /// Create a copy of Pagination
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pages = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
    Object? order = freezed,
    Object? query = freezed,
  }) {
    return _then(_Pagination(
      pages: null == pages
          ? _self.pages
          : pages // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _self.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      order: freezed == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as String?,
      query: freezed == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on

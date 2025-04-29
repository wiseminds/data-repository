// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Content {
  String? get message;
  String? get rule;

  /// Create a copy of Content
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ContentCopyWith<Content> get copyWith =>
      _$ContentCopyWithImpl<Content>(this as Content, _$identity);

  /// Serializes this Content to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Content &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.rule, rule) || other.rule == rule));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, message, rule);

  @override
  String toString() {
    return 'Content(message: $message, rule: $rule)';
  }
}

/// @nodoc
abstract mixin class $ContentCopyWith<$Res> {
  factory $ContentCopyWith(Content value, $Res Function(Content) _then) =
      _$ContentCopyWithImpl;
  @useResult
  $Res call({String? message, String? rule});
}

/// @nodoc
class _$ContentCopyWithImpl<$Res> implements $ContentCopyWith<$Res> {
  _$ContentCopyWithImpl(this._self, this._then);

  final Content _self;
  final $Res Function(Content) _then;

  /// Create a copy of Content
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
    Object? rule = freezed,
  }) {
    return _then(_self.copyWith(
      message: freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      rule: freezed == rule
          ? _self.rule
          : rule // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _Content implements Content {
  _Content({this.message, this.rule});
  factory _Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson(json);

  @override
  final String? message;
  @override
  final String? rule;

  /// Create a copy of Content
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ContentCopyWith<_Content> get copyWith =>
      __$ContentCopyWithImpl<_Content>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ContentToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Content &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.rule, rule) || other.rule == rule));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, message, rule);

  @override
  String toString() {
    return 'Content(message: $message, rule: $rule)';
  }
}

/// @nodoc
abstract mixin class _$ContentCopyWith<$Res> implements $ContentCopyWith<$Res> {
  factory _$ContentCopyWith(_Content value, $Res Function(_Content) _then) =
      __$ContentCopyWithImpl;
  @override
  @useResult
  $Res call({String? message, String? rule});
}

/// @nodoc
class __$ContentCopyWithImpl<$Res> implements _$ContentCopyWith<$Res> {
  __$ContentCopyWithImpl(this._self, this._then);

  final _Content _self;
  final $Res Function(_Content) _then;

  /// Create a copy of Content
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = freezed,
    Object? rule = freezed,
  }) {
    return _then(_Content(
      message: freezed == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      rule: freezed == rule
          ? _self.rule
          : rule // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on

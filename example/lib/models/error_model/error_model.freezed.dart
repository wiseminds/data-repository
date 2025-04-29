// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ErrorModel {
  String get message;
  int get code;
  Map<String, Content>? get errors;

  /// Create a copy of ErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ErrorModelCopyWith<ErrorModel> get copyWith =>
      _$ErrorModelCopyWithImpl<ErrorModel>(this as ErrorModel, _$identity);

  /// Serializes this ErrorModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ErrorModel &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.code, code) || other.code == code) &&
            const DeepCollectionEquality().equals(other.errors, errors));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, message, code, const DeepCollectionEquality().hash(errors));
}

/// @nodoc
abstract mixin class $ErrorModelCopyWith<$Res> {
  factory $ErrorModelCopyWith(
          ErrorModel value, $Res Function(ErrorModel) _then) =
      _$ErrorModelCopyWithImpl;
  @useResult
  $Res call({String message, int code, Map<String, Content>? errors});
}

/// @nodoc
class _$ErrorModelCopyWithImpl<$Res> implements $ErrorModelCopyWith<$Res> {
  _$ErrorModelCopyWithImpl(this._self, this._then);

  final ErrorModel _self;
  final $Res Function(ErrorModel) _then;

  /// Create a copy of ErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? code = null,
    Object? errors = freezed,
  }) {
    return _then(_self.copyWith(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as int,
      errors: freezed == errors
          ? _self.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as Map<String, Content>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ErrorModel implements ErrorModel {
  _ErrorModel(
      {this.message = 'An error occured',
      this.code = 400,
      final Map<String, Content>? errors})
      : _errors = errors;
  factory _ErrorModel.fromJson(Map<String, dynamic> json) =>
      _$ErrorModelFromJson(json);

  @override
  @JsonKey()
  final String message;
  @override
  @JsonKey()
  final int code;
  final Map<String, Content>? _errors;
  @override
  Map<String, Content>? get errors {
    final value = _errors;
    if (value == null) return null;
    if (_errors is EqualUnmodifiableMapView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Create a copy of ErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ErrorModelCopyWith<_ErrorModel> get copyWith =>
      __$ErrorModelCopyWithImpl<_ErrorModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ErrorModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ErrorModel &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.code, code) || other.code == code) &&
            const DeepCollectionEquality().equals(other._errors, _errors));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, message, code, const DeepCollectionEquality().hash(_errors));
}

/// @nodoc
abstract mixin class _$ErrorModelCopyWith<$Res>
    implements $ErrorModelCopyWith<$Res> {
  factory _$ErrorModelCopyWith(
          _ErrorModel value, $Res Function(_ErrorModel) _then) =
      __$ErrorModelCopyWithImpl;
  @override
  @useResult
  $Res call({String message, int code, Map<String, Content>? errors});
}

/// @nodoc
class __$ErrorModelCopyWithImpl<$Res> implements _$ErrorModelCopyWith<$Res> {
  __$ErrorModelCopyWithImpl(this._self, this._then);

  final _ErrorModel _self;
  final $Res Function(_ErrorModel) _then;

  /// Create a copy of ErrorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
    Object? code = null,
    Object? errors = freezed,
  }) {
    return _then(_ErrorModel(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as int,
      errors: freezed == errors
          ? _self._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as Map<String, Content>?,
    ));
  }
}

// dart format on

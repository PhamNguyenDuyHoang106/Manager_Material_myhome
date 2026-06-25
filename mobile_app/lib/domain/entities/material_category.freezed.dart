// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'material_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MaterialCategory _$MaterialCategoryFromJson(Map<String, dynamic> json) {
  return _MaterialCategory.fromJson(json);
}

/// @nodoc
mixin _$MaterialCategory {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this MaterialCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaterialCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaterialCategoryCopyWith<MaterialCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaterialCategoryCopyWith<$Res> {
  factory $MaterialCategoryCopyWith(
          MaterialCategory value, $Res Function(MaterialCategory) then) =
      _$MaterialCategoryCopyWithImpl<$Res, MaterialCategory>;
  @useResult
  $Res call({String id, String name, bool isDeleted, String createdAt});
}

/// @nodoc
class _$MaterialCategoryCopyWithImpl<$Res, $Val extends MaterialCategory>
    implements $MaterialCategoryCopyWith<$Res> {
  _$MaterialCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaterialCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? isDeleted = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MaterialCategoryImplCopyWith<$Res>
    implements $MaterialCategoryCopyWith<$Res> {
  factory _$$MaterialCategoryImplCopyWith(_$MaterialCategoryImpl value,
          $Res Function(_$MaterialCategoryImpl) then) =
      __$$MaterialCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, bool isDeleted, String createdAt});
}

/// @nodoc
class __$$MaterialCategoryImplCopyWithImpl<$Res>
    extends _$MaterialCategoryCopyWithImpl<$Res, _$MaterialCategoryImpl>
    implements _$$MaterialCategoryImplCopyWith<$Res> {
  __$$MaterialCategoryImplCopyWithImpl(_$MaterialCategoryImpl _value,
      $Res Function(_$MaterialCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of MaterialCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? isDeleted = null,
    Object? createdAt = null,
  }) {
    return _then(_$MaterialCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MaterialCategoryImpl implements _MaterialCategory {
  const _$MaterialCategoryImpl(
      {required this.id,
      required this.name,
      this.isDeleted = false,
      required this.createdAt});

  factory _$MaterialCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaterialCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  final String createdAt;

  @override
  String toString() {
    return 'MaterialCategory(id: $id, name: $name, isDeleted: $isDeleted, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaterialCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, isDeleted, createdAt);

  /// Create a copy of MaterialCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaterialCategoryImplCopyWith<_$MaterialCategoryImpl> get copyWith =>
      __$$MaterialCategoryImplCopyWithImpl<_$MaterialCategoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MaterialCategoryImplToJson(
      this,
    );
  }
}

abstract class _MaterialCategory implements MaterialCategory {
  const factory _MaterialCategory(
      {required final String id,
      required final String name,
      final bool isDeleted,
      required final String createdAt}) = _$MaterialCategoryImpl;

  factory _MaterialCategory.fromJson(Map<String, dynamic> json) =
      _$MaterialCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get isDeleted;
  @override
  String get createdAt;

  /// Create a copy of MaterialCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaterialCategoryImplCopyWith<_$MaterialCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

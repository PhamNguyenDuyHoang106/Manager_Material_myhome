// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'material.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StockMaterial _$StockMaterialFromJson(Map<String, dynamic> json) {
  return _StockMaterial.fromJson(json);
}

/// @nodoc
mixin _$StockMaterial {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  @JsonKey(name: 'defaultImportPriceCents')
  int get defaultImportPriceCents => throw _privateConstructorUsedError;
  @JsonKey(name: 'defaultSellingPriceCents')
  int get defaultSellingPriceCents => throw _privateConstructorUsedError;
  @JsonKey(name: 'currentStock')
  double get currentStock => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this StockMaterial to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StockMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StockMaterialCopyWith<StockMaterial> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockMaterialCopyWith<$Res> {
  factory $StockMaterialCopyWith(
          StockMaterial value, $Res Function(StockMaterial) then) =
      _$StockMaterialCopyWithImpl<$Res, StockMaterial>;
  @useResult
  $Res call(
      {String id,
      String name,
      String unit,
      @JsonKey(name: 'defaultImportPriceCents') int defaultImportPriceCents,
      @JsonKey(name: 'defaultSellingPriceCents') int defaultSellingPriceCents,
      @JsonKey(name: 'currentStock') double currentStock,
      bool isDeleted,
      String createdAt,
      String updatedAt});
}

/// @nodoc
class _$StockMaterialCopyWithImpl<$Res, $Val extends StockMaterial>
    implements $StockMaterialCopyWith<$Res> {
  _$StockMaterialCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StockMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? unit = null,
    Object? defaultImportPriceCents = null,
    Object? defaultSellingPriceCents = null,
    Object? currentStock = null,
    Object? isDeleted = null,
    Object? createdAt = null,
    Object? updatedAt = null,
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
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      defaultImportPriceCents: null == defaultImportPriceCents
          ? _value.defaultImportPriceCents
          : defaultImportPriceCents // ignore: cast_nullable_to_non_nullable
              as int,
      defaultSellingPriceCents: null == defaultSellingPriceCents
          ? _value.defaultSellingPriceCents
          : defaultSellingPriceCents // ignore: cast_nullable_to_non_nullable
              as int,
      currentStock: null == currentStock
          ? _value.currentStock
          : currentStock // ignore: cast_nullable_to_non_nullable
              as double,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StockMaterialImplCopyWith<$Res>
    implements $StockMaterialCopyWith<$Res> {
  factory _$$StockMaterialImplCopyWith(
          _$StockMaterialImpl value, $Res Function(_$StockMaterialImpl) then) =
      __$$StockMaterialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String unit,
      @JsonKey(name: 'defaultImportPriceCents') int defaultImportPriceCents,
      @JsonKey(name: 'defaultSellingPriceCents') int defaultSellingPriceCents,
      @JsonKey(name: 'currentStock') double currentStock,
      bool isDeleted,
      String createdAt,
      String updatedAt});
}

/// @nodoc
class __$$StockMaterialImplCopyWithImpl<$Res>
    extends _$StockMaterialCopyWithImpl<$Res, _$StockMaterialImpl>
    implements _$$StockMaterialImplCopyWith<$Res> {
  __$$StockMaterialImplCopyWithImpl(
      _$StockMaterialImpl _value, $Res Function(_$StockMaterialImpl) _then)
      : super(_value, _then);

  /// Create a copy of StockMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? unit = null,
    Object? defaultImportPriceCents = null,
    Object? defaultSellingPriceCents = null,
    Object? currentStock = null,
    Object? isDeleted = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$StockMaterialImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      defaultImportPriceCents: null == defaultImportPriceCents
          ? _value.defaultImportPriceCents
          : defaultImportPriceCents // ignore: cast_nullable_to_non_nullable
              as int,
      defaultSellingPriceCents: null == defaultSellingPriceCents
          ? _value.defaultSellingPriceCents
          : defaultSellingPriceCents // ignore: cast_nullable_to_non_nullable
              as int,
      currentStock: null == currentStock
          ? _value.currentStock
          : currentStock // ignore: cast_nullable_to_non_nullable
              as double,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StockMaterialImpl implements _StockMaterial {
  const _$StockMaterialImpl(
      {required this.id,
      required this.name,
      required this.unit,
      @JsonKey(name: 'defaultImportPriceCents')
      required this.defaultImportPriceCents,
      @JsonKey(name: 'defaultSellingPriceCents')
      required this.defaultSellingPriceCents,
      @JsonKey(name: 'currentStock') required this.currentStock,
      this.isDeleted = false,
      required this.createdAt,
      required this.updatedAt});

  factory _$StockMaterialImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockMaterialImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String unit;
  @override
  @JsonKey(name: 'defaultImportPriceCents')
  final int defaultImportPriceCents;
  @override
  @JsonKey(name: 'defaultSellingPriceCents')
  final int defaultSellingPriceCents;
  @override
  @JsonKey(name: 'currentStock')
  final double currentStock;
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  final String createdAt;
  @override
  final String updatedAt;

  @override
  String toString() {
    return 'StockMaterial(id: $id, name: $name, unit: $unit, defaultImportPriceCents: $defaultImportPriceCents, defaultSellingPriceCents: $defaultSellingPriceCents, currentStock: $currentStock, isDeleted: $isDeleted, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockMaterialImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(
                    other.defaultImportPriceCents, defaultImportPriceCents) ||
                other.defaultImportPriceCents == defaultImportPriceCents) &&
            (identical(
                    other.defaultSellingPriceCents, defaultSellingPriceCents) ||
                other.defaultSellingPriceCents == defaultSellingPriceCents) &&
            (identical(other.currentStock, currentStock) ||
                other.currentStock == currentStock) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      unit,
      defaultImportPriceCents,
      defaultSellingPriceCents,
      currentStock,
      isDeleted,
      createdAt,
      updatedAt);

  /// Create a copy of StockMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StockMaterialImplCopyWith<_$StockMaterialImpl> get copyWith =>
      __$$StockMaterialImplCopyWithImpl<_$StockMaterialImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StockMaterialImplToJson(
      this,
    );
  }
}

abstract class _StockMaterial implements StockMaterial {
  const factory _StockMaterial(
      {required final String id,
      required final String name,
      required final String unit,
      @JsonKey(name: 'defaultImportPriceCents')
      required final int defaultImportPriceCents,
      @JsonKey(name: 'defaultSellingPriceCents')
      required final int defaultSellingPriceCents,
      @JsonKey(name: 'currentStock') required final double currentStock,
      final bool isDeleted,
      required final String createdAt,
      required final String updatedAt}) = _$StockMaterialImpl;

  factory _StockMaterial.fromJson(Map<String, dynamic> json) =
      _$StockMaterialImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get unit;
  @override
  @JsonKey(name: 'defaultImportPriceCents')
  int get defaultImportPriceCents;
  @override
  @JsonKey(name: 'defaultSellingPriceCents')
  int get defaultSellingPriceCents;
  @override
  @JsonKey(name: 'currentStock')
  double get currentStock;
  @override
  bool get isDeleted;
  @override
  String get createdAt;
  @override
  String get updatedAt;

  /// Create a copy of StockMaterial
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StockMaterialImplCopyWith<_$StockMaterialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

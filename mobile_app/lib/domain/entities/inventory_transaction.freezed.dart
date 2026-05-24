// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InventoryTransaction _$InventoryTransactionFromJson(Map<String, dynamic> json) {
  return _InventoryTransaction.fromJson(json);
}

/// @nodoc
mixin _$InventoryTransaction {
  String get id => throw _privateConstructorUsedError;
  String get materialId => throw _privateConstructorUsedError;
  String get materialName => throw _privateConstructorUsedError;
  @InventoryTxTypeConverter()
  InventoryTxType get type => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  double get stockAfter => throw _privateConstructorUsedError;
  String? get referenceId => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this InventoryTransaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InventoryTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InventoryTransactionCopyWith<InventoryTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InventoryTransactionCopyWith<$Res> {
  factory $InventoryTransactionCopyWith(InventoryTransaction value,
          $Res Function(InventoryTransaction) then) =
      _$InventoryTransactionCopyWithImpl<$Res, InventoryTransaction>;
  @useResult
  $Res call(
      {String id,
      String materialId,
      String materialName,
      @InventoryTxTypeConverter() InventoryTxType type,
      double quantity,
      double stockAfter,
      String? referenceId,
      String? note,
      String createdAt});
}

/// @nodoc
class _$InventoryTransactionCopyWithImpl<$Res,
        $Val extends InventoryTransaction>
    implements $InventoryTransactionCopyWith<$Res> {
  _$InventoryTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InventoryTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? materialId = null,
    Object? materialName = null,
    Object? type = null,
    Object? quantity = null,
    Object? stockAfter = null,
    Object? referenceId = freezed,
    Object? note = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      materialName: null == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as InventoryTxType,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      stockAfter: null == stockAfter
          ? _value.stockAfter
          : stockAfter // ignore: cast_nullable_to_non_nullable
              as double,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InventoryTransactionImplCopyWith<$Res>
    implements $InventoryTransactionCopyWith<$Res> {
  factory _$$InventoryTransactionImplCopyWith(_$InventoryTransactionImpl value,
          $Res Function(_$InventoryTransactionImpl) then) =
      __$$InventoryTransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String materialId,
      String materialName,
      @InventoryTxTypeConverter() InventoryTxType type,
      double quantity,
      double stockAfter,
      String? referenceId,
      String? note,
      String createdAt});
}

/// @nodoc
class __$$InventoryTransactionImplCopyWithImpl<$Res>
    extends _$InventoryTransactionCopyWithImpl<$Res, _$InventoryTransactionImpl>
    implements _$$InventoryTransactionImplCopyWith<$Res> {
  __$$InventoryTransactionImplCopyWithImpl(_$InventoryTransactionImpl _value,
      $Res Function(_$InventoryTransactionImpl) _then)
      : super(_value, _then);

  /// Create a copy of InventoryTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? materialId = null,
    Object? materialName = null,
    Object? type = null,
    Object? quantity = null,
    Object? stockAfter = null,
    Object? referenceId = freezed,
    Object? note = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$InventoryTransactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      materialName: null == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as InventoryTxType,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      stockAfter: null == stockAfter
          ? _value.stockAfter
          : stockAfter // ignore: cast_nullable_to_non_nullable
              as double,
      referenceId: freezed == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InventoryTransactionImpl implements _InventoryTransaction {
  const _$InventoryTransactionImpl(
      {required this.id,
      required this.materialId,
      required this.materialName,
      @InventoryTxTypeConverter() required this.type,
      required this.quantity,
      required this.stockAfter,
      this.referenceId,
      this.note,
      required this.createdAt});

  factory _$InventoryTransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$InventoryTransactionImplFromJson(json);

  @override
  final String id;
  @override
  final String materialId;
  @override
  final String materialName;
  @override
  @InventoryTxTypeConverter()
  final InventoryTxType type;
  @override
  final double quantity;
  @override
  final double stockAfter;
  @override
  final String? referenceId;
  @override
  final String? note;
  @override
  final String createdAt;

  @override
  String toString() {
    return 'InventoryTransaction(id: $id, materialId: $materialId, materialName: $materialName, type: $type, quantity: $quantity, stockAfter: $stockAfter, referenceId: $referenceId, note: $note, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InventoryTransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.stockAfter, stockAfter) ||
                other.stockAfter == stockAfter) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, materialId, materialName,
      type, quantity, stockAfter, referenceId, note, createdAt);

  /// Create a copy of InventoryTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InventoryTransactionImplCopyWith<_$InventoryTransactionImpl>
      get copyWith =>
          __$$InventoryTransactionImplCopyWithImpl<_$InventoryTransactionImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InventoryTransactionImplToJson(
      this,
    );
  }
}

abstract class _InventoryTransaction implements InventoryTransaction {
  const factory _InventoryTransaction(
      {required final String id,
      required final String materialId,
      required final String materialName,
      @InventoryTxTypeConverter() required final InventoryTxType type,
      required final double quantity,
      required final double stockAfter,
      final String? referenceId,
      final String? note,
      required final String createdAt}) = _$InventoryTransactionImpl;

  factory _InventoryTransaction.fromJson(Map<String, dynamic> json) =
      _$InventoryTransactionImpl.fromJson;

  @override
  String get id;
  @override
  String get materialId;
  @override
  String get materialName;
  @override
  @InventoryTxTypeConverter()
  InventoryTxType get type;
  @override
  double get quantity;
  @override
  double get stockAfter;
  @override
  String? get referenceId;
  @override
  String? get note;
  @override
  String get createdAt;

  /// Create a copy of InventoryTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InventoryTransactionImplCopyWith<_$InventoryTransactionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_ledger_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LedgerItemSnapshot _$LedgerItemSnapshotFromJson(Map<String, dynamic> json) {
  return _LedgerItemSnapshot.fromJson(json);
}

/// @nodoc
mixin _$LedgerItemSnapshot {
  String get materialId => throw _privateConstructorUsedError;
  String get materialName => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  int get sellingPriceCents => throw _privateConstructorUsedError;
  int get lineTotalCents => throw _privateConstructorUsedError;

  /// Serializes this LedgerItemSnapshot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LedgerItemSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LedgerItemSnapshotCopyWith<LedgerItemSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LedgerItemSnapshotCopyWith<$Res> {
  factory $LedgerItemSnapshotCopyWith(
          LedgerItemSnapshot value, $Res Function(LedgerItemSnapshot) then) =
      _$LedgerItemSnapshotCopyWithImpl<$Res, LedgerItemSnapshot>;
  @useResult
  $Res call(
      {String materialId,
      String materialName,
      double quantity,
      String unit,
      int sellingPriceCents,
      int lineTotalCents});
}

/// @nodoc
class _$LedgerItemSnapshotCopyWithImpl<$Res, $Val extends LedgerItemSnapshot>
    implements $LedgerItemSnapshotCopyWith<$Res> {
  _$LedgerItemSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LedgerItemSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? materialId = null,
    Object? materialName = null,
    Object? quantity = null,
    Object? unit = null,
    Object? sellingPriceCents = null,
    Object? lineTotalCents = null,
  }) {
    return _then(_value.copyWith(
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      materialName: null == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      sellingPriceCents: null == sellingPriceCents
          ? _value.sellingPriceCents
          : sellingPriceCents // ignore: cast_nullable_to_non_nullable
              as int,
      lineTotalCents: null == lineTotalCents
          ? _value.lineTotalCents
          : lineTotalCents // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LedgerItemSnapshotImplCopyWith<$Res>
    implements $LedgerItemSnapshotCopyWith<$Res> {
  factory _$$LedgerItemSnapshotImplCopyWith(_$LedgerItemSnapshotImpl value,
          $Res Function(_$LedgerItemSnapshotImpl) then) =
      __$$LedgerItemSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String materialId,
      String materialName,
      double quantity,
      String unit,
      int sellingPriceCents,
      int lineTotalCents});
}

/// @nodoc
class __$$LedgerItemSnapshotImplCopyWithImpl<$Res>
    extends _$LedgerItemSnapshotCopyWithImpl<$Res, _$LedgerItemSnapshotImpl>
    implements _$$LedgerItemSnapshotImplCopyWith<$Res> {
  __$$LedgerItemSnapshotImplCopyWithImpl(_$LedgerItemSnapshotImpl _value,
      $Res Function(_$LedgerItemSnapshotImpl) _then)
      : super(_value, _then);

  /// Create a copy of LedgerItemSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? materialId = null,
    Object? materialName = null,
    Object? quantity = null,
    Object? unit = null,
    Object? sellingPriceCents = null,
    Object? lineTotalCents = null,
  }) {
    return _then(_$LedgerItemSnapshotImpl(
      materialId: null == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as String,
      materialName: null == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      sellingPriceCents: null == sellingPriceCents
          ? _value.sellingPriceCents
          : sellingPriceCents // ignore: cast_nullable_to_non_nullable
              as int,
      lineTotalCents: null == lineTotalCents
          ? _value.lineTotalCents
          : lineTotalCents // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LedgerItemSnapshotImpl implements _LedgerItemSnapshot {
  const _$LedgerItemSnapshotImpl(
      {required this.materialId,
      required this.materialName,
      required this.quantity,
      required this.unit,
      required this.sellingPriceCents,
      required this.lineTotalCents});

  factory _$LedgerItemSnapshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$LedgerItemSnapshotImplFromJson(json);

  @override
  final String materialId;
  @override
  final String materialName;
  @override
  final double quantity;
  @override
  final String unit;
  @override
  final int sellingPriceCents;
  @override
  final int lineTotalCents;

  @override
  String toString() {
    return 'LedgerItemSnapshot(materialId: $materialId, materialName: $materialName, quantity: $quantity, unit: $unit, sellingPriceCents: $sellingPriceCents, lineTotalCents: $lineTotalCents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LedgerItemSnapshotImpl &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.sellingPriceCents, sellingPriceCents) ||
                other.sellingPriceCents == sellingPriceCents) &&
            (identical(other.lineTotalCents, lineTotalCents) ||
                other.lineTotalCents == lineTotalCents));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, materialId, materialName,
      quantity, unit, sellingPriceCents, lineTotalCents);

  /// Create a copy of LedgerItemSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LedgerItemSnapshotImplCopyWith<_$LedgerItemSnapshotImpl> get copyWith =>
      __$$LedgerItemSnapshotImplCopyWithImpl<_$LedgerItemSnapshotImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LedgerItemSnapshotImplToJson(
      this,
    );
  }
}

abstract class _LedgerItemSnapshot implements LedgerItemSnapshot {
  const factory _LedgerItemSnapshot(
      {required final String materialId,
      required final String materialName,
      required final double quantity,
      required final String unit,
      required final int sellingPriceCents,
      required final int lineTotalCents}) = _$LedgerItemSnapshotImpl;

  factory _LedgerItemSnapshot.fromJson(Map<String, dynamic> json) =
      _$LedgerItemSnapshotImpl.fromJson;

  @override
  String get materialId;
  @override
  String get materialName;
  @override
  double get quantity;
  @override
  String get unit;
  @override
  int get sellingPriceCents;
  @override
  int get lineTotalCents;

  /// Create a copy of LedgerItemSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LedgerItemSnapshotImplCopyWith<_$LedgerItemSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomerLedgerEntry _$CustomerLedgerEntryFromJson(Map<String, dynamic> json) {
  return _CustomerLedgerEntry.fromJson(json);
}

/// @nodoc
mixin _$CustomerLedgerEntry {
  String get id => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  String? get invoiceId => throw _privateConstructorUsedError;
  String? get paymentId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  LedgerEntryType get type => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get amountCents => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get attachmentUrl => throw _privateConstructorUsedError;
  List<LedgerItemSnapshot> get items => throw _privateConstructorUsedError;

  /// Serializes this CustomerLedgerEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerLedgerEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerLedgerEntryCopyWith<CustomerLedgerEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerLedgerEntryCopyWith<$Res> {
  factory $CustomerLedgerEntryCopyWith(
          CustomerLedgerEntry value, $Res Function(CustomerLedgerEntry) then) =
      _$CustomerLedgerEntryCopyWithImpl<$Res, CustomerLedgerEntry>;
  @useResult
  $Res call(
      {String id,
      String customerId,
      String? invoiceId,
      String? paymentId,
      DateTime date,
      LedgerEntryType type,
      String description,
      int amountCents,
      DateTime createdAt,
      String? attachmentUrl,
      List<LedgerItemSnapshot> items});
}

/// @nodoc
class _$CustomerLedgerEntryCopyWithImpl<$Res, $Val extends CustomerLedgerEntry>
    implements $CustomerLedgerEntryCopyWith<$Res> {
  _$CustomerLedgerEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerLedgerEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = null,
    Object? invoiceId = freezed,
    Object? paymentId = freezed,
    Object? date = null,
    Object? type = null,
    Object? description = null,
    Object? amountCents = null,
    Object? createdAt = null,
    Object? attachmentUrl = freezed,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: null == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceId: freezed == invoiceId
          ? _value.invoiceId
          : invoiceId // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentId: freezed == paymentId
          ? _value.paymentId
          : paymentId // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as LedgerEntryType,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      amountCents: null == amountCents
          ? _value.amountCents
          : amountCents // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      attachmentUrl: freezed == attachmentUrl
          ? _value.attachmentUrl
          : attachmentUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<LedgerItemSnapshot>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CustomerLedgerEntryImplCopyWith<$Res>
    implements $CustomerLedgerEntryCopyWith<$Res> {
  factory _$$CustomerLedgerEntryImplCopyWith(_$CustomerLedgerEntryImpl value,
          $Res Function(_$CustomerLedgerEntryImpl) then) =
      __$$CustomerLedgerEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String customerId,
      String? invoiceId,
      String? paymentId,
      DateTime date,
      LedgerEntryType type,
      String description,
      int amountCents,
      DateTime createdAt,
      String? attachmentUrl,
      List<LedgerItemSnapshot> items});
}

/// @nodoc
class __$$CustomerLedgerEntryImplCopyWithImpl<$Res>
    extends _$CustomerLedgerEntryCopyWithImpl<$Res, _$CustomerLedgerEntryImpl>
    implements _$$CustomerLedgerEntryImplCopyWith<$Res> {
  __$$CustomerLedgerEntryImplCopyWithImpl(_$CustomerLedgerEntryImpl _value,
      $Res Function(_$CustomerLedgerEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of CustomerLedgerEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = null,
    Object? invoiceId = freezed,
    Object? paymentId = freezed,
    Object? date = null,
    Object? type = null,
    Object? description = null,
    Object? amountCents = null,
    Object? createdAt = null,
    Object? attachmentUrl = freezed,
    Object? items = null,
  }) {
    return _then(_$CustomerLedgerEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: null == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceId: freezed == invoiceId
          ? _value.invoiceId
          : invoiceId // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentId: freezed == paymentId
          ? _value.paymentId
          : paymentId // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as LedgerEntryType,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      amountCents: null == amountCents
          ? _value.amountCents
          : amountCents // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      attachmentUrl: freezed == attachmentUrl
          ? _value.attachmentUrl
          : attachmentUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<LedgerItemSnapshot>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerLedgerEntryImpl implements _CustomerLedgerEntry {
  const _$CustomerLedgerEntryImpl(
      {required this.id,
      required this.customerId,
      this.invoiceId,
      this.paymentId,
      required this.date,
      required this.type,
      required this.description,
      required this.amountCents,
      required this.createdAt,
      this.attachmentUrl,
      final List<LedgerItemSnapshot> items = const []})
      : _items = items;

  factory _$CustomerLedgerEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerLedgerEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String customerId;
  @override
  final String? invoiceId;
  @override
  final String? paymentId;
  @override
  final DateTime date;
  @override
  final LedgerEntryType type;
  @override
  final String description;
  @override
  final int amountCents;
  @override
  final DateTime createdAt;
  @override
  final String? attachmentUrl;
  final List<LedgerItemSnapshot> _items;
  @override
  @JsonKey()
  List<LedgerItemSnapshot> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'CustomerLedgerEntry(id: $id, customerId: $customerId, invoiceId: $invoiceId, paymentId: $paymentId, date: $date, type: $type, description: $description, amountCents: $amountCents, createdAt: $createdAt, attachmentUrl: $attachmentUrl, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerLedgerEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.invoiceId, invoiceId) ||
                other.invoiceId == invoiceId) &&
            (identical(other.paymentId, paymentId) ||
                other.paymentId == paymentId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.amountCents, amountCents) ||
                other.amountCents == amountCents) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.attachmentUrl, attachmentUrl) ||
                other.attachmentUrl == attachmentUrl) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      customerId,
      invoiceId,
      paymentId,
      date,
      type,
      description,
      amountCents,
      createdAt,
      attachmentUrl,
      const DeepCollectionEquality().hash(_items));

  /// Create a copy of CustomerLedgerEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerLedgerEntryImplCopyWith<_$CustomerLedgerEntryImpl> get copyWith =>
      __$$CustomerLedgerEntryImplCopyWithImpl<_$CustomerLedgerEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerLedgerEntryImplToJson(
      this,
    );
  }
}

abstract class _CustomerLedgerEntry implements CustomerLedgerEntry {
  const factory _CustomerLedgerEntry(
      {required final String id,
      required final String customerId,
      final String? invoiceId,
      final String? paymentId,
      required final DateTime date,
      required final LedgerEntryType type,
      required final String description,
      required final int amountCents,
      required final DateTime createdAt,
      final String? attachmentUrl,
      final List<LedgerItemSnapshot> items}) = _$CustomerLedgerEntryImpl;

  factory _CustomerLedgerEntry.fromJson(Map<String, dynamic> json) =
      _$CustomerLedgerEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get customerId;
  @override
  String? get invoiceId;
  @override
  String? get paymentId;
  @override
  DateTime get date;
  @override
  LedgerEntryType get type;
  @override
  String get description;
  @override
  int get amountCents;
  @override
  DateTime get createdAt;
  @override
  String? get attachmentUrl;
  @override
  List<LedgerItemSnapshot> get items;

  /// Create a copy of CustomerLedgerEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerLedgerEntryImplCopyWith<_$CustomerLedgerEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

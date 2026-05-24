// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InvoiceItem _$InvoiceItemFromJson(Map<String, dynamic> json) {
  return _InvoiceItem.fromJson(json);
}

/// @nodoc
mixin _$InvoiceItem {
  String get id => throw _privateConstructorUsedError;
  String get materialId => throw _privateConstructorUsedError;
  String get materialName => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'sellingPriceCents')
  int get sellingPriceCents => throw _privateConstructorUsedError;
  @JsonKey(name: 'lineTotalCents')
  int get lineTotalCents => throw _privateConstructorUsedError;

  /// Serializes this InvoiceItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InvoiceItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvoiceItemCopyWith<InvoiceItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceItemCopyWith<$Res> {
  factory $InvoiceItemCopyWith(
          InvoiceItem value, $Res Function(InvoiceItem) then) =
      _$InvoiceItemCopyWithImpl<$Res, InvoiceItem>;
  @useResult
  $Res call(
      {String id,
      String materialId,
      String materialName,
      String unit,
      double quantity,
      @JsonKey(name: 'sellingPriceCents') int sellingPriceCents,
      @JsonKey(name: 'lineTotalCents') int lineTotalCents});
}

/// @nodoc
class _$InvoiceItemCopyWithImpl<$Res, $Val extends InvoiceItem>
    implements $InvoiceItemCopyWith<$Res> {
  _$InvoiceItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InvoiceItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? materialId = null,
    Object? materialName = null,
    Object? unit = null,
    Object? quantity = null,
    Object? sellingPriceCents = null,
    Object? lineTotalCents = null,
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
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
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
abstract class _$$InvoiceItemImplCopyWith<$Res>
    implements $InvoiceItemCopyWith<$Res> {
  factory _$$InvoiceItemImplCopyWith(
          _$InvoiceItemImpl value, $Res Function(_$InvoiceItemImpl) then) =
      __$$InvoiceItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String materialId,
      String materialName,
      String unit,
      double quantity,
      @JsonKey(name: 'sellingPriceCents') int sellingPriceCents,
      @JsonKey(name: 'lineTotalCents') int lineTotalCents});
}

/// @nodoc
class __$$InvoiceItemImplCopyWithImpl<$Res>
    extends _$InvoiceItemCopyWithImpl<$Res, _$InvoiceItemImpl>
    implements _$$InvoiceItemImplCopyWith<$Res> {
  __$$InvoiceItemImplCopyWithImpl(
      _$InvoiceItemImpl _value, $Res Function(_$InvoiceItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of InvoiceItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? materialId = null,
    Object? materialName = null,
    Object? unit = null,
    Object? quantity = null,
    Object? sellingPriceCents = null,
    Object? lineTotalCents = null,
  }) {
    return _then(_$InvoiceItemImpl(
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
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
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
class _$InvoiceItemImpl implements _InvoiceItem {
  const _$InvoiceItemImpl(
      {required this.id,
      required this.materialId,
      required this.materialName,
      required this.unit,
      required this.quantity,
      @JsonKey(name: 'sellingPriceCents') required this.sellingPriceCents,
      @JsonKey(name: 'lineTotalCents') required this.lineTotalCents});

  factory _$InvoiceItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvoiceItemImplFromJson(json);

  @override
  final String id;
  @override
  final String materialId;
  @override
  final String materialName;
  @override
  final String unit;
  @override
  final double quantity;
  @override
  @JsonKey(name: 'sellingPriceCents')
  final int sellingPriceCents;
  @override
  @JsonKey(name: 'lineTotalCents')
  final int lineTotalCents;

  @override
  String toString() {
    return 'InvoiceItem(id: $id, materialId: $materialId, materialName: $materialName, unit: $unit, quantity: $quantity, sellingPriceCents: $sellingPriceCents, lineTotalCents: $lineTotalCents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.sellingPriceCents, sellingPriceCents) ||
                other.sellingPriceCents == sellingPriceCents) &&
            (identical(other.lineTotalCents, lineTotalCents) ||
                other.lineTotalCents == lineTotalCents));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, materialId, materialName,
      unit, quantity, sellingPriceCents, lineTotalCents);

  /// Create a copy of InvoiceItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceItemImplCopyWith<_$InvoiceItemImpl> get copyWith =>
      __$$InvoiceItemImplCopyWithImpl<_$InvoiceItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvoiceItemImplToJson(
      this,
    );
  }
}

abstract class _InvoiceItem implements InvoiceItem {
  const factory _InvoiceItem(
      {required final String id,
      required final String materialId,
      required final String materialName,
      required final String unit,
      required final double quantity,
      @JsonKey(name: 'sellingPriceCents') required final int sellingPriceCents,
      @JsonKey(name: 'lineTotalCents')
      required final int lineTotalCents}) = _$InvoiceItemImpl;

  factory _InvoiceItem.fromJson(Map<String, dynamic> json) =
      _$InvoiceItemImpl.fromJson;

  @override
  String get id;
  @override
  String get materialId;
  @override
  String get materialName;
  @override
  String get unit;
  @override
  double get quantity;
  @override
  @JsonKey(name: 'sellingPriceCents')
  int get sellingPriceCents;
  @override
  @JsonKey(name: 'lineTotalCents')
  int get lineTotalCents;

  /// Create a copy of InvoiceItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceItemImplCopyWith<_$InvoiceItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Invoice _$InvoiceFromJson(Map<String, dynamic> json) {
  return _Invoice.fromJson(json);
}

/// @nodoc
mixin _$Invoice {
  String get id => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  String get customerName => throw _privateConstructorUsedError;
  String get invoiceDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'totalAmountCents')
  int get totalAmountCents => throw _privateConstructorUsedError;
  @JsonKey(name: 'paidAmountCents')
  int get paidAmountCents => throw _privateConstructorUsedError;
  @InvoiceStatusConverter()
  InvoiceStatus get status => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get updatedAt => throw _privateConstructorUsedError;
  List<InvoiceItem> get items => throw _privateConstructorUsedError;

  /// Serializes this Invoice to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvoiceCopyWith<Invoice> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceCopyWith<$Res> {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) then) =
      _$InvoiceCopyWithImpl<$Res, Invoice>;
  @useResult
  $Res call(
      {String id,
      String customerId,
      String customerName,
      String invoiceDate,
      @JsonKey(name: 'totalAmountCents') int totalAmountCents,
      @JsonKey(name: 'paidAmountCents') int paidAmountCents,
      @InvoiceStatusConverter() InvoiceStatus status,
      String createdAt,
      String updatedAt,
      List<InvoiceItem> items});
}

/// @nodoc
class _$InvoiceCopyWithImpl<$Res, $Val extends Invoice>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = null,
    Object? customerName = null,
    Object? invoiceDate = null,
    Object? totalAmountCents = null,
    Object? paidAmountCents = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
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
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceDate: null == invoiceDate
          ? _value.invoiceDate
          : invoiceDate // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmountCents: null == totalAmountCents
          ? _value.totalAmountCents
          : totalAmountCents // ignore: cast_nullable_to_non_nullable
              as int,
      paidAmountCents: null == paidAmountCents
          ? _value.paidAmountCents
          : paidAmountCents // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as InvoiceStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<InvoiceItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InvoiceImplCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$$InvoiceImplCopyWith(
          _$InvoiceImpl value, $Res Function(_$InvoiceImpl) then) =
      __$$InvoiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String customerId,
      String customerName,
      String invoiceDate,
      @JsonKey(name: 'totalAmountCents') int totalAmountCents,
      @JsonKey(name: 'paidAmountCents') int paidAmountCents,
      @InvoiceStatusConverter() InvoiceStatus status,
      String createdAt,
      String updatedAt,
      List<InvoiceItem> items});
}

/// @nodoc
class __$$InvoiceImplCopyWithImpl<$Res>
    extends _$InvoiceCopyWithImpl<$Res, _$InvoiceImpl>
    implements _$$InvoiceImplCopyWith<$Res> {
  __$$InvoiceImplCopyWithImpl(
      _$InvoiceImpl _value, $Res Function(_$InvoiceImpl) _then)
      : super(_value, _then);

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = null,
    Object? customerName = null,
    Object? invoiceDate = null,
    Object? totalAmountCents = null,
    Object? paidAmountCents = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? items = null,
  }) {
    return _then(_$InvoiceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: null == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceDate: null == invoiceDate
          ? _value.invoiceDate
          : invoiceDate // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmountCents: null == totalAmountCents
          ? _value.totalAmountCents
          : totalAmountCents // ignore: cast_nullable_to_non_nullable
              as int,
      paidAmountCents: null == paidAmountCents
          ? _value.paidAmountCents
          : paidAmountCents // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as InvoiceStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<InvoiceItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InvoiceImpl implements _Invoice {
  const _$InvoiceImpl(
      {required this.id,
      required this.customerId,
      required this.customerName,
      required this.invoiceDate,
      @JsonKey(name: 'totalAmountCents') required this.totalAmountCents,
      @JsonKey(name: 'paidAmountCents') this.paidAmountCents = 0,
      @InvoiceStatusConverter() required this.status,
      required this.createdAt,
      required this.updatedAt,
      final List<InvoiceItem> items = const []})
      : _items = items;

  factory _$InvoiceImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvoiceImplFromJson(json);

  @override
  final String id;
  @override
  final String customerId;
  @override
  final String customerName;
  @override
  final String invoiceDate;
  @override
  @JsonKey(name: 'totalAmountCents')
  final int totalAmountCents;
  @override
  @JsonKey(name: 'paidAmountCents')
  final int paidAmountCents;
  @override
  @InvoiceStatusConverter()
  final InvoiceStatus status;
  @override
  final String createdAt;
  @override
  final String updatedAt;
  final List<InvoiceItem> _items;
  @override
  @JsonKey()
  List<InvoiceItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'Invoice(id: $id, customerId: $customerId, customerName: $customerName, invoiceDate: $invoiceDate, totalAmountCents: $totalAmountCents, paidAmountCents: $paidAmountCents, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.invoiceDate, invoiceDate) ||
                other.invoiceDate == invoiceDate) &&
            (identical(other.totalAmountCents, totalAmountCents) ||
                other.totalAmountCents == totalAmountCents) &&
            (identical(other.paidAmountCents, paidAmountCents) ||
                other.paidAmountCents == paidAmountCents) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      customerId,
      customerName,
      invoiceDate,
      totalAmountCents,
      paidAmountCents,
      status,
      createdAt,
      updatedAt,
      const DeepCollectionEquality().hash(_items));

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      __$$InvoiceImplCopyWithImpl<_$InvoiceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvoiceImplToJson(
      this,
    );
  }
}

abstract class _Invoice implements Invoice {
  const factory _Invoice(
      {required final String id,
      required final String customerId,
      required final String customerName,
      required final String invoiceDate,
      @JsonKey(name: 'totalAmountCents') required final int totalAmountCents,
      @JsonKey(name: 'paidAmountCents') final int paidAmountCents,
      @InvoiceStatusConverter() required final InvoiceStatus status,
      required final String createdAt,
      required final String updatedAt,
      final List<InvoiceItem> items}) = _$InvoiceImpl;

  factory _Invoice.fromJson(Map<String, dynamic> json) = _$InvoiceImpl.fromJson;

  @override
  String get id;
  @override
  String get customerId;
  @override
  String get customerName;
  @override
  String get invoiceDate;
  @override
  @JsonKey(name: 'totalAmountCents')
  int get totalAmountCents;
  @override
  @JsonKey(name: 'paidAmountCents')
  int get paidAmountCents;
  @override
  @InvoiceStatusConverter()
  InvoiceStatus get status;
  @override
  String get createdAt;
  @override
  String get updatedAt;
  @override
  List<InvoiceItem> get items;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

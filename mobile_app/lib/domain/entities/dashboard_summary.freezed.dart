// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OverdueInvoice _$OverdueInvoiceFromJson(Map<String, dynamic> json) {
  return _OverdueInvoice.fromJson(json);
}

/// @nodoc
mixin _$OverdueInvoice {
  String get id => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  String get customerName => throw _privateConstructorUsedError;
  String get invoiceDate => throw _privateConstructorUsedError;
  int get remainingCents => throw _privateConstructorUsedError;

  /// Serializes this OverdueInvoice to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OverdueInvoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OverdueInvoiceCopyWith<OverdueInvoice> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OverdueInvoiceCopyWith<$Res> {
  factory $OverdueInvoiceCopyWith(
          OverdueInvoice value, $Res Function(OverdueInvoice) then) =
      _$OverdueInvoiceCopyWithImpl<$Res, OverdueInvoice>;
  @useResult
  $Res call(
      {String id,
      String customerId,
      String customerName,
      String invoiceDate,
      int remainingCents});
}

/// @nodoc
class _$OverdueInvoiceCopyWithImpl<$Res, $Val extends OverdueInvoice>
    implements $OverdueInvoiceCopyWith<$Res> {
  _$OverdueInvoiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OverdueInvoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = null,
    Object? customerName = null,
    Object? invoiceDate = null,
    Object? remainingCents = null,
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
      remainingCents: null == remainingCents
          ? _value.remainingCents
          : remainingCents // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OverdueInvoiceImplCopyWith<$Res>
    implements $OverdueInvoiceCopyWith<$Res> {
  factory _$$OverdueInvoiceImplCopyWith(_$OverdueInvoiceImpl value,
          $Res Function(_$OverdueInvoiceImpl) then) =
      __$$OverdueInvoiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String customerId,
      String customerName,
      String invoiceDate,
      int remainingCents});
}

/// @nodoc
class __$$OverdueInvoiceImplCopyWithImpl<$Res>
    extends _$OverdueInvoiceCopyWithImpl<$Res, _$OverdueInvoiceImpl>
    implements _$$OverdueInvoiceImplCopyWith<$Res> {
  __$$OverdueInvoiceImplCopyWithImpl(
      _$OverdueInvoiceImpl _value, $Res Function(_$OverdueInvoiceImpl) _then)
      : super(_value, _then);

  /// Create a copy of OverdueInvoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = null,
    Object? customerName = null,
    Object? invoiceDate = null,
    Object? remainingCents = null,
  }) {
    return _then(_$OverdueInvoiceImpl(
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
      remainingCents: null == remainingCents
          ? _value.remainingCents
          : remainingCents // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OverdueInvoiceImpl implements _OverdueInvoice {
  const _$OverdueInvoiceImpl(
      {required this.id,
      required this.customerId,
      required this.customerName,
      required this.invoiceDate,
      required this.remainingCents});

  factory _$OverdueInvoiceImpl.fromJson(Map<String, dynamic> json) =>
      _$$OverdueInvoiceImplFromJson(json);

  @override
  final String id;
  @override
  final String customerId;
  @override
  final String customerName;
  @override
  final String invoiceDate;
  @override
  final int remainingCents;

  @override
  String toString() {
    return 'OverdueInvoice(id: $id, customerId: $customerId, customerName: $customerName, invoiceDate: $invoiceDate, remainingCents: $remainingCents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OverdueInvoiceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.invoiceDate, invoiceDate) ||
                other.invoiceDate == invoiceDate) &&
            (identical(other.remainingCents, remainingCents) ||
                other.remainingCents == remainingCents));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, customerId, customerName, invoiceDate, remainingCents);

  /// Create a copy of OverdueInvoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OverdueInvoiceImplCopyWith<_$OverdueInvoiceImpl> get copyWith =>
      __$$OverdueInvoiceImplCopyWithImpl<_$OverdueInvoiceImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OverdueInvoiceImplToJson(
      this,
    );
  }
}

abstract class _OverdueInvoice implements OverdueInvoice {
  const factory _OverdueInvoice(
      {required final String id,
      required final String customerId,
      required final String customerName,
      required final String invoiceDate,
      required final int remainingCents}) = _$OverdueInvoiceImpl;

  factory _OverdueInvoice.fromJson(Map<String, dynamic> json) =
      _$OverdueInvoiceImpl.fromJson;

  @override
  String get id;
  @override
  String get customerId;
  @override
  String get customerName;
  @override
  String get invoiceDate;
  @override
  int get remainingCents;

  /// Create a copy of OverdueInvoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OverdueInvoiceImplCopyWith<_$OverdueInvoiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LowStockMaterialSummary _$LowStockMaterialSummaryFromJson(
    Map<String, dynamic> json) {
  return _LowStockMaterialSummary.fromJson(json);
}

/// @nodoc
mixin _$LowStockMaterialSummary {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get currentStock => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  double get minimumStock => throw _privateConstructorUsedError;

  /// Serializes this LowStockMaterialSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LowStockMaterialSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LowStockMaterialSummaryCopyWith<LowStockMaterialSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LowStockMaterialSummaryCopyWith<$Res> {
  factory $LowStockMaterialSummaryCopyWith(LowStockMaterialSummary value,
          $Res Function(LowStockMaterialSummary) then) =
      _$LowStockMaterialSummaryCopyWithImpl<$Res, LowStockMaterialSummary>;
  @useResult
  $Res call(
      {String id,
      String name,
      double currentStock,
      String unit,
      double minimumStock});
}

/// @nodoc
class _$LowStockMaterialSummaryCopyWithImpl<$Res,
        $Val extends LowStockMaterialSummary>
    implements $LowStockMaterialSummaryCopyWith<$Res> {
  _$LowStockMaterialSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LowStockMaterialSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? currentStock = null,
    Object? unit = null,
    Object? minimumStock = null,
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
      currentStock: null == currentStock
          ? _value.currentStock
          : currentStock // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      minimumStock: null == minimumStock
          ? _value.minimumStock
          : minimumStock // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LowStockMaterialSummaryImplCopyWith<$Res>
    implements $LowStockMaterialSummaryCopyWith<$Res> {
  factory _$$LowStockMaterialSummaryImplCopyWith(
          _$LowStockMaterialSummaryImpl value,
          $Res Function(_$LowStockMaterialSummaryImpl) then) =
      __$$LowStockMaterialSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      double currentStock,
      String unit,
      double minimumStock});
}

/// @nodoc
class __$$LowStockMaterialSummaryImplCopyWithImpl<$Res>
    extends _$LowStockMaterialSummaryCopyWithImpl<$Res,
        _$LowStockMaterialSummaryImpl>
    implements _$$LowStockMaterialSummaryImplCopyWith<$Res> {
  __$$LowStockMaterialSummaryImplCopyWithImpl(
      _$LowStockMaterialSummaryImpl _value,
      $Res Function(_$LowStockMaterialSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of LowStockMaterialSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? currentStock = null,
    Object? unit = null,
    Object? minimumStock = null,
  }) {
    return _then(_$LowStockMaterialSummaryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      currentStock: null == currentStock
          ? _value.currentStock
          : currentStock // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      minimumStock: null == minimumStock
          ? _value.minimumStock
          : minimumStock // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LowStockMaterialSummaryImpl implements _LowStockMaterialSummary {
  const _$LowStockMaterialSummaryImpl(
      {required this.id,
      required this.name,
      required this.currentStock,
      required this.unit,
      required this.minimumStock});

  factory _$LowStockMaterialSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$LowStockMaterialSummaryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double currentStock;
  @override
  final String unit;
  @override
  final double minimumStock;

  @override
  String toString() {
    return 'LowStockMaterialSummary(id: $id, name: $name, currentStock: $currentStock, unit: $unit, minimumStock: $minimumStock)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LowStockMaterialSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.currentStock, currentStock) ||
                other.currentStock == currentStock) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.minimumStock, minimumStock) ||
                other.minimumStock == minimumStock));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, currentStock, unit, minimumStock);

  /// Create a copy of LowStockMaterialSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LowStockMaterialSummaryImplCopyWith<_$LowStockMaterialSummaryImpl>
      get copyWith => __$$LowStockMaterialSummaryImplCopyWithImpl<
          _$LowStockMaterialSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LowStockMaterialSummaryImplToJson(
      this,
    );
  }
}

abstract class _LowStockMaterialSummary implements LowStockMaterialSummary {
  const factory _LowStockMaterialSummary(
      {required final String id,
      required final String name,
      required final double currentStock,
      required final String unit,
      required final double minimumStock}) = _$LowStockMaterialSummaryImpl;

  factory _LowStockMaterialSummary.fromJson(Map<String, dynamic> json) =
      _$LowStockMaterialSummaryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get currentStock;
  @override
  String get unit;
  @override
  double get minimumStock;

  /// Create a copy of LowStockMaterialSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LowStockMaterialSummaryImplCopyWith<_$LowStockMaterialSummaryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

DashboardSummary _$DashboardSummaryFromJson(Map<String, dynamic> json) {
  return _DashboardSummary.fromJson(json);
}

/// @nodoc
mixin _$DashboardSummary {
  int get unpaidInvoiceCount => throw _privateConstructorUsedError;
  int get totalDebtCents => throw _privateConstructorUsedError;
  int get revenueTodayCents => throw _privateConstructorUsedError;
  int get revenueMonthCents => throw _privateConstructorUsedError;
  int get materialCount => throw _privateConstructorUsedError;
  int get lowStockCount => throw _privateConstructorUsedError;
  int get totalStockValueCents => throw _privateConstructorUsedError;
  List<OverdueInvoice> get overdueInvoices =>
      throw _privateConstructorUsedError;
  List<LowStockMaterialSummary> get lowStockMaterials =>
      throw _privateConstructorUsedError;

  /// Serializes this DashboardSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardSummaryCopyWith<DashboardSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardSummaryCopyWith<$Res> {
  factory $DashboardSummaryCopyWith(
          DashboardSummary value, $Res Function(DashboardSummary) then) =
      _$DashboardSummaryCopyWithImpl<$Res, DashboardSummary>;
  @useResult
  $Res call(
      {int unpaidInvoiceCount,
      int totalDebtCents,
      int revenueTodayCents,
      int revenueMonthCents,
      int materialCount,
      int lowStockCount,
      int totalStockValueCents,
      List<OverdueInvoice> overdueInvoices,
      List<LowStockMaterialSummary> lowStockMaterials});
}

/// @nodoc
class _$DashboardSummaryCopyWithImpl<$Res, $Val extends DashboardSummary>
    implements $DashboardSummaryCopyWith<$Res> {
  _$DashboardSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unpaidInvoiceCount = null,
    Object? totalDebtCents = null,
    Object? revenueTodayCents = null,
    Object? revenueMonthCents = null,
    Object? materialCount = null,
    Object? lowStockCount = null,
    Object? totalStockValueCents = null,
    Object? overdueInvoices = null,
    Object? lowStockMaterials = null,
  }) {
    return _then(_value.copyWith(
      unpaidInvoiceCount: null == unpaidInvoiceCount
          ? _value.unpaidInvoiceCount
          : unpaidInvoiceCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalDebtCents: null == totalDebtCents
          ? _value.totalDebtCents
          : totalDebtCents // ignore: cast_nullable_to_non_nullable
              as int,
      revenueTodayCents: null == revenueTodayCents
          ? _value.revenueTodayCents
          : revenueTodayCents // ignore: cast_nullable_to_non_nullable
              as int,
      revenueMonthCents: null == revenueMonthCents
          ? _value.revenueMonthCents
          : revenueMonthCents // ignore: cast_nullable_to_non_nullable
              as int,
      materialCount: null == materialCount
          ? _value.materialCount
          : materialCount // ignore: cast_nullable_to_non_nullable
              as int,
      lowStockCount: null == lowStockCount
          ? _value.lowStockCount
          : lowStockCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalStockValueCents: null == totalStockValueCents
          ? _value.totalStockValueCents
          : totalStockValueCents // ignore: cast_nullable_to_non_nullable
              as int,
      overdueInvoices: null == overdueInvoices
          ? _value.overdueInvoices
          : overdueInvoices // ignore: cast_nullable_to_non_nullable
              as List<OverdueInvoice>,
      lowStockMaterials: null == lowStockMaterials
          ? _value.lowStockMaterials
          : lowStockMaterials // ignore: cast_nullable_to_non_nullable
              as List<LowStockMaterialSummary>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DashboardSummaryImplCopyWith<$Res>
    implements $DashboardSummaryCopyWith<$Res> {
  factory _$$DashboardSummaryImplCopyWith(_$DashboardSummaryImpl value,
          $Res Function(_$DashboardSummaryImpl) then) =
      __$$DashboardSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int unpaidInvoiceCount,
      int totalDebtCents,
      int revenueTodayCents,
      int revenueMonthCents,
      int materialCount,
      int lowStockCount,
      int totalStockValueCents,
      List<OverdueInvoice> overdueInvoices,
      List<LowStockMaterialSummary> lowStockMaterials});
}

/// @nodoc
class __$$DashboardSummaryImplCopyWithImpl<$Res>
    extends _$DashboardSummaryCopyWithImpl<$Res, _$DashboardSummaryImpl>
    implements _$$DashboardSummaryImplCopyWith<$Res> {
  __$$DashboardSummaryImplCopyWithImpl(_$DashboardSummaryImpl _value,
      $Res Function(_$DashboardSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unpaidInvoiceCount = null,
    Object? totalDebtCents = null,
    Object? revenueTodayCents = null,
    Object? revenueMonthCents = null,
    Object? materialCount = null,
    Object? lowStockCount = null,
    Object? totalStockValueCents = null,
    Object? overdueInvoices = null,
    Object? lowStockMaterials = null,
  }) {
    return _then(_$DashboardSummaryImpl(
      unpaidInvoiceCount: null == unpaidInvoiceCount
          ? _value.unpaidInvoiceCount
          : unpaidInvoiceCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalDebtCents: null == totalDebtCents
          ? _value.totalDebtCents
          : totalDebtCents // ignore: cast_nullable_to_non_nullable
              as int,
      revenueTodayCents: null == revenueTodayCents
          ? _value.revenueTodayCents
          : revenueTodayCents // ignore: cast_nullable_to_non_nullable
              as int,
      revenueMonthCents: null == revenueMonthCents
          ? _value.revenueMonthCents
          : revenueMonthCents // ignore: cast_nullable_to_non_nullable
              as int,
      materialCount: null == materialCount
          ? _value.materialCount
          : materialCount // ignore: cast_nullable_to_non_nullable
              as int,
      lowStockCount: null == lowStockCount
          ? _value.lowStockCount
          : lowStockCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalStockValueCents: null == totalStockValueCents
          ? _value.totalStockValueCents
          : totalStockValueCents // ignore: cast_nullable_to_non_nullable
              as int,
      overdueInvoices: null == overdueInvoices
          ? _value._overdueInvoices
          : overdueInvoices // ignore: cast_nullable_to_non_nullable
              as List<OverdueInvoice>,
      lowStockMaterials: null == lowStockMaterials
          ? _value._lowStockMaterials
          : lowStockMaterials // ignore: cast_nullable_to_non_nullable
              as List<LowStockMaterialSummary>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardSummaryImpl implements _DashboardSummary {
  const _$DashboardSummaryImpl(
      {this.unpaidInvoiceCount = 0,
      this.totalDebtCents = 0,
      this.revenueTodayCents = 0,
      this.revenueMonthCents = 0,
      this.materialCount = 0,
      this.lowStockCount = 0,
      this.totalStockValueCents = 0,
      final List<OverdueInvoice> overdueInvoices = const [],
      final List<LowStockMaterialSummary> lowStockMaterials = const []})
      : _overdueInvoices = overdueInvoices,
        _lowStockMaterials = lowStockMaterials;

  factory _$DashboardSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardSummaryImplFromJson(json);

  @override
  @JsonKey()
  final int unpaidInvoiceCount;
  @override
  @JsonKey()
  final int totalDebtCents;
  @override
  @JsonKey()
  final int revenueTodayCents;
  @override
  @JsonKey()
  final int revenueMonthCents;
  @override
  @JsonKey()
  final int materialCount;
  @override
  @JsonKey()
  final int lowStockCount;
  @override
  @JsonKey()
  final int totalStockValueCents;
  final List<OverdueInvoice> _overdueInvoices;
  @override
  @JsonKey()
  List<OverdueInvoice> get overdueInvoices {
    if (_overdueInvoices is EqualUnmodifiableListView) return _overdueInvoices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_overdueInvoices);
  }

  final List<LowStockMaterialSummary> _lowStockMaterials;
  @override
  @JsonKey()
  List<LowStockMaterialSummary> get lowStockMaterials {
    if (_lowStockMaterials is EqualUnmodifiableListView)
      return _lowStockMaterials;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lowStockMaterials);
  }

  @override
  String toString() {
    return 'DashboardSummary(unpaidInvoiceCount: $unpaidInvoiceCount, totalDebtCents: $totalDebtCents, revenueTodayCents: $revenueTodayCents, revenueMonthCents: $revenueMonthCents, materialCount: $materialCount, lowStockCount: $lowStockCount, totalStockValueCents: $totalStockValueCents, overdueInvoices: $overdueInvoices, lowStockMaterials: $lowStockMaterials)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardSummaryImpl &&
            (identical(other.unpaidInvoiceCount, unpaidInvoiceCount) ||
                other.unpaidInvoiceCount == unpaidInvoiceCount) &&
            (identical(other.totalDebtCents, totalDebtCents) ||
                other.totalDebtCents == totalDebtCents) &&
            (identical(other.revenueTodayCents, revenueTodayCents) ||
                other.revenueTodayCents == revenueTodayCents) &&
            (identical(other.revenueMonthCents, revenueMonthCents) ||
                other.revenueMonthCents == revenueMonthCents) &&
            (identical(other.materialCount, materialCount) ||
                other.materialCount == materialCount) &&
            (identical(other.lowStockCount, lowStockCount) ||
                other.lowStockCount == lowStockCount) &&
            (identical(other.totalStockValueCents, totalStockValueCents) ||
                other.totalStockValueCents == totalStockValueCents) &&
            const DeepCollectionEquality()
                .equals(other._overdueInvoices, _overdueInvoices) &&
            const DeepCollectionEquality()
                .equals(other._lowStockMaterials, _lowStockMaterials));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      unpaidInvoiceCount,
      totalDebtCents,
      revenueTodayCents,
      revenueMonthCents,
      materialCount,
      lowStockCount,
      totalStockValueCents,
      const DeepCollectionEquality().hash(_overdueInvoices),
      const DeepCollectionEquality().hash(_lowStockMaterials));

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardSummaryImplCopyWith<_$DashboardSummaryImpl> get copyWith =>
      __$$DashboardSummaryImplCopyWithImpl<_$DashboardSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardSummaryImplToJson(
      this,
    );
  }
}

abstract class _DashboardSummary implements DashboardSummary {
  const factory _DashboardSummary(
          {final int unpaidInvoiceCount,
          final int totalDebtCents,
          final int revenueTodayCents,
          final int revenueMonthCents,
          final int materialCount,
          final int lowStockCount,
          final int totalStockValueCents,
          final List<OverdueInvoice> overdueInvoices,
          final List<LowStockMaterialSummary> lowStockMaterials}) =
      _$DashboardSummaryImpl;

  factory _DashboardSummary.fromJson(Map<String, dynamic> json) =
      _$DashboardSummaryImpl.fromJson;

  @override
  int get unpaidInvoiceCount;
  @override
  int get totalDebtCents;
  @override
  int get revenueTodayCents;
  @override
  int get revenueMonthCents;
  @override
  int get materialCount;
  @override
  int get lowStockCount;
  @override
  int get totalStockValueCents;
  @override
  List<OverdueInvoice> get overdueInvoices;
  @override
  List<LowStockMaterialSummary> get lowStockMaterials;

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardSummaryImplCopyWith<_$DashboardSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

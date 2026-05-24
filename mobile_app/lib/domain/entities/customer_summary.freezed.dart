// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CustomerSummary _$CustomerSummaryFromJson(Map<String, dynamic> json) {
  return _CustomerSummary.fromJson(json);
}

/// @nodoc
mixin _$CustomerSummary {
  String get customerId => throw _privateConstructorUsedError;
  int get totalDebtCents => throw _privateConstructorUsedError;
  int get invoiceCount => throw _privateConstructorUsedError;
  int get paymentCount => throw _privateConstructorUsedError;
  List<Invoice> get invoices => throw _privateConstructorUsedError;
  List<Payment> get payments => throw _privateConstructorUsedError;

  /// Serializes this CustomerSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerSummaryCopyWith<CustomerSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerSummaryCopyWith<$Res> {
  factory $CustomerSummaryCopyWith(
          CustomerSummary value, $Res Function(CustomerSummary) then) =
      _$CustomerSummaryCopyWithImpl<$Res, CustomerSummary>;
  @useResult
  $Res call(
      {String customerId,
      int totalDebtCents,
      int invoiceCount,
      int paymentCount,
      List<Invoice> invoices,
      List<Payment> payments});
}

/// @nodoc
class _$CustomerSummaryCopyWithImpl<$Res, $Val extends CustomerSummary>
    implements $CustomerSummaryCopyWith<$Res> {
  _$CustomerSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerId = null,
    Object? totalDebtCents = null,
    Object? invoiceCount = null,
    Object? paymentCount = null,
    Object? invoices = null,
    Object? payments = null,
  }) {
    return _then(_value.copyWith(
      customerId: null == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      totalDebtCents: null == totalDebtCents
          ? _value.totalDebtCents
          : totalDebtCents // ignore: cast_nullable_to_non_nullable
              as int,
      invoiceCount: null == invoiceCount
          ? _value.invoiceCount
          : invoiceCount // ignore: cast_nullable_to_non_nullable
              as int,
      paymentCount: null == paymentCount
          ? _value.paymentCount
          : paymentCount // ignore: cast_nullable_to_non_nullable
              as int,
      invoices: null == invoices
          ? _value.invoices
          : invoices // ignore: cast_nullable_to_non_nullable
              as List<Invoice>,
      payments: null == payments
          ? _value.payments
          : payments // ignore: cast_nullable_to_non_nullable
              as List<Payment>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CustomerSummaryImplCopyWith<$Res>
    implements $CustomerSummaryCopyWith<$Res> {
  factory _$$CustomerSummaryImplCopyWith(_$CustomerSummaryImpl value,
          $Res Function(_$CustomerSummaryImpl) then) =
      __$$CustomerSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String customerId,
      int totalDebtCents,
      int invoiceCount,
      int paymentCount,
      List<Invoice> invoices,
      List<Payment> payments});
}

/// @nodoc
class __$$CustomerSummaryImplCopyWithImpl<$Res>
    extends _$CustomerSummaryCopyWithImpl<$Res, _$CustomerSummaryImpl>
    implements _$$CustomerSummaryImplCopyWith<$Res> {
  __$$CustomerSummaryImplCopyWithImpl(
      _$CustomerSummaryImpl _value, $Res Function(_$CustomerSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of CustomerSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerId = null,
    Object? totalDebtCents = null,
    Object? invoiceCount = null,
    Object? paymentCount = null,
    Object? invoices = null,
    Object? payments = null,
  }) {
    return _then(_$CustomerSummaryImpl(
      customerId: null == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      totalDebtCents: null == totalDebtCents
          ? _value.totalDebtCents
          : totalDebtCents // ignore: cast_nullable_to_non_nullable
              as int,
      invoiceCount: null == invoiceCount
          ? _value.invoiceCount
          : invoiceCount // ignore: cast_nullable_to_non_nullable
              as int,
      paymentCount: null == paymentCount
          ? _value.paymentCount
          : paymentCount // ignore: cast_nullable_to_non_nullable
              as int,
      invoices: null == invoices
          ? _value._invoices
          : invoices // ignore: cast_nullable_to_non_nullable
              as List<Invoice>,
      payments: null == payments
          ? _value._payments
          : payments // ignore: cast_nullable_to_non_nullable
              as List<Payment>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerSummaryImpl implements _CustomerSummary {
  const _$CustomerSummaryImpl(
      {required this.customerId,
      this.totalDebtCents = 0,
      this.invoiceCount = 0,
      this.paymentCount = 0,
      final List<Invoice> invoices = const [],
      final List<Payment> payments = const []})
      : _invoices = invoices,
        _payments = payments;

  factory _$CustomerSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerSummaryImplFromJson(json);

  @override
  final String customerId;
  @override
  @JsonKey()
  final int totalDebtCents;
  @override
  @JsonKey()
  final int invoiceCount;
  @override
  @JsonKey()
  final int paymentCount;
  final List<Invoice> _invoices;
  @override
  @JsonKey()
  List<Invoice> get invoices {
    if (_invoices is EqualUnmodifiableListView) return _invoices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_invoices);
  }

  final List<Payment> _payments;
  @override
  @JsonKey()
  List<Payment> get payments {
    if (_payments is EqualUnmodifiableListView) return _payments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_payments);
  }

  @override
  String toString() {
    return 'CustomerSummary(customerId: $customerId, totalDebtCents: $totalDebtCents, invoiceCount: $invoiceCount, paymentCount: $paymentCount, invoices: $invoices, payments: $payments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerSummaryImpl &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.totalDebtCents, totalDebtCents) ||
                other.totalDebtCents == totalDebtCents) &&
            (identical(other.invoiceCount, invoiceCount) ||
                other.invoiceCount == invoiceCount) &&
            (identical(other.paymentCount, paymentCount) ||
                other.paymentCount == paymentCount) &&
            const DeepCollectionEquality().equals(other._invoices, _invoices) &&
            const DeepCollectionEquality().equals(other._payments, _payments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      customerId,
      totalDebtCents,
      invoiceCount,
      paymentCount,
      const DeepCollectionEquality().hash(_invoices),
      const DeepCollectionEquality().hash(_payments));

  /// Create a copy of CustomerSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerSummaryImplCopyWith<_$CustomerSummaryImpl> get copyWith =>
      __$$CustomerSummaryImplCopyWithImpl<_$CustomerSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerSummaryImplToJson(
      this,
    );
  }
}

abstract class _CustomerSummary implements CustomerSummary {
  const factory _CustomerSummary(
      {required final String customerId,
      final int totalDebtCents,
      final int invoiceCount,
      final int paymentCount,
      final List<Invoice> invoices,
      final List<Payment> payments}) = _$CustomerSummaryImpl;

  factory _CustomerSummary.fromJson(Map<String, dynamic> json) =
      _$CustomerSummaryImpl.fromJson;

  @override
  String get customerId;
  @override
  int get totalDebtCents;
  @override
  int get invoiceCount;
  @override
  int get paymentCount;
  @override
  List<Invoice> get invoices;
  @override
  List<Payment> get payments;

  /// Create a copy of CustomerSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerSummaryImplCopyWith<_$CustomerSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

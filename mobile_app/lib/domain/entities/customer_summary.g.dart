// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomerSummaryImpl _$$CustomerSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$CustomerSummaryImpl(
      customerId: json['customerId'] as String,
      totalDebtCents: (json['totalDebtCents'] as num?)?.toInt() ?? 0,
      invoiceCount: (json['invoiceCount'] as num?)?.toInt() ?? 0,
      paymentCount: (json['paymentCount'] as num?)?.toInt() ?? 0,
      invoices: (json['invoices'] as List<dynamic>?)
              ?.map((e) => Invoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$CustomerSummaryImplToJson(
        _$CustomerSummaryImpl instance) =>
    <String, dynamic>{
      'customerId': instance.customerId,
      'totalDebtCents': instance.totalDebtCents,
      'invoiceCount': instance.invoiceCount,
      'paymentCount': instance.paymentCount,
      'invoices': instance.invoices.map((e) => e.toJson()).toList(),
      'payments': instance.payments.map((e) => e.toJson()).toList(),
    };

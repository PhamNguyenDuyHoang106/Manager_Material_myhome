// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DashboardSummaryImpl _$$DashboardSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$DashboardSummaryImpl(
      unpaidInvoiceCount: (json['unpaidInvoiceCount'] as num?)?.toInt() ?? 0,
      totalDebtCents: (json['totalDebtCents'] as num?)?.toInt() ?? 0,
      revenueTodayCents: (json['revenueTodayCents'] as num?)?.toInt() ?? 0,
      revenueMonthCents: (json['revenueMonthCents'] as num?)?.toInt() ?? 0,
      materialCount: (json['materialCount'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      totalStockValueCents:
          (json['totalStockValueCents'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$DashboardSummaryImplToJson(
        _$DashboardSummaryImpl instance) =>
    <String, dynamic>{
      'unpaidInvoiceCount': instance.unpaidInvoiceCount,
      'totalDebtCents': instance.totalDebtCents,
      'revenueTodayCents': instance.revenueTodayCents,
      'revenueMonthCents': instance.revenueMonthCents,
      'materialCount': instance.materialCount,
      'lowStockCount': instance.lowStockCount,
      'totalStockValueCents': instance.totalStockValueCents,
    };

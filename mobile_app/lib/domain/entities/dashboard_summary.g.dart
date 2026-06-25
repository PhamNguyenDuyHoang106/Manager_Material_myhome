// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OverdueInvoiceImpl _$$OverdueInvoiceImplFromJson(Map<String, dynamic> json) =>
    _$OverdueInvoiceImpl(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      invoiceDate: json['invoiceDate'] as String,
      remainingCents: (json['remainingCents'] as num).toInt(),
    );

Map<String, dynamic> _$$OverdueInvoiceImplToJson(
        _$OverdueInvoiceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerId': instance.customerId,
      'customerName': instance.customerName,
      'invoiceDate': instance.invoiceDate,
      'remainingCents': instance.remainingCents,
    };

_$LowStockMaterialSummaryImpl _$$LowStockMaterialSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$LowStockMaterialSummaryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      currentStock: (json['currentStock'] as num).toDouble(),
      unit: json['unit'] as String,
      minimumStock: (json['minimumStock'] as num).toDouble(),
    );

Map<String, dynamic> _$$LowStockMaterialSummaryImplToJson(
        _$LowStockMaterialSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'currentStock': instance.currentStock,
      'unit': instance.unit,
      'minimumStock': instance.minimumStock,
    };

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
      overdueInvoices: (json['overdueInvoices'] as List<dynamic>?)
              ?.map((e) => OverdueInvoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lowStockMaterials: (json['lowStockMaterials'] as List<dynamic>?)
              ?.map((e) =>
                  LowStockMaterialSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
      'overdueInvoices':
          instance.overdueInvoices.map((e) => e.toJson()).toList(),
      'lowStockMaterials':
          instance.lowStockMaterials.map((e) => e.toJson()).toList(),
    };

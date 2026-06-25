import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_summary.freezed.dart';
part 'dashboard_summary.g.dart';

@freezed
class OverdueInvoice with _$OverdueInvoice {
  const factory OverdueInvoice({
    required String id,
    required String customerId,
    required String customerName,
    required String invoiceDate,
    required int remainingCents,
  }) = _OverdueInvoice;

  factory OverdueInvoice.fromJson(Map<String, dynamic> json) =>
      _$OverdueInvoiceFromJson(json);
}

@freezed
class LowStockMaterialSummary with _$LowStockMaterialSummary {
  const factory LowStockMaterialSummary({
    required String id,
    required String name,
    required double currentStock,
    required String unit,
    required double minimumStock,
  }) = _LowStockMaterialSummary;

  factory LowStockMaterialSummary.fromJson(Map<String, dynamic> json) =>
      _$LowStockMaterialSummaryFromJson(json);
}

@freezed
class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    @Default(0) int unpaidInvoiceCount,
    @Default(0) int totalDebtCents,
    @Default(0) int revenueTodayCents,
    @Default(0) int revenueMonthCents,
    @Default(0) int materialCount,
    @Default(0) int lowStockCount,
    @Default(0) int totalStockValueCents,
    @Default([]) List<OverdueInvoice> overdueInvoices,
    @Default([]) List<LowStockMaterialSummary> lowStockMaterials,
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}

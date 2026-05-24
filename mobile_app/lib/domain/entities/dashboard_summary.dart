import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_summary.freezed.dart';
part 'dashboard_summary.g.dart';

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
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}

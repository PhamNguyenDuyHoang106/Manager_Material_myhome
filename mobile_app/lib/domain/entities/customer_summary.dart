import 'package:freezed_annotation/freezed_annotation.dart';
import 'payment.dart';
import 'invoice.dart';

part 'customer_summary.freezed.dart';
part 'customer_summary.g.dart';

@freezed
class CustomerSummary with _$CustomerSummary {
  const factory CustomerSummary({
    required String customerId,
    @Default(0) int totalDebtCents,
    @Default(0) int invoiceCount,
    @Default(0) int paymentCount,
    @Default([]) List<Invoice> invoices,
    @Default([]) List<Payment> payments,
  }) = _CustomerSummary;

  factory CustomerSummary.fromJson(Map<String, dynamic> json) =>
      _$CustomerSummaryFromJson(json);
}

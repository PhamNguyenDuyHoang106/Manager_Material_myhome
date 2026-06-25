import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_ledger_entry.freezed.dart';
part 'customer_ledger_entry.g.dart';

@JsonEnum(alwaysCreate: true)
enum LedgerEntryType {
  sale,
  payment,
  cancellation,
  paymentReversal,
}

@freezed
class LedgerItemSnapshot with _$LedgerItemSnapshot {
  const factory LedgerItemSnapshot({
    required String materialId,
    required String materialName,
    required double quantity,
    required String unit,
    required int sellingPriceCents,
    required int lineTotalCents,
  }) = _LedgerItemSnapshot;

  factory LedgerItemSnapshot.fromJson(Map<String, dynamic> json) => _$LedgerItemSnapshotFromJson(json);
}

@freezed
class CustomerLedgerEntry with _$CustomerLedgerEntry {
  const factory CustomerLedgerEntry({
    required String id,
    required String customerId,
    String? invoiceId,
    String? paymentId,
    required DateTime date,
    required LedgerEntryType type,
    required String description,
    required int amountCents,
    required DateTime createdAt,
    String? attachmentUrl,
    @Default([]) List<LedgerItemSnapshot> items,
  }) = _CustomerLedgerEntry;

  factory CustomerLedgerEntry.fromJson(Map<String, dynamic> json) => _$CustomerLedgerEntryFromJson(json);
}

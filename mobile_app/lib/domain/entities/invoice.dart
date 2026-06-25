import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'invoice.freezed.dart';
part 'invoice.g.dart';

@JsonEnum(alwaysCreate: true)
enum InvoiceStatus {
  unpaid,
  partiallyPaid,
  paid,
  cancelled,
}

@freezed
class InvoiceItem with _$InvoiceItem {
  const factory InvoiceItem({
    required String id,
    required String materialId,
    required String materialName,
    required String unit,
    required double quantity,
    @JsonKey(name: 'sellingPriceCents') required int sellingPriceCents,
    @JsonKey(name: 'lineTotalCents') required int lineTotalCents,
  }) = _InvoiceItem;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => _$InvoiceItemFromJson(json);
}

@freezed
class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    required String customerId,
    required String customerName,
    required DateTime invoiceDate,
    @JsonKey(name: 'totalAmountCents') required int totalAmountCents,
    @JsonKey(name: 'paidAmountCents') @Default(0) int paidAmountCents,
    @InvoiceStatusConverter() required InvoiceStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<InvoiceItem> items,
    @Default('') String deliveryAddress,
    @Default('') String deliveryNote,
    @Default(false) bool isDeleted,
    DateTime? deletedAt,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
}

extension InvoiceX on Invoice {
  int get remainingCents => totalAmountCents - paidAmountCents;
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'inventory_transaction.freezed.dart';
part 'inventory_transaction.g.dart';

@JsonEnum(alwaysCreate: true)
enum InventoryTxType {
  import,
  invoiceDeduct,
  invoiceRollback,
  adjustment,
}

@freezed
class InventoryTransaction with _$InventoryTransaction {
  const factory InventoryTransaction({
    required String id,
    required String materialId,
    required String materialName,
    @InventoryTxTypeConverter() required InventoryTxType type,
    required double quantity,
    required double stockAfter,
    String? referenceId,
    String? note,
    required String createdAt,
  }) = _InventoryTransaction;

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) =>
      _$InventoryTransactionFromJson(json);
}

import '../entities/inventory_transaction.dart';

abstract class InventoryRepository {
  Stream<List<InventoryTransaction>> watchTransactions({String? materialId});
  Future<void> addStock({
    required String materialId,
    required double quantity,
    required int importPriceCents,
    String? note,
  });
  Future<void> adjustStock({
    required String materialId,
    required double quantityDelta,
    required String note,
  });
}

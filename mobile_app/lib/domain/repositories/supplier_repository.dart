import '../entities/supplier.dart';
import '../entities/supplier_ledger_entry.dart';

abstract class SupplierRepository {
  Stream<List<Supplier>> watchSuppliers({String? query});
  Future<Supplier?> getSupplier(String id);
  Future<String> createSupplier({
    required String name,
    String phone = '',
    String address = '',
    String note = '',
    List<String> materialIds = const [],
  });
  Future<void> updateSupplier({
    required String id,
    required String name,
    String phone = '',
    String address = '',
    String note = '',
    List<String>? materialIds,
  });
  Future<void> deleteSupplier(String id);

  // Ledger
  Stream<List<SupplierLedgerEntry>> watchLedger(String supplierId);
  Future<void> createImportInvoice({
    required String supplierId,
    required String supplierName,
    required DateTime date,
    required List<SupplierLedgerItem> items,
    required int paidAmountCents,
    String note = '',
    int adjustCents = 0,      // điều chỉnh công nợ: + = nợ cũ, - = đặt cọc
    String adjustNote = '',
  });
  Future<void> recordPayment({
    required String supplierId,
    required String supplierName,
    required int amountCents,
    required DateTime date,
    String note = '',
  });
  Future<void> recordAdjustment({
    required String supplierId,
    required String supplierName,
    required int amountCents, // positive = add debt (nợ cũ), negative = reduce (đặt cọc)
    required DateTime date,
    String note = '',
  });
  Future<void> cancelLedgerEntry({
    required String supplierId,
    required SupplierLedgerEntry entry,
  });
}

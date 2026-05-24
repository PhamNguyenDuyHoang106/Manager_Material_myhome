import '../entities/invoice.dart';

abstract class InvoiceRepository {
  Stream<List<Invoice>> watchInvoices({String query = ''});
  Future<List<Invoice>> getInvoices({String query = ''});
  Future<Invoice?> getInvoice(String id);
  Future<String> createInvoice({
    required String customerId,
    required String invoiceDate,
    required List<InvoiceItemInput> items,
  });
  Future<void> updateInvoice({
    required String invoiceId,
    required String customerId,
    required String invoiceDate,
    required List<InvoiceItemInput> items,
  });
  Future<void> deleteInvoice(String invoiceId);
}

class InvoiceItemInput {
  const InvoiceItemInput({
    this.id,
    required this.materialId,
    required this.quantity,
    required this.sellingPriceCents,
  });

  final String? id;
  final String materialId;
  final double quantity;
  final int sellingPriceCents;
}

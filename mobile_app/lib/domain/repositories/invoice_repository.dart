import '../entities/invoice.dart';

abstract class InvoiceRepository {
  Stream<List<Invoice>> watchInvoices({String query = ''});
  Future<List<Invoice>> getInvoices({String query = ''});
  Future<Invoice?> getInvoice(String id);
  Future<String> createInvoice({
    required String customerId,
    required DateTime invoiceDate,
    required List<InvoiceItemInput> items,
    required String deliveryAddress,
    required String deliveryNote,
  });
  Future<void> updateInvoice({
    required String invoiceId,
    required String customerId,
    required DateTime invoiceDate,
    required List<InvoiceItemInput> items,
    required String deliveryAddress,
    required String deliveryNote,
  });
  Future<void> cancelInvoice(String invoiceId);
  Future<void> deleteInvoice(String id);
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

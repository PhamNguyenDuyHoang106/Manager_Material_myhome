import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<void> addPayment({
    required String invoiceId,
    required String customerId,
    required int amountCents,
    required DateTime paymentDate,
    String? attachmentUrl,
  });
  Future<List<Payment>> getPaymentsForCustomer(String customerId);
  Future<List<Payment>> getPaymentsForInvoice(String invoiceId);
  Future<void> deletePayment(String id);
}

import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<void> addPayment({
    required String invoiceId,
    required String customerId,
    required int amountCents,
    required String paymentDate,
  });
  Future<List<Payment>> getPaymentsForCustomer(String customerId);
  Future<List<Payment>> getPaymentsForInvoice(String invoiceId);
}

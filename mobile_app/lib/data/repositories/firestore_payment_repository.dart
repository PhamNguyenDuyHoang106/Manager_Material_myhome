import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/firestore_paths.dart';
import '../mappers/firestore_mapper.dart';

class FirestorePaymentRepository implements PaymentRepository {
  FirestorePaymentRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;
  final _uuid = const Uuid();

  FirestorePaths get _paths => FirestorePaths(_uid);

  String _statusToString(InvoiceStatus s) => switch (s) {
        InvoiceStatus.unpaid => 'unpaid',
        InvoiceStatus.partiallyPaid => 'partially_paid',
        InvoiceStatus.paid => 'paid',
      };

  @override
  Future<void> addPayment({
    required String invoiceId,
    required String customerId,
    required int amountCents,
    required String paymentDate,
  }) async {
    if (amountCents <= 0) throw const ValidationException('Số tiền phải lớn hơn 0');

    await _firestore.runTransaction((txn) async {
      final invoiceRef = _firestore.collection(_paths.invoices).doc(invoiceId);
      final invoiceSnap = await txn.get(invoiceRef);
      if (!invoiceSnap.exists) throw const ValidationException('Hóa đơn không tồn tại');

      final total = invoiceSnap.data()!['totalAmountCents'] as int;
      final paid = invoiceSnap.data()!['paidAmountCents'] as int? ?? 0;
      final remaining = total - paid;
      if (amountCents > remaining) {
        throw ValidationException('Vượt quá số nợ còn lại (${remaining / 100})');
      }

      final newPaid = paid + amountCents;
      final status = newPaid >= total
          ? InvoiceStatus.paid
          : newPaid > 0
              ? InvoiceStatus.partiallyPaid
              : InvoiceStatus.unpaid;

      txn.set(_firestore.collection(_paths.payments).doc(_uuid.v4()), {
        'invoiceId': invoiceId,
        'customerId': customerId,
        'amountCents': amountCents,
        'paymentDate': paymentDate,
        'createdAt': DateTime.now().toIso8601String(),
      });

      txn.update(invoiceRef, {
        'paidAmountCents': newPaid,
        'status': _statusToString(status),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  @override
  Future<List<Payment>> getPaymentsForCustomer(String customerId) async {
    final snap = await _firestore
        .collection(_paths.payments)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Payment.fromJson(fromFirestore(d))).toList();
  }

  @override
  Future<List<Payment>> getPaymentsForInvoice(String invoiceId) async {
    final snap = await _firestore
        .collection(_paths.payments)
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Payment.fromJson(fromFirestore(d))).toList();
  }
}

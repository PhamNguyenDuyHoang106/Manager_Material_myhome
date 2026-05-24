import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_summary.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/firestore_paths.dart';
import '../datasources/hive_cache.dart';
import '../mappers/firestore_mapper.dart';

class FirestoreCustomerRepository implements CustomerRepository {
  FirestoreCustomerRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;
  final _uuid = const Uuid();

  FirestorePaths get _paths => FirestorePaths(_uid);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_paths.customers);

  @override
  Stream<List<Customer>> watchCustomers() {
    return _col.where('isDeleted', isEqualTo: false).orderBy('createdAt', descending: true).snapshots().map(
      (snap) {
        final list = snap.docs.map((d) => Customer.fromJson(fromFirestore(d))).toList();
        _cacheCustomers(list);
        return list;
      },
    );
  }

  @override
  Future<List<Customer>> getCustomers({String query = ''}) async {
    try {
      final snap = await _col.where('isDeleted', isEqualTo: false).orderBy('createdAt', descending: true).get();
      var list = snap.docs.map((d) => Customer.fromJson(fromFirestore(d))).toList();
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        list = list.where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q)).toList();
      }
      _cacheCustomers(list);
      return list;
    } catch (_) {
      final cached = HiveCache.instance.loadList(HiveCache.instance.customersBox);
      if (cached == null) rethrow;
      var list = cached.map(Customer.fromJson).toList();
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        list = list.where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q)).toList();
      }
      return list;
    }
  }

  void _cacheCustomers(List<Customer> list) {
    HiveCache.instance.saveList(
      HiveCache.instance.customersBox,
      list.map((c) => c.toJson()).toList(),
    );
  }

  @override
  Future<void> createCustomer({
    required String name,
    required String phone,
    required String address,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();
    await _col.doc(id).set({
      'name': name,
      'phone': phone,
      'address': address,
      'isDeleted': false,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    await _col.doc(customer.id).update({
      'name': customer.name,
      'phone': customer.phone,
      'address': customer.address,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _col.doc(id).update({
      'isDeleted': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<CustomerSummary> getCustomerSummary(String customerId) async {
    final invoicesSnap = await _firestore
        .collection(_paths.invoices)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();

    final paymentsSnap = await _firestore
        .collection(_paths.payments)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();

    final invoices = <Invoice>[];
    for (final doc in invoicesSnap.docs) {
      final data = fromFirestore(doc);
      final itemsSnap = await _firestore.collection(_paths.invoiceItems(doc.id)).get();
      final items = itemsSnap.docs.map((i) => InvoiceItem.fromJson(fromFirestore(i))).toList();
      invoices.add(Invoice.fromJson({...data, 'items': items.map((e) => e.toJson()).toList()}));
    }

    final payments = paymentsSnap.docs.map((d) => Payment.fromJson(fromFirestore(d))).toList();
    final totalInvoiced = invoices.fold<int>(0, (s, i) => s + i.totalAmountCents);
    final totalPaid = payments.fold<int>(0, (s, p) => s + p.amountCents);

    return CustomerSummary(
      customerId: customerId,
      totalDebtCents: totalInvoiced - totalPaid,
      invoiceCount: invoices.length,
      paymentCount: payments.length,
      invoices: invoices,
      payments: payments,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_ledger_entry.dart';
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
  Future<Customer?> getCustomer(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return null;
      return Customer.fromJson(fromFirestore(doc));
    } catch (_) {
      final cached = HiveCache.instance.loadList(HiveCache.instance.customersBox);
      if (cached != null) {
        try {
          final json = cached.firstWhere((c) => c['id'] == id);
          return Customer.fromJson(json);
        } catch (_) {}
      }
      rethrow;
    }
  }

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
    required String defaultNote,
    required String note,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();
    await _col.doc(id).set({
      'name': name,
      'phone': phone,
      'address': address,
      'defaultNote': defaultNote,
      'note': note,
      'currentDebtCacheCents': 0,
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
      'defaultNote': customer.defaultNote,
      'note': customer.note,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final now = DateTime.now().toIso8601String();
    await _col.doc(id).update({
      'isDeleted': true,
      'deletedAt': now,
      'updatedAt': now,
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

  @override
  Stream<List<CustomerLedgerEntry>> watchCustomerLedger(String customerId) {
    return _firestore
        .collection(_paths.ledger(customerId))
        .orderBy('date', descending: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CustomerLedgerEntry.fromJson(fromFirestore(d))).toList());
  }

  @override
  Future<void> recalculateLedger(String customerId) async {
    final ledgerSnap = await _firestore
        .collection(_paths.ledger(customerId))
        .orderBy('date', descending: false)
        .orderBy('createdAt', descending: false)
        .get();

    int total = 0;
    for (final doc in ledgerSnap.docs) {
      final data = doc.data();
      final typeStr = data['type'] as String? ?? 'sale';
      final amount = data['amountCents'] as int? ?? 0;
      if (typeStr == 'sale') {
        total += amount;
      } else if (typeStr == 'payment') {
        total -= amount;
      } else if (typeStr == 'cancellation') {
        total -= amount;
      } else if (typeStr == 'paymentReversal') {
        total += amount;
      }
    }

    await _col.doc(customerId).update({
      'currentDebtCacheCents': total,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> migrateCustomerIfNeeded(String customerId) async {
    final docRef = _col.doc(customerId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data();
    if (data != null && data.containsKey('currentDebtCacheCents') && data['currentDebtCacheCents'] != null) {
      return; // Already migrated
    }

    final invoicesSnap = await _firestore
        .collection(_paths.invoices)
        .where('customerId', isEqualTo: customerId)
        .get();

    final invoiceList = <Invoice>[];
    for (final d in invoicesSnap.docs) {
      final invData = fromFirestore(d);
      final itemsSnap = await _firestore.collection(_paths.invoiceItems(d.id)).get();
      final items = itemsSnap.docs.map((i) => InvoiceItem.fromJson(fromFirestore(i))).toList();
      invoiceList.add(Invoice.fromJson({...invData, 'items': items.map((e) => e.toJson()).toList()}));
    }

    final paymentsSnap = await _firestore
        .collection(_paths.payments)
        .where('customerId', isEqualTo: customerId)
        .get();
    final paymentList = paymentsSnap.docs.map((d) => Payment.fromJson(fromFirestore(d))).toList();

    final batch = _firestore.batch();
    final ledgerCol = _firestore.collection(_paths.ledger(customerId));

    int total = 0;
    final entries = <Map<String, dynamic>>[];

    for (final inv in invoiceList) {
      final snapshots = inv.items.map((item) => LedgerItemSnapshot(
        materialId: item.materialId,
        materialName: item.materialName,
        quantity: item.quantity,
        unit: item.unit,
        sellingPriceCents: item.sellingPriceCents,
        lineTotalCents: item.lineTotalCents,
      )).toList();

      entries.add({
        'id': inv.id,
        'date': inv.invoiceDate,
        'createdAt': inv.createdAt,
        'type': inv.status == InvoiceStatus.cancelled ? 'cancellation' : 'sale',
        'description': inv.items.map((item) => '${item.materialName}: ${item.quantity} ${item.unit}').join(', '),
        'amountCents': inv.totalAmountCents,
        'invoiceId': inv.id,
        'paymentId': null,
        'items': snapshots.map((e) => e.toJson()).toList(),
      });

      if (inv.status == InvoiceStatus.cancelled) {
        entries.add({
          'id': const Uuid().v4(),
          'date': inv.invoiceDate,
          'createdAt': inv.updatedAt,
          'type': 'cancellation',
          'description': 'Hủy hóa đơn #${inv.id.substring(0, 8).toUpperCase()}',
          'amountCents': inv.totalAmountCents,
          'invoiceId': inv.id,
          'paymentId': null,
          'items': snapshots.map((e) => e.toJson()).toList(),
        });
      }
    }

    for (final p in paymentList) {
      entries.add({
        'id': p.id,
        'date': p.paymentDate,
        'createdAt': p.createdAt,
        'type': 'payment',
        'description': 'Khách trả tiền',
        'amountCents': p.amountCents,
        'invoiceId': p.invoiceId,
        'paymentId': p.id,
        'items': <Map<String, dynamic>>[],
      });
    }

    entries.sort((a, b) {
      final cmp = (a['date'] as String).compareTo(b['date'] as String);
      if (cmp != 0) return cmp;
      return (a['createdAt'] as String).compareTo(b['createdAt'] as String);
    });

    for (final entry in entries) {
      final entryId = entry['id'] as String;
      final type = entry['type'] as String;
      final amount = entry['amountCents'] as int;

      if (type == 'sale') {
        total += amount;
      } else {
        total -= amount;
      }

      batch.set(ledgerCol.doc(entryId), {
        'customerId': customerId,
        'invoiceId': entry['invoiceId'],
        'paymentId': entry['paymentId'],
        'date': entry['date'],
        'type': type,
        'description': entry['description'],
        'amountCents': amount,
        'createdAt': entry['createdAt'],
        'items': entry['items'],
      });
    }

    batch.update(docRef, {
      'currentDebtCacheCents': total,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }
}

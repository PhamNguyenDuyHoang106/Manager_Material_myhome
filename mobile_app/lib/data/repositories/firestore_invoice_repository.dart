import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/inventory_transaction.dart';
import '../../domain/entities/customer_ledger_entry.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/firestore_paths.dart';
import '../datasources/hive_cache.dart';
import '../mappers/firestore_mapper.dart';
import 'firestore_inventory_repository.dart';

class FirestoreInvoiceRepository implements InvoiceRepository {
  FirestoreInvoiceRepository(
    this._firestore,
    this._uid,
    this._inventoryRepo,
  );

  final FirebaseFirestore _firestore;
  final String _uid;
  final FirestoreInventoryRepository _inventoryRepo;
  final _uuid = const Uuid();

  FirestorePaths get _paths => FirestorePaths(_uid);

  CollectionReference<Map<String, dynamic>> get _invoiceCol =>
      _firestore.collection(_paths.invoices);

  CollectionReference<Map<String, dynamic>> get _materialCol =>
      _firestore.collection(_paths.materials);

  String _statusToString(InvoiceStatus s) => switch (s) {
        InvoiceStatus.unpaid => 'unpaid',
        InvoiceStatus.partiallyPaid => 'partially_paid',
        InvoiceStatus.paid => 'paid',
        InvoiceStatus.cancelled => 'cancelled',
      };

  Future<Invoice> _mapInvoice(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = fromFirestore(doc);
    final itemsSnap = await _firestore.collection(_paths.invoiceItems(doc.id)).get();
    final items = itemsSnap.docs.map((i) => InvoiceItem.fromJson(fromFirestore(i))).toList();
    return Invoice.fromJson({...data, 'items': items.map((e) => e.toJson()).toList()});
  }

  @override
  Stream<List<Invoice>> watchInvoices({String query = ''}) {
    return _invoiceCol
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final list = <Invoice>[];
      for (final doc in snap.docs) {
        list.add(await _mapInvoice(doc));
      }
      var filtered = list;
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        filtered = list.where((i) => i.customerName.toLowerCase().contains(q)).toList();
      }
      HiveCache.instance.saveList(
        HiveCache.instance.invoicesBox,
        filtered.map((i) => i.toJson()).toList(),
      );
      return filtered;
    });
  }

  @override
  Future<List<Invoice>> getInvoices({String query = ''}) async {
    try {
      final snap = await _invoiceCol
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
      final list = <Invoice>[];
      for (final doc in snap.docs) {
        list.add(await _mapInvoice(doc));
      }
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        return list.where((i) => i.customerName.toLowerCase().contains(q)).toList();
      }
      return list;
    } catch (_) {
      final cached = HiveCache.instance.loadList(HiveCache.instance.invoicesBox);
      if (cached == null) rethrow;
      return cached.map((j) {
        final inv = Invoice.fromJson(j);
        return inv;
      }).toList();
    }
  }

  @override
  Future<Invoice?> getInvoice(String id) async {
    final doc = await _invoiceCol.doc(id).get();
    if (!doc.exists) return null;
    return _mapInvoice(doc);
  }

  Future<Map<String, dynamic>> _loadMaterial(Transaction txn, String materialId) async {
    final ref = _materialCol.doc(materialId);
    final snap = await txn.get(ref);
    if (!snap.exists || (snap.data()?['isDeleted'] == true)) {
      throw const ValidationException('Vật liệu không tồn tại');
    }
    return snap.data()!;
  }

  Future<void> _deductStock(
    Transaction txn, {
    required String materialId,
    required String materialName,
    required double quantity,
    required String invoiceId,
  }) async {
    final matRef = _materialCol.doc(materialId);
    final matSnap = await txn.get(matRef);
    final current = (matSnap.data()!['currentStock'] as num).toDouble();
    if (current < quantity) {
      throw StockException('Không đủ tồn kho cho "$materialName" (còn $current)');
    }
    final newStock = current - quantity;
    txn.update(matRef, {
      'currentStock': newStock,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _inventoryRepo.recordTransaction(
      txn: txn,
      materialId: materialId,
      materialName: materialName,
      type: InventoryTxType.invoiceDeduct,
      quantity: -quantity,
      stockAfter: newStock,
      referenceId: invoiceId,
    );
  }

  Future<void> _rollbackStock(
    Transaction txn, {
    required String materialId,
    required String materialName,
    required double quantity,
    required String invoiceId,
  }) async {
    final matRef = _materialCol.doc(materialId);
    final matSnap = await txn.get(matRef);
    final current = (matSnap.data()!['currentStock'] as num).toDouble();
    final newStock = current + quantity;
    txn.update(matRef, {
      'currentStock': newStock,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _inventoryRepo.recordTransaction(
      txn: txn,
      materialId: materialId,
      materialName: materialName,
      type: InventoryTxType.invoiceRollback,
      quantity: quantity,
      stockAfter: newStock,
      referenceId: invoiceId,
    );
  }

  @override
  Future<String> createInvoice({
    required String customerId,
    required DateTime invoiceDate,
    required List<InvoiceItemInput> items,
    required String deliveryAddress,
    required String deliveryNote,
  }) async {
    if (items.isEmpty) throw const ValidationException('Hóa đơn cần ít nhất một dòng');

    final customerDoc = await _firestore.collection(_paths.customers).doc(customerId).get();
    if (!customerDoc.exists) throw const ValidationException('Khách hàng không tồn tại');
    final customerName = customerDoc.data()!['name'] as String;

    final invoiceId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final invoiceDateStr = invoiceDate.toIso8601String();

    await _firestore.runTransaction((txn) async {
      int total = 0;
      final lineData = <Map<String, dynamic>>[];

      for (final item in items) {
        final mat = await _loadMaterial(txn, item.materialId);
        final lineTotal = (item.quantity * item.sellingPriceCents).round();
        total += lineTotal;
        lineData.add({
          'material': mat,
          'item': item,
          'lineTotal': lineTotal,
        });
      }

      final invoiceRef = _invoiceCol.doc(invoiceId);
      txn.set(invoiceRef, {
        'customerId': customerId,
        'customerName': customerName,
        'invoiceDate': invoiceDateStr,
        'totalAmountCents': total,
        'paidAmountCents': 0,
        'status': _statusToString(InvoiceStatus.unpaid),
        'createdAt': now,
        'updatedAt': now,
        'deliveryAddress': deliveryAddress,
        'deliveryNote': deliveryNote,
      });

      final customerRef = _firestore.collection(_paths.customers).doc(customerId);
      final custSnap = await txn.get(customerRef);
      final currentDebt = custSnap.data()?['currentDebtCacheCents'] as int? ?? 0;
      final newDebt = currentDebt + total;
      txn.update(customerRef, {
        'currentDebtCacheCents': newDebt,
        'updatedAt': now,
      });

      for (final row in lineData) {
        final item = row['item'] as InvoiceItemInput;
        final mat = row['material'] as Map<String, dynamic>;
        final lineTotal = row['lineTotal'] as int;
        final itemId = _uuid.v4();
        txn.set(_firestore.collection(_paths.invoiceItems(invoiceId)).doc(itemId), {
          'materialId': item.materialId,
          'materialName': mat['name'],
          'unit': mat['unit'],
          'quantity': item.quantity,
          'sellingPriceCents': item.sellingPriceCents,
          'lineTotalCents': lineTotal,
        });
        await _deductStock(
          txn,
          materialId: item.materialId,
          materialName: mat['name'] as String,
          quantity: item.quantity,
          invoiceId: invoiceId,
        );
      }

      final ledgerRef = _firestore.collection(_paths.ledger(customerId)).doc(invoiceId);
      final desc = lineData.map((row) {
        final mat = row['material'] as Map<String, dynamic>;
        final item = row['item'] as InvoiceItemInput;
        return '${mat['name']}: ${item.quantity} ${mat['unit']}';
      }).join(', ');

      final snapshots = lineData.map((row) {
        final mat = row['material'] as Map<String, dynamic>;
        final item = row['item'] as InvoiceItemInput;
        final lineTotal = row['lineTotal'] as int;
        return {
          'materialId': item.materialId,
          'materialName': mat['name'],
          'quantity': item.quantity,
          'unit': mat['unit'],
          'sellingPriceCents': item.sellingPriceCents,
          'lineTotalCents': lineTotal,
        };
      }).toList();

      txn.set(ledgerRef, {
        'customerId': customerId,
        'invoiceId': invoiceId,
        'paymentId': null,
        'date': invoiceDateStr,
        'type': 'sale',
        'description': desc,
        'amountCents': total,
        'createdAt': now,
        'items': snapshots,
      });
    });

    return invoiceId;
  }

  @override
  Future<void> updateInvoice({
    required String invoiceId,
    required String customerId,
    required DateTime invoiceDate,
    required List<InvoiceItemInput> items,
    required String deliveryAddress,
    required String deliveryNote,
  }) async {
    final existing = await getInvoice(invoiceId);
    if (existing == null) throw const ValidationException('Hóa đơn không tồn tại');
    
    final paymentsSnap = await _firestore
        .collection(_paths.payments)
        .where('invoiceId', isEqualTo: invoiceId)
        .limit(1)
        .get();
    if (paymentsSnap.docs.isNotEmpty) {
      throw const ValidationException('Không thể sửa hóa đơn đã có thanh toán liên quan');
    }
    if (items.isEmpty) throw const ValidationException('Hóa đơn cần ít nhất một dòng');

    final customerDoc = await _firestore.collection(_paths.customers).doc(customerId).get();
    final customerName = customerDoc.data()?['name'] as String? ?? existing.customerName;

    final itemsCol = _firestore.collection(_paths.invoiceItems(invoiceId));
    final oldItemsSnap = await itemsCol.get();
    final invoiceDateStr = invoiceDate.toIso8601String();
    final now = DateTime.now().toIso8601String();

    await _firestore.runTransaction((txn) async {
      for (final oldItem in existing.items) {
        await _rollbackStock(
          txn,
          materialId: oldItem.materialId,
          materialName: oldItem.materialName,
          quantity: oldItem.quantity,
          invoiceId: invoiceId,
        );
      }

      for (final doc in oldItemsSnap.docs) {
        txn.delete(doc.reference);
      }

      int total = 0;
      final lineData = <Map<String, dynamic>>[];
      for (final item in items) {
        final mat = await _loadMaterial(txn, item.materialId);
        final lineTotal = (item.quantity * item.sellingPriceCents).round();
        total += lineTotal;
        final itemId = _uuid.v4();
        txn.set(itemsCol.doc(itemId), {
          'materialId': item.materialId,
          'materialName': mat['name'],
          'unit': mat['unit'],
          'quantity': item.quantity,
          'sellingPriceCents': item.sellingPriceCents,
          'lineTotalCents': lineTotal,
        });
        lineData.add({
          'material': mat,
          'item': item,
          'lineTotal': lineTotal,
        });
        await _deductStock(
          txn,
          materialId: item.materialId,
          materialName: mat['name'] as String,
          quantity: item.quantity,
          invoiceId: invoiceId,
        );
      }

      // Update customer debt cache
      if (existing.customerId == customerId) {
        final customerRef = _firestore.collection(_paths.customers).doc(customerId);
        final custSnap = await txn.get(customerRef);
        final currentDebt = custSnap.data()?['currentDebtCacheCents'] as int? ?? 0;
        final newDebt = currentDebt - existing.totalAmountCents + total;
        txn.update(customerRef, {
          'currentDebtCacheCents': newDebt,
          'updatedAt': now,
        });
      } else {
        // Subtract from old customer
        final oldCustomerRef = _firestore.collection(_paths.customers).doc(existing.customerId);
        final oldCustSnap = await txn.get(oldCustomerRef);
        final oldDebt = oldCustSnap.data()?['currentDebtCacheCents'] as int? ?? 0;
        txn.update(oldCustomerRef, {
          'currentDebtCacheCents': oldDebt - existing.totalAmountCents,
          'updatedAt': now,
        });

        // Add to new customer
        final newCustomerRef = _firestore.collection(_paths.customers).doc(customerId);
        final newCustSnap = await txn.get(newCustomerRef);
        final newDebt = newCustSnap.data()?['currentDebtCacheCents'] as int? ?? 0;
        txn.update(newCustomerRef, {
          'currentDebtCacheCents': newDebt + total,
          'updatedAt': now,
        });

        // Delete from old ledger
        txn.delete(_firestore.collection(_paths.ledger(existing.customerId)).doc(invoiceId));
      }

      // Set ledger entry
      final ledgerRef = _firestore.collection(_paths.ledger(customerId)).doc(invoiceId);
      final desc = lineData.map((row) {
        final mat = row['material'] as Map<String, dynamic>;
        final item = row['item'] as InvoiceItemInput;
        return '${mat['name']}: ${item.quantity} ${mat['unit']}';
      }).join(', ');

      final snapshots = lineData.map((row) {
        final mat = row['material'] as Map<String, dynamic>;
        final item = row['item'] as InvoiceItemInput;
        final lineTotal = row['lineTotal'] as int;
        return {
          'materialId': item.materialId,
          'materialName': mat['name'],
          'quantity': item.quantity,
          'unit': mat['unit'],
          'sellingPriceCents': item.sellingPriceCents,
          'lineTotalCents': lineTotal,
        };
      }).toList();

      txn.set(ledgerRef, {
        'customerId': customerId,
        'invoiceId': invoiceId,
        'paymentId': null,
        'date': invoiceDateStr,
        'type': 'sale',
        'description': desc,
        'amountCents': total,
        'createdAt': existing.createdAt.toIso8601String(),
        'items': snapshots,
      });

      txn.update(_invoiceCol.doc(invoiceId), {
        'customerId': customerId,
        'customerName': customerName,
        'invoiceDate': invoiceDateStr,
        'totalAmountCents': total,
        'status': _statusToString(InvoiceStatus.unpaid),
        'updatedAt': now,
        'deliveryAddress': deliveryAddress,
        'deliveryNote': deliveryNote,
      });
    });
  }

  @override
  Future<void> cancelInvoice(String invoiceId) async {
    final existing = await getInvoice(invoiceId);
    if (existing == null) throw const ValidationException('Hóa đơn không tồn tại');

    // Secure check: verify if there are any payments in firestore for this invoice
    final paymentsSnap = await _firestore
        .collection(_paths.payments)
        .where('invoiceId', isEqualTo: invoiceId)
        .limit(1)
        .get();
    if (paymentsSnap.docs.isNotEmpty) {
      throw const ValidationException('Không thể hủy hóa đơn đã có thanh toán liên quan');
    }

    final now = DateTime.now().toIso8601String();
    final today = now.substring(0, 10);

    await _firestore.runTransaction((txn) async {
      // 1. Rollback stock
      for (final item in existing.items) {
        await _rollbackStock(
          txn,
          materialId: item.materialId,
          materialName: item.materialName,
          quantity: item.quantity,
          invoiceId: invoiceId,
        );
      }

      // 2. Update Invoice status to cancelled
      txn.update(_invoiceCol.doc(invoiceId), {
        'status': _statusToString(InvoiceStatus.cancelled),
        'updatedAt': now,
      });

      // 3. Revert customer debt cache
      final customerRef = _firestore.collection(_paths.customers).doc(existing.customerId);
      final custSnap = await txn.get(customerRef);
      final currentDebt = custSnap.data()?['currentDebtCacheCents'] as int? ?? 0;
      final newDebt = currentDebt - existing.totalAmountCents;
      txn.update(customerRef, {
        'currentDebtCacheCents': newDebt,
        'updatedAt': now,
      });

      // 4. Create ledger cancellation entry
      final ledgerRef = _firestore.collection(_paths.ledger(existing.customerId)).doc(_uuid.v4());
      final snapshots = existing.items.map((item) => {
        'materialId': item.materialId,
        'materialName': item.materialName,
        'quantity': item.quantity,
        'unit': item.unit,
        'sellingPriceCents': item.sellingPriceCents,
        'lineTotalCents': item.lineTotalCents,
      }).toList();

      txn.set(ledgerRef, {
        'customerId': existing.customerId,
        'invoiceId': invoiceId,
        'paymentId': null,
        'date': today,
        'type': 'cancellation',
        'description': 'Hủy hóa đơn #${invoiceId.substring(0, 8).toUpperCase()}',
        'amountCents': existing.totalAmountCents,
        'createdAt': now,
        'items': snapshots,
      });
    });
  }

  @override
  Future<void> deleteInvoice(String id) async {
    final existing = await getInvoice(id);
    if (existing == null) throw const ValidationException('Hóa đơn không tồn tại');

    final paymentsSnap = await _firestore
        .collection(_paths.payments)
        .where('invoiceId', isEqualTo: id)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();
    if (paymentsSnap.docs.isNotEmpty) {
      throw const ValidationException('Không thể xóa hóa đơn đã có thanh toán liên quan');
    }

    final now = DateTime.now().toIso8601String();

    await _firestore.runTransaction((txn) async {
      final invoiceRef = _invoiceCol.doc(id);

      if (existing.status != InvoiceStatus.cancelled) {
        for (final item in existing.items) {
          await _rollbackStock(
            txn,
            materialId: item.materialId,
            materialName: item.materialName,
            quantity: item.quantity,
            invoiceId: id,
          );
        }

        final customerRef = _firestore.collection(_paths.customers).doc(existing.customerId);
        final custSnap = await txn.get(customerRef);
        final currentDebt = custSnap.data()?['currentDebtCacheCents'] as int? ?? 0;
        final newDebt = currentDebt - existing.totalAmountCents;
        txn.update(customerRef, {
          'currentDebtCacheCents': newDebt,
          'updatedAt': now,
        });
      }

      txn.update(invoiceRef, {
        'isDeleted': true,
        'deletedAt': now,
        'updatedAt': now,
      });
    });

    final ledgerSnap = await _firestore
        .collection(_paths.ledger(existing.customerId))
        .where('invoiceId', isEqualTo: id)
        .get();

    final batch = _firestore.batch();
    for (final doc in ledgerSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

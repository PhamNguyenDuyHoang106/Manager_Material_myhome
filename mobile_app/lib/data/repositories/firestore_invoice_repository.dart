import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/money_utils.dart';
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

  @override
  Future<String> createInvoice({
    required String customerId,
    required DateTime invoiceDate,
    required List<InvoiceItemInput> items,
    required String deliveryAddress,
    required String deliveryDirections,
    required String deliveryNote,
  }) async {
    if (items.isEmpty) throw const ValidationException('Hóa đơn cần ít nhất một dòng');

    final customerRef = _firestore.collection(_paths.customers).doc(customerId);
    final customerDoc = await customerRef.get();
    if (!customerDoc.exists) throw const ValidationException('Khách hàng không tồn tại');
    final customerName = customerDoc.data()!['name'] as String;

    final invoiceId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final invoiceDateStr = invoiceDate.toIso8601String();

    // 1. READ materials first
    final matSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final item in items) {
      if (!matSnaps.containsKey(item.materialId)) {
        final ref = _materialCol.doc(item.materialId);
        matSnaps[item.materialId] = await ref.get();
      }
    }

    // 2. VALIDATION & COMPUTATION (In memory)
    int total = 0;
    final lineData = <Map<String, dynamic>>[];

    for (final item in items) {
      final matSnap = matSnaps[item.materialId]!;
      if (!matSnap.exists || (matSnap.data()?['isDeleted'] == true)) {
        throw const ValidationException('Vật liệu không tồn tại');
      }
      final mat = matSnap.data()!;

      final lineTotal = (item.quantity * item.sellingPriceCents).round();
      total += lineTotal;
      lineData.add({
        'material': mat,
        'item': item,
        'lineTotal': lineTotal,
      });
    }

    final currentDebt = customerDoc.data()?['currentDebtCacheCents'] as int? ?? 0;
    final newDebt = currentDebt + total;

    // 3. WRITE phase using WriteBatch
    final batch = _firestore.batch();

    // A. Update customer debt cache
    batch.update(customerRef, {
      'currentDebtCacheCents': newDebt,
      'updatedAt': now,
    });

    // B. Create Invoice doc
    final invoiceRef = _invoiceCol.doc(invoiceId);
    batch.set(invoiceRef, {
      'customerId': customerId,
      'customerName': customerName,
      'invoiceDate': invoiceDateStr,
      'totalAmountCents': total,
      'paidAmountCents': 0,
      'status': _statusToString(InvoiceStatus.unpaid),
      'createdAt': now,
      'updatedAt': now,
      'deliveryAddress': deliveryAddress,
      'deliveryDirections': deliveryDirections,
      'deliveryNote': deliveryNote,
      'isDeleted': false,
    });

    // C. Save each line item (no stock update – inventory removed)
    for (final row in lineData) {
      final item = row['item'] as InvoiceItemInput;
      final mat = row['material'] as Map<String, dynamic>;
      final lineTotal = row['lineTotal'] as int;
      final itemId = _uuid.v4();

      batch.set(_firestore.collection(_paths.invoiceItems(invoiceId)).doc(itemId), {
        'materialId': item.materialId,
        'materialName': mat['name'],
        'unit': item.unit ?? mat['unit'],
        'quantity': item.quantity,
        'sellingPriceCents': item.sellingPriceCents,
        'lineTotalCents': lineTotal,
        'deliveryDate': item.deliveryDate?.toIso8601String() ?? invoiceDateStr,
      });
    }

    // D. Create ledger entry
    final ledgerRef = _firestore.collection(_paths.ledger(customerId)).doc(invoiceId);
    final desc = lineData.map((row) {
      final mat = row['material'] as Map<String, dynamic>;
      final item = row['item'] as InvoiceItemInput;
      return '${mat['name']}: ${MoneyUtils.formatQty(item.quantity)} ${item.unit ?? mat['unit']}';
    }).join(', ');

    final snapshots = lineData.map((row) {
      final mat = row['material'] as Map<String, dynamic>;
      final item = row['item'] as InvoiceItemInput;
      final lineTotal = row['lineTotal'] as int;
      return {
        'materialId': item.materialId,
        'materialName': mat['name'],
        'quantity': item.quantity,
        'unit': item.unit ?? mat['unit'],
        'sellingPriceCents': item.sellingPriceCents,
        'lineTotalCents': lineTotal,
        'deliveryDate': item.deliveryDate?.toIso8601String() ?? invoiceDateStr,
      };
    }).toList();

    batch.set(ledgerRef, {
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

    await batch.commit();

    return invoiceId;
  }

  @override
  Future<void> updateInvoice({
    required String invoiceId,
    required String customerId,
    required DateTime invoiceDate,
    required List<InvoiceItemInput> items,
    required String deliveryAddress,
    required String deliveryDirections,
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

    // 1. READ customer & materials first
    final oldCustSnap = await _firestore.collection(_paths.customers).doc(existing.customerId).get();
    DocumentSnapshot<Map<String, dynamic>>? newCustSnap;
    if (existing.customerId != customerId) {
      newCustSnap = await _firestore.collection(_paths.customers).doc(customerId).get();
    }

    // Only read materials for validation (not stock)
    final matSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final newItem in items) {
      if (!matSnaps.containsKey(newItem.materialId)) {
        matSnaps[newItem.materialId] = await _materialCol.doc(newItem.materialId).get();
      }
    }

    // 2. VALIDATION & COMPUTATION
    int total = 0;
    final lineData = <Map<String, dynamic>>[];
    for (final item in items) {
      final matSnap = matSnaps[item.materialId]!;
      if (!matSnap.exists || (matSnap.data()?['isDeleted'] == true)) {
        throw const ValidationException('Vật liệu không tồn tại');
      }
      final mat = matSnap.data()!;

      final lineTotal = (item.quantity * item.sellingPriceCents).round();
      total += lineTotal;
      lineData.add({
        'material': mat,
        'item': item,
        'lineTotal': lineTotal,
      });
    }

    // 3. WRITE phase using WriteBatch
    final batch = _firestore.batch();

    // A. Delete all old item subdocuments
    for (final doc in oldItemsSnap.docs) {
      batch.delete(doc.reference);
    }

    // B. Save new item documents (no stock update – inventory removed)
    for (final row in lineData) {
      final item = row['item'] as InvoiceItemInput;
      final mat = row['material'] as Map<String, dynamic>;
      final lineTotal = row['lineTotal'] as int;
      final itemId = _uuid.v4();

      batch.set(itemsCol.doc(itemId), {
        'materialId': item.materialId,
        'materialName': mat['name'],
        'unit': item.unit ?? mat['unit'],
        'quantity': item.quantity,
        'sellingPriceCents': item.sellingPriceCents,
        'lineTotalCents': lineTotal,
        'deliveryDate': item.deliveryDate?.toIso8601String() ?? invoiceDateStr,
      });
    }

    // C. Update customer debt caches
    if (existing.customerId == customerId) {
      final oldDebt = oldCustSnap.data()?['currentDebtCacheCents'] as int? ?? 0;
      final newDebt = oldDebt - existing.totalAmountCents + total;
      batch.update(_firestore.collection(_paths.customers).doc(customerId), {
        'currentDebtCacheCents': newDebt,
        'updatedAt': now,
      });
    } else {
      final oldDebt = oldCustSnap.data()?['currentDebtCacheCents'] as int? ?? 0;
      batch.update(_firestore.collection(_paths.customers).doc(existing.customerId), {
        'currentDebtCacheCents': oldDebt - existing.totalAmountCents,
        'updatedAt': now,
      });

      final newDebt = newCustSnap!.data()?['currentDebtCacheCents'] as int? ?? 0;
      batch.update(_firestore.collection(_paths.customers).doc(customerId), {
        'currentDebtCacheCents': newDebt + total,
        'updatedAt': now,
      });

      // Delete ledger from old customer
      batch.delete(_firestore.collection(_paths.ledger(existing.customerId)).doc(invoiceId));
    }

    // F. Write ledger entry
    final ledgerRef = _firestore.collection(_paths.ledger(customerId)).doc(invoiceId);
    final desc = lineData.map((row) {
      final mat = row['material'] as Map<String, dynamic>;
      final item = row['item'] as InvoiceItemInput;
      return '${mat['name']}: ${MoneyUtils.formatQty(item.quantity)} ${item.unit ?? mat['unit']}';
    }).join(', ');

    final snapshots = lineData.map((row) {
      final mat = row['material'] as Map<String, dynamic>;
      final item = row['item'] as InvoiceItemInput;
      final lineTotal = row['lineTotal'] as int;
      return {
        'materialId': item.materialId,
        'materialName': mat['name'],
        'quantity': item.quantity,
        'unit': item.unit ?? mat['unit'],
        'sellingPriceCents': item.sellingPriceCents,
        'lineTotalCents': lineTotal,
        'deliveryDate': item.deliveryDate?.toIso8601String() ?? invoiceDateStr,
      };
    }).toList();

    batch.set(ledgerRef, {
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

    // G. Update invoice itself
    batch.update(_invoiceCol.doc(invoiceId), {
      'customerId': customerId,
      'customerName': customerName,
      'invoiceDate': invoiceDateStr,
      'totalAmountCents': total,
      'status': _statusToString(InvoiceStatus.unpaid),
      'updatedAt': now,
      'deliveryAddress': deliveryAddress,
      'deliveryDirections': deliveryDirections,
      'deliveryNote': deliveryNote,
    });

    await batch.commit();
  }

  @override
  Future<void> cancelInvoice(String invoiceId) async {
    final existing = await getInvoice(invoiceId);
    if (existing == null) throw const ValidationException('Hóa đơn không tồn tại');

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

    // 1. READ customer and materials first
    final customerRef = _firestore.collection(_paths.customers).doc(existing.customerId);
    final custSnap = await customerRef.get();

    final matSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final item in existing.items) {
      if (!matSnaps.containsKey(item.materialId)) {
        matSnaps[item.materialId] = await _materialCol.doc(item.materialId).get();
      }
    }

    // 2. COMPUTE stock updates
    final currentStocks = <String, double>{};
    for (final entry in matSnaps.entries) {
      final data = entry.value.data();
      currentStocks[entry.key] = data != null ? (data['currentStock'] as num).toDouble() : 0.0;
    }

    // 3. WRITE phase using WriteBatch
    final batch = _firestore.batch();

    // A. Rollback stock
    for (final item in existing.items) {
      final currentStock = currentStocks[item.materialId]!;
      final newStock = currentStock + item.quantity;
      currentStocks[item.materialId] = newStock;

      // Record transaction
      batch.set(_firestore.collection(_paths.inventoryTransactions).doc(_uuid.v4()), {
        'materialId': item.materialId,
        'materialName': item.materialName,
        'type': 'invoice_rollback',
        'quantity': item.quantity,
        'stockAfter': newStock,
        'referenceId': invoiceId,
        'createdAt': now,
      });

      // Update material stock
      batch.update(_materialCol.doc(item.materialId), {
        'currentStock': newStock,
        'updatedAt': now,
      });
    }

    // B. Update Invoice status to cancelled
    batch.update(_invoiceCol.doc(invoiceId), {
      'status': _statusToString(InvoiceStatus.cancelled),
      'updatedAt': now,
    });

    // C. Revert customer debt cache
    final currentDebt = custSnap.data()?['currentDebtCacheCents'] as int? ?? 0;
    final newDebt = currentDebt - existing.totalAmountCents;
    batch.update(customerRef, {
      'currentDebtCacheCents': newDebt,
      'updatedAt': now,
    });

    // D. Create ledger cancellation entry
    final ledgerRef = _firestore.collection(_paths.ledger(existing.customerId)).doc(_uuid.v4());
    final snapshots = existing.items.map((item) => {
      'materialId': item.materialId,
      'materialName': item.materialName,
      'quantity': item.quantity,
      'unit': item.unit,
      'sellingPriceCents': item.sellingPriceCents,
      'lineTotalCents': item.lineTotalCents,
    }).toList();

    batch.set(ledgerRef, {
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

    await batch.commit();
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

    final invoiceRef = _invoiceCol.doc(id);

    DocumentSnapshot<Map<String, dynamic>>? custSnap;
    final customerRef = _firestore.collection(_paths.customers).doc(existing.customerId);
    final matSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};

    // 1. READ customer and materials first (only if invoice is not already cancelled)
    if (existing.status != InvoiceStatus.cancelled) {
      custSnap = await customerRef.get();
      for (final item in existing.items) {
        if (!matSnaps.containsKey(item.materialId)) {
          matSnaps[item.materialId] = await _materialCol.doc(item.materialId).get();
        }
      }
    }

    // 2. WRITE phase using WriteBatch
    final batch = _firestore.batch();

    if (existing.status != InvoiceStatus.cancelled) {
      final currentStocks = <String, double>{};
      for (final entry in matSnaps.entries) {
        final data = entry.value.data();
        currentStocks[entry.key] = data != null ? (data['currentStock'] as num).toDouble() : 0.0;
      }

      for (final item in existing.items) {
        final currentStock = currentStocks[item.materialId]!;
        final newStock = currentStock + item.quantity;
        currentStocks[item.materialId] = newStock;

        // Record transaction
        batch.set(_firestore.collection(_paths.inventoryTransactions).doc(_uuid.v4()), {
          'materialId': item.materialId,
          'materialName': item.materialName,
          'type': 'invoice_rollback',
          'quantity': item.quantity,
          'stockAfter': newStock,
          'referenceId': id,
          'createdAt': now,
        });

        // Update material stock
        batch.update(_materialCol.doc(item.materialId), {
          'currentStock': newStock,
          'updatedAt': now,
        });
      }

      final currentDebt = custSnap!.data()?['currentDebtCacheCents'] as int? ?? 0;
      final newDebt = currentDebt - existing.totalAmountCents;
      batch.update(customerRef, {
        'currentDebtCacheCents': newDebt,
        'updatedAt': now,
      });
    }

    // Mark invoice as deleted
    batch.update(invoiceRef, {
      'isDeleted': true,
      'deletedAt': now,
      'updatedAt': now,
    });

    final ledgerSnap = await _firestore
        .collection(_paths.ledger(existing.customerId))
        .where('invoiceId', isEqualTo: id)
        .get();

    for (final doc in ledgerSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Stream<List<Invoice>> watchDeletedInvoices({String query = ''}) {
    return _invoiceCol
        .where('isDeleted', isEqualTo: true)
        .snapshots()
        .asyncMap((snap) async {
      final list = <Invoice>[];
      for (final doc in snap.docs) {
        list.add(await _mapInvoice(doc));
      }
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      var filtered = list;
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        filtered = list.where((i) => i.customerName.toLowerCase().contains(q)).toList();
      }
      return filtered;
    });
  }

  @override
  Future<void> permanentlyDeleteInvoice(String id) async {
    final invoiceRef = _invoiceCol.doc(id);
    final itemsCol = _firestore.collection(_paths.invoiceItems(id));
    final itemsSnap = await itemsCol.get();

    final batch = _firestore.batch();
    for (final doc in itemsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(invoiceRef);
    await batch.commit();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/inventory_transaction.dart';
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
      };

  Future<Invoice> _mapInvoice(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = fromFirestore(doc);
    final itemsSnap = await _firestore.collection(_paths.invoiceItems(doc.id)).get();
    final items = itemsSnap.docs.map((i) => InvoiceItem.fromJson(fromFirestore(i))).toList();
    return Invoice.fromJson({...data, 'items': items.map((e) => e.toJson()).toList()});
  }

  @override
  Stream<List<Invoice>> watchInvoices({String query = ''}) {
    return _invoiceCol.orderBy('createdAt', descending: true).snapshots().asyncMap((snap) async {
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
      final snap = await _invoiceCol.orderBy('createdAt', descending: true).get();
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
    required String invoiceDate,
    required List<InvoiceItemInput> items,
  }) async {
    if (items.isEmpty) throw const ValidationException('Hóa đơn cần ít nhất một dòng');

    final customerDoc = await _firestore.collection(_paths.customers).doc(customerId).get();
    if (!customerDoc.exists) throw const ValidationException('Khách hàng không tồn tại');
    final customerName = customerDoc.data()!['name'] as String;

    final invoiceId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

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
        'invoiceDate': invoiceDate,
        'totalAmountCents': total,
        'paidAmountCents': 0,
        'status': _statusToString(InvoiceStatus.unpaid),
        'createdAt': now,
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
    });

    return invoiceId;
  }

  @override
  Future<void> updateInvoice({
    required String invoiceId,
    required String customerId,
    required String invoiceDate,
    required List<InvoiceItemInput> items,
  }) async {
    final existing = await getInvoice(invoiceId);
    if (existing == null) throw const ValidationException('Hóa đơn không tồn tại');
    if (existing.paidAmountCents > 0) {
      throw const ValidationException('Không thể sửa hóa đơn đã có thanh toán');
    }
    if (items.isEmpty) throw const ValidationException('Hóa đơn cần ít nhất một dòng');

    final customerDoc = await _firestore.collection(_paths.customers).doc(customerId).get();
    final customerName = customerDoc.data()?['name'] as String? ?? existing.customerName;

    final itemsCol = _firestore.collection(_paths.invoiceItems(invoiceId));
    final oldItemsSnap = await itemsCol.get();

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
        await _deductStock(
          txn,
          materialId: item.materialId,
          materialName: mat['name'] as String,
          quantity: item.quantity,
          invoiceId: invoiceId,
        );
      }

      txn.update(_invoiceCol.doc(invoiceId), {
        'customerId': customerId,
        'customerName': customerName,
        'invoiceDate': invoiceDate,
        'totalAmountCents': total,
        'status': _statusToString(InvoiceStatus.unpaid),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  @override
  Future<void> deleteInvoice(String invoiceId) async {
    final existing = await getInvoice(invoiceId);
    if (existing == null) throw const ValidationException('Hóa đơn không tồn tại');
    if (existing.paidAmountCents > 0) {
      throw const ValidationException('Không thể xóa hóa đơn đã có thanh toán');
    }

    final itemsCol = _firestore.collection(_paths.invoiceItems(invoiceId));
    final oldItemsSnap = await itemsCol.get();

    await _firestore.runTransaction((txn) async {
      for (final item in existing.items) {
        await _rollbackStock(
          txn,
          materialId: item.materialId,
          materialName: item.materialName,
          quantity: item.quantity,
          invoiceId: invoiceId,
        );
      }
      for (final doc in oldItemsSnap.docs) {
        txn.delete(doc.reference);
      }
      txn.delete(_invoiceCol.doc(invoiceId));
    });
  }
}

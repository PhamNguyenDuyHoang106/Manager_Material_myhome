import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/supplier_ledger_entry.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/firestore_paths.dart';

class FirestoreSupplierRepository implements SupplierRepository {
  FirestoreSupplierRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;
  final _uuid = const Uuid();

  FirestorePaths get _paths => FirestorePaths(_uid);

  CollectionReference<Map<String, dynamic>> get _suppliersCol =>
      _firestore.collection(_paths.suppliers);

  CollectionReference<Map<String, dynamic>> _ledgerCol(String supplierId) =>
      _firestore.collection(_paths.supplierLedger(supplierId));

  // ─────────────────────────────────────────────────────────────
  // SUPPLIER CRUD
  // ─────────────────────────────────────────────────────────────
  @override
  Stream<List<Supplier>> watchSuppliers({String? query}) {
    return _suppliersCol
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return Supplier.fromJson(data);
      }).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (query != null && query.trim().isNotEmpty) {
        final lower = query.trim().toLowerCase();
        return list.where((s) =>
          s.name.toLowerCase().contains(lower) ||
          s.phone.contains(lower)
        ).toList();
      }
      return list;
    });
  }

  @override
  Future<Supplier?> getSupplier(String id) async {
    final doc = await _suppliersCol.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return Supplier.fromJson(data);
  }

  @override
  Future<String> createSupplier({
    required String name,
    String phone = '',
    String address = '',
    String note = '',
    List<String> materialIds = const [],
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationException('Tên nhà cung cấp không được để trống');
    }
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    await _suppliersCol.doc(id).set({
      'id': id,
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'note': note.trim(),
      'materialIds': materialIds,
      'currentDebtCacheCents': 0,
      'isDeleted': false,
      'createdAt': now,
      'updatedAt': now,
    });
    return id;
  }

  @override
  Future<void> updateSupplier({
    required String id,
    required String name,
    String phone = '',
    String address = '',
    String note = '',
    List<String>? materialIds,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationException('Tên nhà cung cấp không được để trống');
    }
    final updates = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'note': note.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (materialIds != null) updates['materialIds'] = materialIds;
    await _suppliersCol.doc(id).update(updates);
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await _suppliersCol.doc(id).update({
      'isDeleted': true,
      'deletedAt': DateTime.now().toIso8601String(),
    });
  }

  // ─────────────────────────────────────────────────────────────
  // LEDGER
  // ─────────────────────────────────────────────────────────────
  @override
  Stream<List<SupplierLedgerEntry>> watchLedger(String supplierId) {
    return _ledgerCol(supplierId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = Map<String, dynamic>.from(d.data());
              data['id'] = d.id;
              return SupplierLedgerEntry.fromJson(data);
            }).toList());
  }

  Future<void> _updateSupplierDebt(
    Transaction txn,
    String supplierId,
    int deltaCents,
  ) async {
    final docRef = _suppliersCol.doc(supplierId);
    final snap = await txn.get(docRef);
    final current = (snap.data()?['currentDebtCacheCents'] as num?)?.toInt() ?? 0;
    txn.update(docRef, {
      'currentDebtCacheCents': current + deltaCents,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> createImportInvoice({
    required String supplierId,
    required String supplierName,
    required DateTime date,
    required List<SupplierLedgerItem> items,
    required int paidAmountCents,
    String note = '',
    int adjustCents = 0,
    String adjustNote = '',
  }) async {
    if (items.isEmpty) throw const ValidationException('Chưa có vật tư nào');
    final totalCents = items.fold<int>(0, (sum, item) => sum + item.lineTotalCents);
    final debtDelta = totalCents - paidAmountCents + adjustCents; // nợ thêm sau khi điều chỉnh

    final id  = _uuid.v4();
    final now = DateTime.now();
    final entry = SupplierLedgerEntry(
      id: id,
      supplierId: supplierId,
      type: SupplierLedgerEntryType.importInvoice,
      date: date,
      description: supplierName,
      amountCents: totalCents,
      paidAmountCents: paidAmountCents,
      createdAt: now,
      items: items,
      note: note,
    );

    await _firestore.runTransaction((txn) async {
      // Ghi ledger entry hóa đơn nhập
      txn.set(_ledgerCol(supplierId).doc(id), entry.toJson());

      // Nếu có điều chỉnh công nợ, ghi thêm ledger entry riêng
      if (adjustCents != 0) {
        final adjId = _uuid.v4();
        final adjDesc = adjustCents > 0
            ? (adjustNote.isNotEmpty ? adjustNote : 'Nợ cũ trước khi dùng app')
            : (adjustNote.isNotEmpty ? adjustNote : 'Đặt cọc / Ứng trước');
        final adjEntry = SupplierLedgerEntry(
          id: adjId,
          supplierId: supplierId,
          type: SupplierLedgerEntryType.adjustment,
          date: date,
          description: adjDesc,
          amountCents: adjustCents.abs(),
          paidAmountCents: 0,
          createdAt: now,
          note: adjustNote,
        );
        txn.set(_ledgerCol(supplierId).doc(adjId), adjEntry.toJson());
      }

      // Cập nhật debt cache
      await _updateSupplierDebt(txn, supplierId, debtDelta);
    });
  }

  @override
  Future<void> recordPayment({
    required String supplierId,
    required String supplierName,
    required int amountCents,
    required DateTime date,
    String note = '',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final entry = SupplierLedgerEntry(
      id: id,
      supplierId: supplierId,
      type: SupplierLedgerEntryType.payment,
      date: date,
      description: 'Thanh toán cho $supplierName',
      amountCents: amountCents,
      paidAmountCents: amountCents,
      createdAt: now,
      note: note,
    );

    await _firestore.runTransaction((txn) async {
      txn.set(_ledgerCol(supplierId).doc(id), entry.toJson());
      await _updateSupplierDebt(txn, supplierId, -amountCents); // payment reduces debt
    });
  }

  @override
  Future<void> recordAdjustment({
    required String supplierId,
    required String supplierName,
    required int amountCents,
    required DateTime date,
    String note = '',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final desc = amountCents > 0
        ? 'Nợ cũ trước khi dùng app'
        : 'Đặt cọc / Ứng trước';
    final entry = SupplierLedgerEntry(
      id: id,
      supplierId: supplierId,
      type: SupplierLedgerEntryType.adjustment,
      date: date,
      description: note.isNotEmpty ? note : desc,
      amountCents: amountCents.abs(),
      paidAmountCents: 0,
      createdAt: now,
      note: note,
    );

    await _firestore.runTransaction((txn) async {
      txn.set(_ledgerCol(supplierId).doc(id), entry.toJson());
      await _updateSupplierDebt(txn, supplierId, amountCents);
    });
  }

  @override
  Future<void> cancelLedgerEntry({
    required String supplierId,
    required SupplierLedgerEntry entry,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    // Reverse the debt impact
    int reverseDelta = 0;
    if (entry.type == SupplierLedgerEntryType.importInvoice) {
      final debtFromInvoice = entry.amountCents - entry.paidAmountCents;
      reverseDelta = -debtFromInvoice;
    } else if (entry.type == SupplierLedgerEntryType.payment) {
      reverseDelta = entry.amountCents; // restore debt
    } else if (entry.type == SupplierLedgerEntryType.adjustment) {
      reverseDelta = -entry.amountCents;
    }

    final cancelEntry = SupplierLedgerEntry(
      id: id,
      supplierId: supplierId,
      type: SupplierLedgerEntryType.cancellation,
      date: now,
      description: 'Hủy: ${entry.description}',
      amountCents: entry.amountCents,
      paidAmountCents: 0,
      createdAt: now,
      note: 'Hủy bút toán ngày ${entry.date.toIso8601String().substring(0, 10)}',
    );

    await _firestore.runTransaction((txn) async {
      txn.set(_ledgerCol(supplierId).doc(id), cancelEntry.toJson());
      if (reverseDelta != 0) {
        await _updateSupplierDebt(txn, supplierId, reverseDelta);
      }
    });
  }
}

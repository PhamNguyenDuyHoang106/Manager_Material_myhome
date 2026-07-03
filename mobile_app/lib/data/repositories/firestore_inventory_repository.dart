import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/inventory_transaction.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/firestore_paths.dart';
import 'firestore_material_repository.dart';

class FirestoreInventoryRepository implements InventoryRepository {
  FirestoreInventoryRepository(this._firestore, this._uid, this._materialRepo);

  final FirebaseFirestore _firestore;
  final String _uid;
  final FirestoreMaterialRepository _materialRepo;
  final _uuid = const Uuid();

  FirestorePaths get _paths => FirestorePaths(_uid);

  CollectionReference<Map<String, dynamic>> get _txCol =>
      _firestore.collection(_paths.inventoryTransactions);

  @override
  Stream<List<InventoryTransaction>> watchTransactions({String? materialId}) {
    Query<Map<String, dynamic>> q = _txCol.orderBy('createdAt', descending: true);
    if (materialId != null) {
      q = q.where('materialId', isEqualTo: materialId);
    }
    return q.snapshots().map(
      (snap) => snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return InventoryTransaction.fromJson(data);
      }).toList(),
    );
  }

  String _typeToString(InventoryTxType type) => switch (type) {
        InventoryTxType.import => 'import',
        InventoryTxType.invoiceDeduct => 'invoice_deduct',
        InventoryTxType.invoiceRollback => 'invoice_rollback',
        InventoryTxType.adjustment => 'adjustment',
      };

  @override
  Future<void> addStock({
    required String materialId,
    required double quantity,
    required int importPriceCents,
    String? note,
  }) async {
    if (quantity <= 0) throw const ValidationException('Số lượng phải lớn hơn 0');
    final material = await _materialRepo.getMaterial(materialId);
    if (material == null) throw const ValidationException('Vật liệu không tồn tại');

    final matRef = _firestore.collection(_paths.materials).doc(materialId);
    final matSnap = await matRef.get();
    final current = (matSnap.data()!['currentStock'] as num).toDouble();
    final newStock = current + quantity;

    final batch = _firestore.batch();
    batch.update(matRef, {
      'currentStock': newStock,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    final txRef = _txCol.doc(_uuid.v4());
    batch.set(txRef, {
      'materialId': materialId,
      'materialName': material.name,
      'type': _typeToString(InventoryTxType.import),
      'quantity': quantity,
      'stockAfter': newStock,
      'importPriceCents': importPriceCents,
      'note': note ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  @override
  Future<void> adjustStock({
    required String materialId,
    required double quantityDelta,
    required String note,
  }) async {
    final material = await _materialRepo.getMaterial(materialId);
    if (material == null) throw const ValidationException('Vật liệu không tồn tại');

    final matRef = _firestore.collection(_paths.materials).doc(materialId);
    final matSnap = await matRef.get();
    final current = (matSnap.data()!['currentStock'] as num).toDouble();
    final newStock = current + quantityDelta;
    if (newStock < 0) throw const StockException('Tồn kho không được âm');

    final batch = _firestore.batch();
    batch.update(matRef, {
      'currentStock': newStock,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    batch.set(_txCol.doc(_uuid.v4()), {
      'materialId': materialId,
      'materialName': material.name,
      'type': _typeToString(InventoryTxType.adjustment),
      'quantity': quantityDelta,
      'stockAfter': newStock,
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  Future<void> recordTransaction({
    required Transaction txn,
    required String materialId,
    required String materialName,
    required InventoryTxType type,
    required double quantity,
    required double stockAfter,
    String? referenceId,
  }) async {
    txn.set(_txCol.doc(_uuid.v4()), {
      'materialId': materialId,
      'materialName': materialName,
      'type': _typeToString(type),
      'quantity': quantity,
      'stockAfter': stockAfter,
      'referenceId': referenceId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/material.dart';
import '../../domain/repositories/material_repository.dart';
import '../datasources/firestore_paths.dart';
import '../datasources/hive_cache.dart';
import '../mappers/firestore_mapper.dart';

class FirestoreMaterialRepository implements MaterialRepository {
  FirestoreMaterialRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths(_uid).materials);

  @override
  Stream<List<StockMaterial>> watchMaterials() {
    return _col.where('isDeleted', isEqualTo: false).orderBy('name').snapshots().map((snap) {
      final list = snap.docs.map((d) => StockMaterial.fromJson(fromFirestore(d))).toList();
      HiveCache.instance.saveList(
        HiveCache.instance.materialsBox,
        list.map((m) => m.toJson()).toList(),
      );
      return list;
    });
  }

  @override
  Future<List<StockMaterial>> getMaterials({String query = ''}) async {
    try {
      final snap = await _col.where('isDeleted', isEqualTo: false).orderBy('name').get();
      var list = snap.docs.map((d) => StockMaterial.fromJson(fromFirestore(d))).toList();
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        list = list.where((m) => m.name.toLowerCase().contains(q)).toList();
      }
      HiveCache.instance.saveList(
        HiveCache.instance.materialsBox,
        list.map((m) => m.toJson()).toList(),
      );
      return list;
    } catch (_) {
      final cached = HiveCache.instance.loadList(HiveCache.instance.materialsBox);
      if (cached == null) rethrow;
      var list = cached.map(StockMaterial.fromJson).toList();
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        list = list.where((m) => m.name.toLowerCase().contains(q)).toList();
      }
      return list;
    }
  }

  @override
  Future<StockMaterial?> getMaterial(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return StockMaterial.fromJson(fromFirestore(doc));
  }

  @override
  Future<void> createMaterial({
    required String name,
    required String unit,
    required int importPriceCents,
    required int sellingPriceCents,
    required String categoryId,
    required String categoryName,
    required double minimumStock,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _col.doc(_uuid.v4()).set({
      'name': name,
      'unit': unit,
      'defaultImportPriceCents': importPriceCents,
      'defaultSellingPriceCents': sellingPriceCents,
      'currentStock': 0.0,
      'isDeleted': false,
      'createdAt': now,
      'updatedAt': now,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'minimumStock': minimumStock,
    });
  }

  @override
  Future<void> updateMaterial(StockMaterial material) async {
    await _col.doc(material.id).update({
      'name': material.name,
      'unit': material.unit,
      'defaultImportPriceCents': material.defaultImportPriceCents,
      'defaultSellingPriceCents': material.defaultSellingPriceCents,
      'updatedAt': DateTime.now().toIso8601String(),
      'categoryId': material.categoryId,
      'categoryName': material.categoryName,
      'minimumStock': material.minimumStock,
    });
  }

  @override
  Future<void> deleteMaterial(String id) async {
    final now = DateTime.now().toIso8601String();
    await _col.doc(id).update({
      'isDeleted': true,
      'deletedAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateStock(String materialId, double newStock) async {
    await _col.doc(materialId).update({
      'currentStock': newStock,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<double> getStock(String materialId, {Transaction? txn}) async {
    final ref = _col.doc(materialId);
    final doc = txn != null ? await txn.get(ref) : await ref.get();
    if (!doc.exists) throw Exception('Vật liệu không tồn tại');
    return (doc.data()!['currentStock'] as num).toDouble();
  }
}

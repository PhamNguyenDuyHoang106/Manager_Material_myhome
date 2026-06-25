import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/material_category.dart';
import '../../domain/repositories/material_category_repository.dart';
import '../datasources/firestore_paths.dart';
import '../mappers/firestore_mapper.dart';

class FirestoreMaterialCategoryRepository implements MaterialCategoryRepository {
  FirestoreMaterialCategoryRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;
  final _uuid = const Uuid();

  FirestorePaths get _paths => FirestorePaths(_uid);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_paths.materialCategories);

  @override
  Stream<List<MaterialCategory>> watchCategories() {
    return _col
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MaterialCategory.fromJson(fromFirestore(d))).toList());
  }

  @override
  Future<List<MaterialCategory>> getCategories() async {
    await seedDefaultCategoriesIfNeeded();
    final snap = await _col
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map((d) => MaterialCategory.fromJson(fromFirestore(d))).toList();
  }

  @override
  Future<void> createCategory({required String name}) async {
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();
    await _col.doc(id).set({
      'name': name,
      'isDeleted': false,
      'createdAt': now,
    });
  }

  @override
  Future<void> updateCategory(MaterialCategory category) async {
    await _col.doc(category.id).update({
      'name': category.name,
    });
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _col.doc(id).update({
      'isDeleted': true,
    });
  }

  @override
  Future<void> seedDefaultCategoriesIfNeeded() async {
    final snap = await _col.where('isDeleted', isEqualTo: false).limit(1).get();
    if (snap.docs.isEmpty) {
      final batch = _firestore.batch();
      final defaults = ['Cát', 'Đá', 'Xi Măng', 'Sắt Thép', 'Gạch', 'Khác'];
      final baseTime = DateTime.now();
      for (int i = 0; i < defaults.length; i++) {
        final name = defaults[i];
        final id = _uuid.v4();
        final createdAt = baseTime.add(Duration(seconds: i)).toIso8601String();
        batch.set(_col.doc(id), {
          'name': name,
          'isDeleted': false,
          'createdAt': createdAt,
        });
      }
      await batch.commit();
    }
  }
}

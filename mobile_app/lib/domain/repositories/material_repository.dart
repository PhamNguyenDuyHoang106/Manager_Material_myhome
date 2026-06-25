import '../entities/material.dart';

abstract class MaterialRepository {
  Stream<List<StockMaterial>> watchMaterials();
  Future<List<StockMaterial>> getMaterials({String query = ''});
  Future<StockMaterial?> getMaterial(String id);
  Future<void> createMaterial({
    required String name,
    required String unit,
    required int importPriceCents,
    required int sellingPriceCents,
    required String categoryId,
    required String categoryName,
    required double minimumStock,
  });
  Future<void> updateMaterial(StockMaterial material);
  Future<void> deleteMaterial(String id);
}

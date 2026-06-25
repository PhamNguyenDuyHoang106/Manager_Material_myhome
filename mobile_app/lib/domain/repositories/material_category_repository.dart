import '../entities/material_category.dart';

abstract class MaterialCategoryRepository {
  Stream<List<MaterialCategory>> watchCategories();
  Future<List<MaterialCategory>> getCategories();
  Future<void> createCategory({required String name});
  Future<void> updateCategory(MaterialCategory category);
  Future<void> deleteCategory(String id);
  Future<void> seedDefaultCategoriesIfNeeded();
}

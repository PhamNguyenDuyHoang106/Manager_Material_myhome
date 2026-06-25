import 'package:freezed_annotation/freezed_annotation.dart';

part 'material_category.freezed.dart';
part 'material_category.g.dart';

@freezed
class MaterialCategory with _$MaterialCategory {
  const factory MaterialCategory({
    required String id,
    required String name,
    @Default(false) bool isDeleted,
    required String createdAt,
  }) = _MaterialCategory;

  factory MaterialCategory.fromJson(Map<String, dynamic> json) => _$MaterialCategoryFromJson(json);
}

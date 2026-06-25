import 'package:freezed_annotation/freezed_annotation.dart';

part 'material.freezed.dart';
part 'material.g.dart';

@freezed
class StockMaterial with _$StockMaterial {
  const factory StockMaterial({
    required String id,
    required String name,
    required String unit,
    @JsonKey(name: 'defaultImportPriceCents') required int defaultImportPriceCents,
    @JsonKey(name: 'defaultSellingPriceCents') required int defaultSellingPriceCents,
    @JsonKey(name: 'currentStock') required double currentStock,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('') String categoryId,
    @Default('Khác') String categoryName,
    @Default(10.0) double minimumStock,
    DateTime? deletedAt,
  }) = _StockMaterial;

  factory StockMaterial.fromJson(Map<String, dynamic> json) => _$StockMaterialFromJson(json);
}

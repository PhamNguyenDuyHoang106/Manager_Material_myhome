// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StockMaterialImpl _$$StockMaterialImplFromJson(Map<String, dynamic> json) =>
    _$StockMaterialImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      defaultImportPriceCents: (json['defaultImportPriceCents'] as num).toInt(),
      defaultSellingPriceCents:
          (json['defaultSellingPriceCents'] as num).toInt(),
      currentStock: (json['currentStock'] as num).toDouble(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? 'Khác',
      minimumStock: (json['minimumStock'] as num?)?.toDouble() ?? 10.0,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$$StockMaterialImplToJson(_$StockMaterialImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'unit': instance.unit,
      'defaultImportPriceCents': instance.defaultImportPriceCents,
      'defaultSellingPriceCents': instance.defaultSellingPriceCents,
      'currentStock': instance.currentStock,
      'isDeleted': instance.isDeleted,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'minimumStock': instance.minimumStock,
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };

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
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
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
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MaterialCategoryImpl _$$MaterialCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$MaterialCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$MaterialCategoryImplToJson(
        _$MaterialCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isDeleted': instance.isDeleted,
      'createdAt': instance.createdAt,
    };

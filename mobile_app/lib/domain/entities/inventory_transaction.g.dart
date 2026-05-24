// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InventoryTransactionImpl _$$InventoryTransactionImplFromJson(
        Map<String, dynamic> json) =>
    _$InventoryTransactionImpl(
      id: json['id'] as String,
      materialId: json['materialId'] as String,
      materialName: json['materialName'] as String,
      type: const InventoryTxTypeConverter().fromJson(json['type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      stockAfter: (json['stockAfter'] as num).toDouble(),
      referenceId: json['referenceId'] as String?,
      note: json['note'] as String?,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$InventoryTransactionImplToJson(
        _$InventoryTransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'materialId': instance.materialId,
      'materialName': instance.materialName,
      'type': const InventoryTxTypeConverter().toJson(instance.type),
      'quantity': instance.quantity,
      'stockAfter': instance.stockAfter,
      'referenceId': instance.referenceId,
      'note': instance.note,
      'createdAt': instance.createdAt,
    };

const _$InventoryTxTypeEnumMap = {
  InventoryTxType.import: 'import',
  InventoryTxType.invoiceDeduct: 'invoiceDeduct',
  InventoryTxType.invoiceRollback: 'invoiceRollback',
  InventoryTxType.adjustment: 'adjustment',
};

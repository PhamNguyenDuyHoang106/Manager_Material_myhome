// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_ledger_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LedgerItemSnapshotImpl _$$LedgerItemSnapshotImplFromJson(
        Map<String, dynamic> json) =>
    _$LedgerItemSnapshotImpl(
      materialId: json['materialId'] as String,
      materialName: json['materialName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      sellingPriceCents: (json['sellingPriceCents'] as num).toInt(),
      lineTotalCents: (json['lineTotalCents'] as num).toInt(),
    );

Map<String, dynamic> _$$LedgerItemSnapshotImplToJson(
        _$LedgerItemSnapshotImpl instance) =>
    <String, dynamic>{
      'materialId': instance.materialId,
      'materialName': instance.materialName,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'sellingPriceCents': instance.sellingPriceCents,
      'lineTotalCents': instance.lineTotalCents,
    };

_$CustomerLedgerEntryImpl _$$CustomerLedgerEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$CustomerLedgerEntryImpl(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      invoiceId: json['invoiceId'] as String?,
      paymentId: json['paymentId'] as String?,
      date: DateTime.parse(json['date'] as String),
      type: $enumDecode(_$LedgerEntryTypeEnumMap, json['type']),
      description: json['description'] as String,
      amountCents: (json['amountCents'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      attachmentUrl: json['attachmentUrl'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map(
                  (e) => LedgerItemSnapshot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$CustomerLedgerEntryImplToJson(
        _$CustomerLedgerEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerId': instance.customerId,
      'invoiceId': instance.invoiceId,
      'paymentId': instance.paymentId,
      'date': instance.date.toIso8601String(),
      'type': _$LedgerEntryTypeEnumMap[instance.type]!,
      'description': instance.description,
      'amountCents': instance.amountCents,
      'createdAt': instance.createdAt.toIso8601String(),
      'attachmentUrl': instance.attachmentUrl,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

const _$LedgerEntryTypeEnumMap = {
  LedgerEntryType.sale: 'sale',
  LedgerEntryType.payment: 'payment',
  LedgerEntryType.cancellation: 'cancellation',
  LedgerEntryType.paymentReversal: 'paymentReversal',
};

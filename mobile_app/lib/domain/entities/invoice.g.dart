// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InvoiceItemImpl _$$InvoiceItemImplFromJson(Map<String, dynamic> json) =>
    _$InvoiceItemImpl(
      id: json['id'] as String,
      materialId: json['materialId'] as String,
      materialName: json['materialName'] as String,
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      sellingPriceCents: (json['sellingPriceCents'] as num).toInt(),
      lineTotalCents: (json['lineTotalCents'] as num).toInt(),
    );

Map<String, dynamic> _$$InvoiceItemImplToJson(_$InvoiceItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'materialId': instance.materialId,
      'materialName': instance.materialName,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'sellingPriceCents': instance.sellingPriceCents,
      'lineTotalCents': instance.lineTotalCents,
    };

_$InvoiceImpl _$$InvoiceImplFromJson(Map<String, dynamic> json) =>
    _$InvoiceImpl(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      invoiceDate: json['invoiceDate'] as String,
      totalAmountCents: (json['totalAmountCents'] as num).toInt(),
      paidAmountCents: (json['paidAmountCents'] as num?)?.toInt() ?? 0,
      status: const InvoiceStatusConverter().fromJson(json['status'] as String),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$InvoiceImplToJson(_$InvoiceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerId': instance.customerId,
      'customerName': instance.customerName,
      'invoiceDate': instance.invoiceDate,
      'totalAmountCents': instance.totalAmountCents,
      'paidAmountCents': instance.paidAmountCents,
      'status': const InvoiceStatusConverter().toJson(instance.status),
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

const _$InvoiceStatusEnumMap = {
  InvoiceStatus.unpaid: 'unpaid',
  InvoiceStatus.partiallyPaid: 'partiallyPaid',
  InvoiceStatus.paid: 'paid',
};

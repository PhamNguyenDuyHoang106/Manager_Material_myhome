// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentImpl _$$PaymentImplFromJson(Map<String, dynamic> json) =>
    _$PaymentImpl(
      id: json['id'] as String,
      invoiceId: json['invoiceId'] as String,
      customerId: json['customerId'] as String,
      amountCents: (json['amountCents'] as num).toInt(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      attachmentUrl: json['attachmentUrl'] as String? ?? '',
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$$PaymentImplToJson(_$PaymentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoiceId': instance.invoiceId,
      'customerId': instance.customerId,
      'amountCents': instance.amountCents,
      'paymentDate': instance.paymentDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'attachmentUrl': instance.attachmentUrl,
      'isDeleted': instance.isDeleted,
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };

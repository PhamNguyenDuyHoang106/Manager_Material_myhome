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
      paymentDate: json['paymentDate'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$PaymentImplToJson(_$PaymentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoiceId': instance.invoiceId,
      'customerId': instance.customerId,
      'amountCents': instance.amountCents,
      'paymentDate': instance.paymentDate,
      'createdAt': instance.createdAt,
    };

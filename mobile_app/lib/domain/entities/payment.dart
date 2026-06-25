import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String invoiceId,
    required String customerId,
    @JsonKey(name: 'amountCents') required int amountCents,
    required DateTime paymentDate,
    required DateTime createdAt,
    @Default('') String attachmentUrl,
    @Default(false) bool isDeleted,
    DateTime? deletedAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}

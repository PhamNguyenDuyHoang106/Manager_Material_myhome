import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

@freezed
class Customer with _$Customer {
  const factory Customer({
    required String id,
    required String name,
    required String phone,
    required String address,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('') String defaultNote,
    @Default('') String note,
    @Default(0) int currentDebtCacheCents,
    DateTime? deletedAt,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);
}

class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.note = '',
    this.materialIds = const [],
    this.currentDebtCacheCents = 0,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String address;
  final String note;
  final List<String> materialIds;
  final int currentDebtCacheCents;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Supplier.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }
    final rawIds = json['materialIds'] as List<dynamic>? ?? [];
    return Supplier(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      note: (json['note'] ?? '') as String,
      materialIds: rawIds.map((e) => e as String).toList(),
      currentDebtCacheCents: (json['currentDebtCacheCents'] as num?)?.toInt() ?? 
                             (json['totalDebtCents'] as num?)?.toInt() ?? 0,
      isDeleted: (json['isDeleted'] as bool?) ?? false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'note': note,
    'materialIds': materialIds,
    'currentDebtCacheCents': currentDebtCacheCents,
    'isDeleted': isDeleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? note,
    List<String>? materialIds,
    int? currentDebtCacheCents,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      note: note ?? this.note,
      materialIds: materialIds ?? this.materialIds,
      currentDebtCacheCents: currentDebtCacheCents ?? this.currentDebtCacheCents,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

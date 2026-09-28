/// Supplier ledger entry — mirrors CustomerLedgerEntry
enum SupplierLedgerEntryType {
  importInvoice,   // Đơn nhập hàng
  payment,         // Thanh toán cho NCC
  adjustment,      // Điều chỉnh (nợ cũ / đặt cọc)
  cancellation,    // Hủy đơn nhập
}

class SupplierLedgerItem {
  const SupplierLedgerItem({
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.quantity,
    required this.importPriceCents,
    required this.sellingPriceCents,
    required this.lineTotalCents,
  });

  final String materialId;
  final String materialName;
  final String unit;
  final double quantity;
  final int importPriceCents;
  final int sellingPriceCents;
  final int lineTotalCents;

  factory SupplierLedgerItem.fromJson(Map<String, dynamic> json) {
    return SupplierLedgerItem(
      materialId:       (json['materialId'] ?? '') as String,
      materialName:     (json['materialName'] ?? '') as String,
      unit:             (json['unit'] ?? '') as String,
      quantity:         (json['quantity'] as num?)?.toDouble() ?? 0,
      importPriceCents: (json['importPriceCents'] as num?)?.toInt() ?? 0,
      sellingPriceCents:(json['sellingPriceCents'] as num?)?.toInt() ?? 0,
      lineTotalCents:   (json['lineTotalCents'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'materialId':        materialId,
    'materialName':      materialName,
    'unit':              unit,
    'quantity':          quantity,
    'importPriceCents':  importPriceCents,
    'sellingPriceCents': sellingPriceCents,
    'lineTotalCents':    lineTotalCents,
  };
}

class SupplierLedgerEntry {
  const SupplierLedgerEntry({
    required this.id,
    required this.supplierId,
    required this.type,
    required this.date,
    required this.description,
    required this.amountCents,
    required this.paidAmountCents,
    required this.createdAt,
    this.items = const [],
    this.note = '',
  });

  final String id;
  final String supplierId;
  final SupplierLedgerEntryType type;
  final DateTime date;
  final String description;
  final int amountCents;
  final int paidAmountCents;
  final DateTime createdAt;
  final List<SupplierLedgerItem> items;
  final String note;

  static SupplierLedgerEntryType _typeFromString(String? s) {
    switch (s) {
      case 'payment':     return SupplierLedgerEntryType.payment;
      case 'adjustment':  return SupplierLedgerEntryType.adjustment;
      case 'cancellation':return SupplierLedgerEntryType.cancellation;
      default:            return SupplierLedgerEntryType.importInvoice;
    }
  }

  static String _typeToString(SupplierLedgerEntryType t) {
    switch (t) {
      case SupplierLedgerEntryType.payment:      return 'payment';
      case SupplierLedgerEntryType.adjustment:   return 'adjustment';
      case SupplierLedgerEntryType.cancellation: return 'cancellation';
      case SupplierLedgerEntryType.importInvoice:return 'importInvoice';
    }
  }

  factory SupplierLedgerEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    final rawItems = json['items'] as List<dynamic>? ?? [];
    return SupplierLedgerEntry(
      id:             (json['id'] ?? '') as String,
      supplierId:     (json['supplierId'] ?? '') as String,
      type:           _typeFromString(json['type'] as String?),
      date:           parseDate(json['date']),
      description:    (json['description'] ?? '') as String,
      amountCents:    (json['amountCents'] as num?)?.toInt() ?? 0,
      paidAmountCents:(json['paidAmountCents'] as num?)?.toInt() ?? 0,
      createdAt:      parseDate(json['createdAt']),
      items:          rawItems.map((e) => SupplierLedgerItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      note:           (json['note'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':             id,
    'supplierId':     supplierId,
    'type':           _typeToString(type),
    'date':           date.toIso8601String(),
    'description':    description,
    'amountCents':    amountCents,
    'paidAmountCents':paidAmountCents,
    'createdAt':      createdAt.toIso8601String(),
    'items':          items.map((e) => e.toJson()).toList(),
    'note':           note,
  };
}

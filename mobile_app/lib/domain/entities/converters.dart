import 'package:freezed_annotation/freezed_annotation.dart';

import 'inventory_transaction.dart';
import 'invoice.dart';

class InvoiceStatusConverter implements JsonConverter<InvoiceStatus, String> {
  const InvoiceStatusConverter();

  @override
  InvoiceStatus fromJson(String json) => switch (json) {
        'paid' => InvoiceStatus.paid,
        'partially_paid' => InvoiceStatus.partiallyPaid,
        'cancelled' => InvoiceStatus.cancelled,
        _ => InvoiceStatus.unpaid,
      };

  @override
  String toJson(InvoiceStatus object) => switch (object) {
        InvoiceStatus.paid => 'paid',
        InvoiceStatus.partiallyPaid => 'partially_paid',
        InvoiceStatus.unpaid => 'unpaid',
        InvoiceStatus.cancelled => 'cancelled',
      };
}

class InventoryTxTypeConverter implements JsonConverter<InventoryTxType, String> {
  const InventoryTxTypeConverter();

  @override
  InventoryTxType fromJson(String json) => switch (json) {
        'import' => InventoryTxType.import,
        'invoice_deduct' => InventoryTxType.invoiceDeduct,
        'invoice_rollback' => InventoryTxType.invoiceRollback,
        _ => InventoryTxType.adjustment,
      };

  @override
  String toJson(InventoryTxType object) => switch (object) {
        InventoryTxType.import => 'import',
        InventoryTxType.invoiceDeduct => 'invoice_deduct',
        InventoryTxType.invoiceRollback => 'invoice_rollback',
        InventoryTxType.adjustment => 'adjustment',
      };
}

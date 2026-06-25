import 'package:flutter_test/flutter_test.dart';
import 'package:material_manager_mobile/domain/entities/customer_ledger_entry.dart';

void main() {
  group('Ledger Calculation Tests', () {
    test('Calculate running balance with paymentReversal', () {
      final now = DateTime.now();
      final entries = [
        CustomerLedgerEntry(
          id: '1',
          customerId: 'cust-1',
          date: now.subtract(const Duration(days: 5)),
          type: LedgerEntryType.sale,
          description: 'Bán cát đá',
          amountCents: 5000000, // 5,000,000 cents = 50,000 VND
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        CustomerLedgerEntry(
          id: '2',
          customerId: 'cust-1',
          date: now.subtract(const Duration(days: 4)),
          type: LedgerEntryType.payment,
          description: 'Khách trả',
          amountCents: 2000000,
          createdAt: now.subtract(const Duration(days: 4)),
        ),
        CustomerLedgerEntry(
          id: '3',
          customerId: 'cust-1',
          date: now.subtract(const Duration(days: 3)),
          type: LedgerEntryType.paymentReversal,
          description: 'Hoàn tác thanh toán 2 triệu',
          amountCents: 2000000,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        CustomerLedgerEntry(
          id: '4',
          customerId: 'cust-1',
          date: now.subtract(const Duration(days: 2)),
          type: LedgerEntryType.cancellation,
          description: 'Hủy đơn hàng',
          amountCents: 1000000,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      // Simulate sequential calculation of running debt
      int running = 0;
      final balances = <String, int>{};
      for (final entry in entries) {
        if (entry.type == LedgerEntryType.sale) {
          running += entry.amountCents;
        } else if (entry.type == LedgerEntryType.payment) {
          running -= entry.amountCents;
        } else if (entry.type == LedgerEntryType.cancellation) {
          running -= entry.amountCents;
        } else if (entry.type == LedgerEntryType.paymentReversal) {
          running += entry.amountCents;
        }
        balances[entry.id] = running;
      }

      // Assertions
      expect(balances['1'], equals(5000000)); // Sale: +5,000,000
      expect(balances['2'], equals(3000000)); // Payment: -2,000,000 -> 3,000,000
      expect(balances['3'], equals(5000000)); // Reversal: +2,000,000 -> 5,000,000
      expect(balances['4'], equals(4000000)); // Cancellation: -1,000,000 -> 4,000,000
    });

    test('Identify overdue invoice (> 30 days)', () {
      final now = DateTime.now();

      final overdueDate = now.subtract(const Duration(days: 35));
      final recentDate = now.subtract(const Duration(days: 10));

      // Overdue threshold check helper
      bool isInvoiceOverdue(DateTime invoiceDate, int remainingCents) {
        final age = now.difference(invoiceDate).inDays;
        return age > 30 && remainingCents > 0;
      }

      // 1. Overdue with remaining debt -> True
      expect(isInvoiceOverdue(overdueDate, 1000), isTrue);

      // 2. Overdue but fully paid -> False
      expect(isInvoiceOverdue(overdueDate, 0), isFalse);

      // 3. Not overdue but unpaid -> False
      expect(isInvoiceOverdue(recentDate, 1000), isFalse);
    });
  });
}

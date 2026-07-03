import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/invoice.dart';
import 'invoice_form_screen.dart';
import 'trash_invoices_screen.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final invoicesAsync = ref.watch(invoicesStreamProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Thùng rác',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrashInvoicesScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên khách...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _search.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: invoicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                final invoices = list.cast<Invoice>();
                if (invoices.isEmpty) {
                  return const EmptyState(
                      icon: Icons.receipt_long_outlined, title: 'Chưa có hóa đơn');
                }

                // Sort by invoiceDate descending
                final sorted = [...invoices]
                  ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

                // Group by date (yyyy-MM-dd)
                final Map<String, List<Invoice>> grouped = {};
                for (final inv in sorted) {
                  final key = DateFormat('yyyy-MM-dd').format(inv.invoiceDate);
                  grouped.putIfAbsent(key, () => []).add(inv);
                }
                final days = grouped.keys.toList(); // already sorted desc

                // Flat list: date-string header | Invoice objects
                final items = <dynamic>[];
                for (final day in days) {
                  items.add(day);
                  items.addAll(grouped[day]!);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];

                    // ── Date header ────────────────────────────────
                    if (item is String) {
                      final date = DateTime.parse(item);
                      final label = DateFormat('dd/MM/yyyy').format(date);
                      return Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                      );
                    }

                    // ── Invoice card ───────────────────────────────
                    final inv = item as Invoice;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        title: Text(inv.customerName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${MoneyUtils.format(inv.totalAmountCents)} | Còn: ${MoneyUtils.format(inv.remainingCents)} | ${_statusLabel(inv.status)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Xóa hóa đơn',
                          onPressed: () async {
                            final ok = await showConfirmDialog(
                              context,
                              title: 'Xóa hóa đơn?',
                              message:
                                  'Hóa đơn này sẽ được đẩy vào Thùng rác.',
                            );
                            if (ok == true) {
                              try {
                                await ref
                                    .read(invoiceRepositoryProvider)
                                    ?.deleteInvoice(inv.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Đã chuyển hóa đơn vào Thùng rác')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) showErrorSnackBar(context, e);
                              }
                            }
                          },
                        ),
                        onTap: () => context.push('/invoices/${inv.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(InvoiceStatus s) => switch (s) {
        InvoiceStatus.paid => 'Đã TT',
        InvoiceStatus.partiallyPaid => 'TT một phần',
        InvoiceStatus.unpaid => 'Chưa TT',
        InvoiceStatus.cancelled => 'Đã hủy',
      };
}

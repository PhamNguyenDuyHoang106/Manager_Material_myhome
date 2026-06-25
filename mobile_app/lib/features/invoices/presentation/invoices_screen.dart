import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../domain/entities/invoice.dart';
import 'invoice_form_screen.dart';

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
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
              );
            },
          ),
        ],
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
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() {})),
              ),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: invoicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                final invoices = list.cast<Invoice>();
                if (invoices.isEmpty) {
                  return const EmptyState(icon: Icons.receipt_long_outlined, title: 'Chưa có hóa đơn');
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: invoices.length,
                  itemBuilder: (_, i) {
                    final inv = invoices[i];
                    return Card(
                      child: ListTile(
                        title: Text(inv.customerName),
                        subtitle: Text(
                          '${MoneyUtils.format(inv.totalAmountCents)} | Còn: ${MoneyUtils.format(inv.remainingCents)} | ${_statusLabel(inv.status)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
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

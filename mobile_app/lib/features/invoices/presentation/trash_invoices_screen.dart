import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/invoice.dart';

class TrashInvoicesScreen extends ConsumerStatefulWidget {
  const TrashInvoicesScreen({super.key});

  @override
  ConsumerState<TrashInvoicesScreen> createState() => _TrashInvoicesScreenState();
}

class _TrashInvoicesScreenState extends ConsumerState<TrashInvoicesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final deletedInvoicesAsync = ref.watch(deletedInvoicesStreamProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thùng rác hóa đơn'),
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
            child: deletedInvoicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return const EmptyState(
                    icon: Icons.delete_outline,
                    title: 'Thùng rác trống',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: invoices.length,
                  itemBuilder: (_, i) {
                    final inv = invoices[i];
                    return Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        title: Text(
                          inv.customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${MoneyUtils.format(inv.totalAmountCents)} | Còn: ${MoneyUtils.format(inv.remainingCents)}',
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          tooltip: 'Xóa vĩnh viễn',
                          onPressed: () async {
                            final ok = await showConfirmDialog(
                              context,
                              title: 'Xóa vĩnh viễn?',
                              message: 'Xóa vĩnh viễn hóa đơn của "${inv.customerName}" khỏi hệ thống? Thao tác này KHÔNG thể hoàn tác.',
                            );
                            if (ok == true) {
                              try {
                                await ref.read(invoiceRepositoryProvider)?.permanentlyDeleteInvoice(inv.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã xóa vĩnh viễn hóa đơn')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) showErrorSnackBar(context, e);
                              }
                            }
                          },
                        ),
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
}

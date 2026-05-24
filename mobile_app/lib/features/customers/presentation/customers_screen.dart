import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/customer.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final query = _search.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Khách hàng')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Tìm tên hoặc SĐT...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _search.clear();
                        setState(() {});
                      })
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                var customers = list.cast<Customer>();
                if (query.isNotEmpty) {
                  customers = customers
                      .where((c) => c.name.toLowerCase().contains(query) || c.phone.contains(query))
                      .toList();
                }
                if (customers.isEmpty) {
                  return const EmptyState(icon: Icons.people_outline, title: 'Chưa có khách hàng');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: customers.length,
                  itemBuilder: (_, i) {
                    final c = customers[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?')),
                        title: Text(c.name),
                        subtitle: Text('${c.phone}\n${c.address}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        onTap: () => _showDetail(context, c),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                            const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                          ],
                          onSelected: (v) async {
                            if (v == 'edit') _showCustomerForm(context, customer: c);
                            if (v == 'delete') await _deleteCustomer(context, c);
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

  Future<void> _showCustomerForm(BuildContext context, {Customer? customer}) async {
    final name = TextEditingController(text: customer?.name ?? '');
    final phone = TextEditingController(text: customer?.phone ?? '');
    final address = TextEditingController(text: customer?.address ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(customer == null ? 'Thêm khách hàng' : 'Sửa khách hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên *')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'SĐT')),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Địa chỉ')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              final repo = ref.read(customerRepositoryProvider);
              if (repo == null) return;
              try {
                if (customer == null) {
                  await repo.createCustomer(
                    name: name.text.trim(),
                    phone: phone.text.trim(),
                    address: address.text.trim(),
                  );
                } else {
                  await repo.updateCustomer(customer.copyWith(
                    name: name.text.trim(),
                    phone: phone.text.trim(),
                    address: address.text.trim(),
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) showErrorSnackBar(ctx, e);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetail(BuildContext context, Customer customer) async {
    final repo = ref.read(customerRepositoryProvider);
    if (repo == null) return;
    final summary = await repo.getCustomerSummary(customer.id);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.name, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Tổng nợ: ${MoneyUtils.format(summary.totalDebtCents)}',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontWeight: FontWeight.bold)),
            Text('Hóa đơn: ${summary.invoiceCount}'),
            Text('Thanh toán: ${summary.paymentCount}'),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCustomer(BuildContext context, Customer customer) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa khách hàng?',
      message: 'Bạn có chắc muốn xóa "${customer.name}"?',
    );
    if (ok != true) return;
    try {
      await ref.read(customerRepositoryProvider)?.deleteCustomer(customer.id);
      showSuccessSnackBar(context, 'Đã xóa khách hàng');
    } catch (e) {
      showErrorSnackBar(context, e);
    }
  }
}

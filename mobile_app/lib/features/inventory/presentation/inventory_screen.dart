import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/inventory_transaction.dart';
import '../../../domain/entities/material.dart' show StockMaterial;

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(inventoryTxStreamProvider);
    final materialsAsync = ref.watch(materialsStreamProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kho hàng'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tồn kho'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showImportDialog(context, ref, materialsAsync.valueOrNull ?? []),
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            materialsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                final materials = list.cast<StockMaterial>();
                if (materials.isEmpty) {
                  return const EmptyState(icon: Icons.inventory_2_outlined, title: 'Chưa có vật liệu');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: materials.length,
                  itemBuilder: (_, i) {
                    final m = materials[i];
                    return Card(
                      child: ListTile(
                        title: Text(m.name),
                        subtitle: Text('${m.currentStock} ${m.unit}'),
                        trailing: Text(MoneyUtils.format(m.defaultImportPriceCents), style: const TextStyle(fontSize: 12)),
                      ),
                    );
                  },
                );
              },
            ),
            txAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                final txs = list.cast<InventoryTransaction>();
                if (txs.isEmpty) {
                  return const EmptyState(icon: Icons.history, title: 'Chưa có giao dịch');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: txs.length,
                  itemBuilder: (_, i) {
                    final tx = txs[i];
                    final isAdd = tx.quantity > 0;
                    return Card(
                      child: ListTile(
                        leading: Icon(isAdd ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isAdd ? Colors.green : Colors.red),
                        title: Text(tx.materialName),
                        subtitle: Text('${AppDateUtils.formatDisplay(tx.createdAt)} | Sau: ${tx.stockAfter}'),
                        trailing: Text(
                          '${isAdd ? '+' : ''}${tx.quantity}',
                          style: TextStyle(color: isAdd ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref, List<dynamic> materialsRaw) async {
    final materials = materialsRaw.cast<StockMaterial>();
    if (materials.isEmpty) {
      showErrorSnackBar(context, 'Thêm vật liệu trước khi nhập kho');
      return;
    }

    StockMaterial? selected = materials.first;
    final qty = TextEditingController();
    final price = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nhập kho'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<StockMaterial>(
                value: selected,
                decoration: const InputDecoration(labelText: 'Vật liệu'),
                items: materials
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                    .toList(),
                onChanged: (v) => setState(() => selected = v),
              ),
              TextField(
                controller: qty,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Số lượng *'),
              ),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Giá nhập'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                final repo = ref.read(inventoryRepositoryProvider);
                if (repo == null || selected == null) return;
                try {
                  await repo.addStock(
                    materialId: selected!.id,
                    quantity: double.parse(qty.text),
                    importPriceCents: MoneyUtils.toCents(double.tryParse(price.text) ?? 0),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  showSuccessSnackBar(context, 'Đã nhập kho');
                } catch (e) {
                  if (ctx.mounted) showErrorSnackBar(ctx, e);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

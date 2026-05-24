import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/material.dart' show StockMaterial;

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsStreamProvider);
    final query = _search.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Vật liệu')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Tìm vật liệu...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: materialsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                var materials = list.cast<StockMaterial>();
                if (query.isNotEmpty) {
                  materials = materials.where((m) => m.name.toLowerCase().contains(query)).toList();
                }
                if (materials.isEmpty) {
                  return const EmptyState(icon: Icons.category_outlined, title: 'Chưa có vật liệu');
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: materials.length,
                  itemBuilder: (_, i) {
                    final m = materials[i];
                    final lowStock = m.currentStock <= AppConstants.lowStockThreshold;
                    return Card(
                      child: ListTile(
                        title: Text(m.name),
                        subtitle: Text(
                          'Tồn: ${m.currentStock} ${m.unit} | Bán: ${MoneyUtils.format(m.defaultSellingPriceCents)}',
                        ),
                        leading: CircleAvatar(
                          backgroundColor: lowStock ? Colors.orange.shade100 : null,
                          child: Icon(
                            lowStock ? Icons.warning : Icons.inventory_2,
                            color: lowStock ? Colors.orange.shade800 : null,
                          ),
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                            const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                          ],
                          onSelected: (v) async {
                            if (v == 'edit') _showForm(context, material: m);
                            if (v == 'delete') await _delete(context, m);
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

  Future<void> _showForm(BuildContext context, {StockMaterial? material}) async {
    final name = TextEditingController(text: material?.name ?? '');
    final unit = TextEditingController(text: material?.unit ?? 'cái');
    final importPrice = TextEditingController(
      text: material != null ? MoneyUtils.fromCents(material.defaultImportPriceCents).toString() : '',
    );
    final sellPrice = TextEditingController(
      text: material != null ? MoneyUtils.fromCents(material.defaultSellingPriceCents).toString() : '',
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(material == null ? 'Thêm vật liệu' : 'Sửa vật liệu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên *')),
              TextField(controller: unit, decoration: const InputDecoration(labelText: 'Đơn vị')),
              TextField(
                controller: importPrice,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Giá nhập'),
              ),
              TextField(
                controller: sellPrice,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Giá bán'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              final repo = ref.read(materialRepositoryProvider);
              if (repo == null || name.text.trim().isEmpty) return;
              try {
                final importCents = MoneyUtils.toCents(double.tryParse(importPrice.text) ?? 0);
                final sellCents = MoneyUtils.toCents(double.tryParse(sellPrice.text) ?? 0);
                if (material == null) {
                  await repo.createMaterial(
                    name: name.text.trim(),
                    unit: unit.text.trim(),
                    importPriceCents: importCents,
                    sellingPriceCents: sellCents,
                  );
                } else {
                  await repo.updateMaterial(material.copyWith(
                    name: name.text.trim(),
                    unit: unit.text.trim(),
                    defaultImportPriceCents: importCents,
                    defaultSellingPriceCents: sellCents,
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

  Future<void> _delete(BuildContext context, StockMaterial material) async {
    final ok = await showConfirmDialog(context, title: 'Xóa vật liệu?', message: 'Xóa "${material.name}"?');
    if (ok != true) return;
    try {
      await ref.read(materialRepositoryProvider)?.deleteMaterial(material.id);
      showSuccessSnackBar(context, 'Đã xóa');
    } catch (e) {
      showErrorSnackBar(context, e);
    }
  }
}

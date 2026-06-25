import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/material.dart' show StockMaterial;
import '../../../domain/entities/material_category.dart';

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  final _search = TextEditingController();
  String _selectedCategoryId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(materialCategoryRepositoryProvider)?.getCategories();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final query = _search.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vật liệu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Quản lý nhóm',
            onPressed: () => _manageCategories(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Tìm vật liệu...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          categoriesAsync.when(
            loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) {
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _selectedCategoryId.isEmpty,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategoryId = '');
                          }
                        },
                      ),
                    ),
                    ...cats.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cat.name),
                          selected: _selectedCategoryId == cat.id,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = selected ? cat.id : '';
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
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
                if (_selectedCategoryId.isNotEmpty) {
                  materials = materials.where((m) => m.categoryId == _selectedCategoryId).toList();
                }
                if (materials.isEmpty) {
                  return const EmptyState(icon: Icons.category_outlined, title: 'Chưa có vật liệu');
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: materials.length,
                  itemBuilder: (_, i) {
                    final m = materials[i];
                    final lowStock = m.currentStock <= m.minimumStock;
                    return Card(
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(m.name),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                m.categoryName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Tồn: ${m.currentStock} ${m.unit} | Bán: ${MoneyUtils.format(m.defaultSellingPriceCents)}',
                            ),
                            if (lowStock) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.warning, size: 14, color: Colors.orange.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sắp hết hàng (Tối thiểu: ${m.minimumStock} ${m.unit})',
                                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ],
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

  Future<void> _manageCategories(BuildContext context) async {
    final newCat = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final categoriesAsync = ref.watch(categoriesStreamProvider);
          return AlertDialog(
            title: const Text('Quản lý nhóm vật liệu'),
            content: SizedBox(
              width: double.maxFinite,
              height: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newCat,
                          decoration: const InputDecoration(
                            hintText: 'Tên nhóm mới...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () async {
                          final name = newCat.text.trim();
                          if (name.isNotEmpty) {
                            await ref.read(materialCategoryRepositoryProvider)?.createCategory(name: name);
                            newCat.clear();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: categoriesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('$e')),
                      data: (cats) {
                        if (cats.isEmpty) {
                          return const Center(child: Text('Chưa có nhóm vật liệu'));
                        }
                        return ListView.builder(
                          itemCount: cats.length,
                          itemBuilder: (_, i) {
                            final cat = cats[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(cat.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _editCategory(context, cat),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    onPressed: () async {
                                      final ok = await showConfirmDialog(
                                        context,
                                        title: 'Xóa nhóm?',
                                        message: 'Xóa nhóm "${cat.name}"? Vật liệu cũ vẫn giữ nguyên nhóm này.',
                                      );
                                      if (ok == true) {
                                        await ref.read(materialCategoryRepositoryProvider)?.deleteCategory(cat.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editCategory(BuildContext context, MaterialCategory cat) async {
    final name = TextEditingController(text: cat.name);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa tên nhóm'),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Tên nhóm *'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isNotEmpty) {
                await ref.read(materialCategoryRepositoryProvider)?.updateCategory(
                      cat.copyWith(name: name.text.trim()),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Lưu'),
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
    final minStock = TextEditingController(
      text: material != null ? material.minimumStock.toString() : '10.0',
    );

    final categories = ref.read(categoriesStreamProvider).valueOrNull ?? [];
    MaterialCategory? selectedCategory;
    
    if (material != null && material.categoryId.isNotEmpty) {
      try {
        selectedCategory = categories.firstWhere((c) => c.id == material.categoryId);
      } catch (_) {}
    }
    
    selectedCategory ??= categories.isNotEmpty ? categories.first : null;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(material == null ? 'Thêm vật liệu' : 'Sửa vật liệu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên *')),
                DropdownButtonFormField<MaterialCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Nhóm vật liệu *'),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedCategory = v;
                    });
                  },
                ),
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
                TextField(
                  controller: minStock,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Mức cảnh báo tồn tối thiểu'),
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
                  final minimumStockValue = double.tryParse(minStock.text) ?? 10.0;
                  final categoryId = selectedCategory?.id ?? '';
                  final categoryName = selectedCategory?.name ?? 'Khác';

                  if (material == null) {
                    await repo.createMaterial(
                      name: name.text.trim(),
                      unit: unit.text.trim(),
                      importPriceCents: importCents,
                      sellingPriceCents: sellCents,
                      categoryId: categoryId,
                      categoryName: categoryName,
                      minimumStock: minimumStockValue,
                    );
                  } else {
                    await repo.updateMaterial(material.copyWith(
                      name: name.text.trim(),
                      unit: unit.text.trim(),
                      defaultImportPriceCents: importCents,
                      defaultSellingPriceCents: sellCents,
                      categoryId: categoryId,
                      categoryName: categoryName,
                      minimumStock: minimumStockValue,
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


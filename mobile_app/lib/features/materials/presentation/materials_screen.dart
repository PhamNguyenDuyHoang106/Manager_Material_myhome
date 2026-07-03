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
                              'Giá bán: ${MoneyUtils.format(m.defaultSellingPriceCents)} / ${m.unit}',
                            ),
                          ],
                        ),
                        leading: const CircleAvatar(
                          child: Icon(Icons.layers_outlined),
                        ),
                        onTap: () => _showMaterialDetail(context, m),
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

  Future<void> _showMaterialDetail(BuildContext context, StockMaterial m) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    m.categoryName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _detailRow(context, 'Đơn vị tính', m.unit),
            _detailRow(context, 'Giá nhập', MoneyUtils.format(m.defaultImportPriceCents)),
            _detailRow(context, 'Giá bán', MoneyUtils.format(m.defaultSellingPriceCents)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa vật liệu'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showForm(context, material: m);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _delete(context, m);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
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
    final importPrice = TextEditingController(
      text: material != null ? MoneyUtils.formatInt(MoneyUtils.fromCents(material.defaultImportPriceCents).toInt()) : '',
    );
    final sellPrice = TextEditingController(
      text: material != null ? MoneyUtils.formatInt(MoneyUtils.fromCents(material.defaultSellingPriceCents).toInt()) : '',
    );

    const unitOptions = ['khối', 'viên', 'cây', 'kg', 'tấn'];

    final categories = (ref.read(categoriesStreamProvider).valueOrNull ?? []).cast<MaterialCategory>();
    MaterialCategory? selectedCategory;
    String? selectedUnit = material?.unit;

    if (material != null && material.categoryId.isNotEmpty) {
      try {
        selectedCategory = categories.firstWhere((c) => c.id == material.categoryId);
      } catch (_) {}
    }

    selectedCategory ??= categories.isNotEmpty ? categories.first : null;

    // Validate initial unit
    if (selectedUnit != null && !unitOptions.contains(selectedUnit)) {
      selectedUnit = null;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(material == null ? 'Thêm vật liệu' : 'Sửa vật liệu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tên', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tên vật liệu',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Nhóm vật liệu', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<MaterialCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (v) {
                    setDialogState(() => selectedCategory = v);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Đơn vị tính', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  hint: const Text('Chọn đơn vị'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) {
                    setDialogState(() => selectedUnit = v);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Giá nhập', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: importPrice,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsFormatter()],
                  decoration: const InputDecoration(
                    hintText: 'Nhập giá nhập',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Giá bán', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: sellPrice,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsFormatter()],
                  decoration: const InputDecoration(
                    hintText: 'Nhập giá bán',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
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
                if (selectedUnit == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn đơn vị tính')),
                  );
                  return;
                }
                try {
                  final importCents = MoneyUtils.toCents(double.tryParse(importPrice.text.replaceAll('.', '')) ?? 0);
                  final sellCents = MoneyUtils.toCents(double.tryParse(sellPrice.text.replaceAll('.', '')) ?? 0);
                  const minimumStockValue = 0.0;
                  final categoryId = selectedCategory?.id ?? '';
                  final categoryName = selectedCategory?.name ?? 'Khác';

                  if (material == null) {
                    await repo.createMaterial(
                      name: name.text.trim(),
                      unit: selectedUnit!,
                      importPriceCents: importCents,
                      sellingPriceCents: sellCents,
                      categoryId: categoryId,
                      categoryName: categoryName,
                      minimumStock: minimumStockValue,
                    );
                  } else {
                    await repo.updateMaterial(material.copyWith(
                      name: name.text.trim(),
                      unit: selectedUnit!,
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


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/material.dart' show StockMaterial;
import '../../../domain/entities/supplier.dart';

// ─────────────────────────────────────────────────────────────
// Dialog Thêm / Sửa nhà cung cấp — khớp y hệt screenshot
// ─────────────────────────────────────────────────────────────
Future<void> showSupplierFormDialog(
  BuildContext context,
  WidgetRef ref, {
  Supplier? supplier,
}) async {
  final nameCtrl  = TextEditingController(text: supplier?.name ?? '');
  final phoneCtrl = TextEditingController(text: supplier?.phone ?? '');
  final selectedIds = <String>{...?supplier?.materialIds};

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final materialsAsync = ref.watch(materialsStreamProvider);
        final materials = materialsAsync.valueOrNull?.cast<StockMaterial>() ?? [];

        return StatefulBuilder(
          builder: (ctx, setState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tiêu đề ──
                  Text(
                    supplier == null ? 'Thêm nhà cung cấp' : 'Sửa nhà cung cấp',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // ── Tên ──
                  const Text('Tên nhà cung cấp *',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên nhà cung cấp...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── SĐT ──
                  const Text('Số điện thoại',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Nhập số điện thoại...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Loại vật tư cung cấp ──
                  const Text('Loại vật tư cung cấp',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  const Text(
                    'Chọn các vật tư mà nhà cung cấp này cung ứng',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),

                  // Danh sách vật tư — cuộn được nếu dài
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: materials.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Chưa có vật tư nào',
                                style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: materials.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (_, i) {
                              final m = materials[i];
                              final checked = selectedIds.contains(m.id);
                              return CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                                title: Text(m.name,
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w500)),
                                subtitle: Text(m.unit,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                value: checked,
                                controlAffinity: ListTileControlAffinity.trailing,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      selectedIds.add(m.id);
                                    } else {
                                      selectedIds.remove(m.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),

                  // ── Actions ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final repo = ref.read(supplierRepositoryProvider);
                          if (repo == null) return;
                          try {
                            if (supplier == null) {
                              await repo.createSupplier(
                                name:        nameCtrl.text.trim(),
                                phone:       phoneCtrl.text.trim(),
                                materialIds: selectedIds.toList(),
                              );
                            } else {
                              await repo.updateSupplier(
                                id:          supplier.id,
                                name:        nameCtrl.text.trim(),
                                phone:       phoneCtrl.text.trim(),
                                materialIds: selectedIds.toList(),
                              );
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
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Màn hình chính: Nhập kho = Danh sách Nhà cung cấp
// ─────────────────────────────────────────────────────────────
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersStreamProvider(null));
    final query = _search.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Nhà cung cấp')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSupplierFormDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm — y chang màn Khách hàng
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Tìm tên hoặc SĐT nhà cung cấp...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: suppliersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                var suppliers = list;
                if (query.isNotEmpty) {
                  suppliers = suppliers
                      .where((s) =>
                          s.name.toLowerCase().contains(query) ||
                          s.phone.contains(query))
                      .toList();
                }
                if (suppliers.isEmpty) {
                  return const EmptyState(
                    icon: Icons.store_outlined,
                    title: 'Chưa có nhà cung cấp',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: suppliers.length,
                  itemBuilder: (_, i) {
                    final s          = suppliers[i];
                    final debtCents  = s.currentDebtCacheCents;
                    final isPositive = debtCents > 0;

                    return Card(
                      child: ListTile(
                        onTap: () => context.push('/inventory/${s.id}'),
                        leading: CircleAvatar(
                          child: Text(
                            s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                          ),
                        ),
                        title: Text(
                          s.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: s.phone.isNotEmpty ? Text(s.phone) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (debtCents != 0)
                              Text(
                                MoneyUtils.format(debtCents),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? Colors.red : Colors.green,
                                  fontSize: 13,
                                ),
                              ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Sửa'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    title: Text('Xóa',
                                        style:
                                            TextStyle(color: Colors.red)),
                                  ),
                                ),
                              ],
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  showSupplierFormDialog(context, ref,
                                      supplier: s);
                                } else if (v == 'delete') {
                                  await _deleteSupplier(context, s);
                                }
                              },
                            ),
                          ],
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

  Future<void> _deleteSupplier(BuildContext context, Supplier supplier) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa nhà cung cấp?',
      message: 'Bạn có chắc muốn xóa "${supplier.name}"?',
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(supplierRepositoryProvider)?.deleteSupplier(supplier.id);
      if (mounted) showSuccessSnackBar(context, 'Đã xóa nhà cung cấp');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }
}

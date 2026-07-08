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
  bool _isSelectMode = false;
  final Set<String> _selectedInvoiceIds = {};
  List<Invoice> _currentInvoices = [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _deleteSelectedInvoices(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa vĩnh viễn?',
      message: 'Xóa vĩnh viễn ${_selectedInvoiceIds.length} hóa đơn đã chọn khỏi hệ thống? Thao tác này KHÔNG thể hoàn tác.',
    );
    if (ok != true) return;
    if (!context.mounted) return;

    final repo = ref.read(invoiceRepositoryProvider);
    if (repo == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    int successCount = 0;
    final errors = <String>[];

    for (final id in _selectedInvoiceIds) {
      try {
        await repo.permanentlyDeleteInvoice(id);
        successCount++;
      } catch (e) {
        errors.add(e.toString());
      }
    }

    if (context.mounted) {
      Navigator.of(context).pop(); // Dismiss loading
      setState(() {
        _selectedInvoiceIds.clear();
        _isSelectMode = false;
      });

      if (errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa vĩnh viễn $successCount hóa đơn')),
        );
      } else {
        showErrorSnackBar(context, 'Có lỗi xảy ra khi xóa một số hóa đơn');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final deletedInvoicesAsync = ref.watch(deletedInvoicesStreamProvider(query));

    return Scaffold(
      appBar: _isSelectMode
          ? AppBar(
              title: Text('Đã chọn ${_selectedInvoiceIds.length}'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Hủy chọn',
                onPressed: () {
                  setState(() {
                    _selectedInvoiceIds.clear();
                    _isSelectMode = false;
                  });
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Chọn tất cả',
                  onPressed: () {
                    setState(() {
                      _selectedInvoiceIds.addAll(_currentInvoices.map((i) => i.id));
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'Xóa vĩnh viễn đã chọn',
                  onPressed: () => _deleteSelectedInvoices(context),
                ),
              ],
            )
          : AppBar(
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
                _currentInvoices = invoices;
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
                    final isSelected = _selectedInvoiceIds.contains(inv.id);
                    return Card(
                      color: isSelected ? Colors.red.shade100 : Colors.red.shade50,
                      child: ListTile(
                        selected: isSelected,
                        leading: _isSelectMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedInvoiceIds.add(inv.id);
                                    } else {
                                      _selectedInvoiceIds.remove(inv.id);
                                      if (_selectedInvoiceIds.isEmpty) {
                                        _isSelectMode = false;
                                      }
                                    }
                                  });
                                },
                              )
                            : null,
                        title: Text(
                          inv.customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${MoneyUtils.format(inv.totalAmountCents)} | Còn: ${MoneyUtils.format(inv.remainingCents)}',
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                        ),
                        onTap: () {
                          if (_isSelectMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedInvoiceIds.remove(inv.id);
                                if (_selectedInvoiceIds.isEmpty) {
                                  _isSelectMode = false;
                                }
                              } else {
                                _selectedInvoiceIds.add(inv.id);
                              }
                            });
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectMode) {
                            setState(() {
                              _isSelectMode = true;
                              _selectedInvoiceIds.add(inv.id);
                            });
                          }
                        },
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

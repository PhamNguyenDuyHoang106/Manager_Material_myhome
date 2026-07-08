import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
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
      title: 'Xóa hóa đơn?',
      message: 'Đã chọn ${_selectedInvoiceIds.length} hóa đơn. Di chuyển vào Thùng rác?',
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
        await repo.deleteInvoice(id);
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
          SnackBar(content: Text('Đã chuyển $successCount hóa đơn vào Thùng rác')),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Kết quả xóa'),
            content: Text(
              'Đã chuyển thành công: $successCount hóa đơn.\n\n'
              'Thất bại: ${errors.length} hóa đơn.\n'
              'Lý do: Hóa đơn đã có thanh toán liên quan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final invoicesAsync = ref.watch(invoicesStreamProvider(query));

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
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Xóa đã chọn',
                  onPressed: () => _deleteSelectedInvoices(context),
                ),
              ],
            )
          : AppBar(
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
      floatingActionButton: _isSelectMode
          ? null
          : FloatingActionButton(
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
                _currentInvoices = invoices;
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
                    final isSelected = _selectedInvoiceIds.contains(inv.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
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
                        title: Text(inv.customerName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${MoneyUtils.format(inv.totalAmountCents)} | Còn: ${MoneyUtils.format(inv.remainingCents)} | ${_statusLabel(inv.status)}',
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
                          } else {
                            context.push('/invoices/${inv.id}');
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

  String _statusLabel(InvoiceStatus s) => switch (s) {
        InvoiceStatus.paid => 'Đã TT',
        InvoiceStatus.partiallyPaid => 'TT một phần',
        InvoiceStatus.unpaid => 'Chưa TT',
        InvoiceStatus.cancelled => 'Đã hủy',
      };
}

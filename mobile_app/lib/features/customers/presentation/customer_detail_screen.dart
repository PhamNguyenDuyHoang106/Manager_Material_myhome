import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/customer_ledger_entry.dart';
import '../../../domain/services/customer_export_service.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  bool _migrating = true;
  DateTimeRange? _dateRange;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _migrate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _migrate() async {
    try {
      final repo = ref.read(customerRepositoryProvider);
      if (repo != null) {
        await repo.migrateCustomerIfNeeded(widget.customerId);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _migrating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_migrating) {
      return const Scaffold(
        body: AppLoading(message: 'Đang đồng bộ sổ nợ...'),
      );
    }

    final customersAsync = ref.watch(customersStreamProvider);
    final ledgerAsync = ref.watch(customerLedgerStreamProvider(widget.customerId));

    return customersAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (customers) {
        Customer? customer;
        try {
          customer = customers.firstWhere((c) => c.id == widget.customerId);
        } catch (_) {}

        if (customer == null) {
          return const Scaffold(body: Center(child: Text('Không tìm thấy khách hàng')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Xuất PDF sổ nợ',
                onPressed: () => _exportPdf(customer!),
              ),
            ],
          ),
          body: ledgerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (entries) {
              // 1. Calculate running balances sequentially (chronological order)
              final sortedEntries = List<CustomerLedgerEntry>.from(entries);
              sortedEntries.sort((a, b) {
                final cmp = a.date.compareTo(b.date);
                if (cmp != 0) return cmp;
                return a.createdAt.compareTo(b.createdAt);
              });

              int running = 0;
              final balances = <String, int>{};
              for (final entry in sortedEntries) {
                if (entry.type == LedgerEntryType.sale) {
                  running += entry.amountCents;
                } else if (entry.type == LedgerEntryType.payment) {
                  running -= entry.amountCents;
                } else if (entry.type == LedgerEntryType.cancellation) {
                  running -= entry.amountCents;
                } else if (entry.type == LedgerEntryType.paymentReversal) {
                  running += entry.amountCents;
                }
                balances[entry.id] = running;
              }

              final showRecalculateBanner = customer!.currentDebtCacheCents != running;

              // 2. Apply filters
              var filteredEntries = List<CustomerLedgerEntry>.from(entries);
              if (_dateRange != null) {
                filteredEntries = filteredEntries.where((e) {
                  return e.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                      e.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
                }).toList();
              }

              if (_filterType == 'sale') {
                filteredEntries = filteredEntries.where((e) => e.type == LedgerEntryType.sale).toList();
              } else if (_filterType == 'payment') {
                filteredEntries = filteredEntries.where((e) => e.type == LedgerEntryType.payment).toList();
              } else if (_filterType == 'cancellation') {
                filteredEntries = filteredEntries.where((e) => e.type == LedgerEntryType.cancellation || e.type == LedgerEntryType.paymentReversal).toList();
              }

              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                filteredEntries = filteredEntries.where((e) {
                  final descContains = e.description.toLowerCase().contains(q);
                  final itemsContains = e.items.any((item) => item.materialName.toLowerCase().contains(q));
                  return descContains || itemsContains;
                }).toList();
              }

              // 3. Sort descending for display (most recent first)
              filteredEntries.sort((a, b) {
                final cmp = b.date.compareTo(a.date);
                if (cmp != 0) return cmp;
                return b.createdAt.compareTo(a.createdAt);
              });

              return Column(
                children: [
                  _CustomerHeader(customer: customer!, currentDebt: running),
                  if (showRecalculateBanner)
                    Container(
                      color: Colors.amber.shade100,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber.shade800),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Công nợ cần đồng bộ lại',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.amber.shade900,
                            ),
                            icon: const Icon(Icons.sync, size: 16),
                            label: const Text('Đồng bộ', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              try {
                                final repo = ref.read(customerRepositoryProvider);
                                if (repo != null) {
                                  await repo.recalculateLedger(customer!.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã đồng bộ lại công nợ')),
                                  );
                                }
                              } catch (e) {
                                showErrorSnackBar(context, e);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  _buildDateFilter(),
                  _buildSearchAndTypeFilters(),
                  Expanded(
                    child: filteredEntries.isEmpty
                        ? const EmptyState(icon: Icons.history, title: 'Chưa có giao dịch nào')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filteredEntries.length,
                            itemBuilder: (_, i) {
                              final entry = filteredEntries[i];
                              final balance = balances[entry.id] ?? 0;
                              return _LedgerCard(entry: entry, runningBalance: balance);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month, size: 18),
              label: Text(
                _dateRange == null
                    ? 'Lọc theo ngày'
                    : '${AppDateUtils.formatDisplay(_dateRange!.start.toIso8601String().substring(0, 10))} - ${AppDateUtils.formatDisplay(_dateRange!.end.toIso8601String().substring(0, 10))}',
              ),
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _dateRange,
                );
                if (range != null) {
                  setState(() => _dateRange = range);
                }
              },
            ),
          ),
          if (_dateRange != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Xóa bộ lọc',
              onPressed: () => setState(() => _dateRange = null),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndTypeFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() => _searchQuery = val);
            },
            decoration: InputDecoration(
              hintText: 'Tìm theo vật liệu, nội dung...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _filterType == 'all',
                  onSelected: (val) => setState(() => _filterType = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Bán hàng'),
                  selected: _filterType == 'sale',
                  onSelected: (val) => setState(() => _filterType = 'sale'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Thanh toán'),
                  selected: _filterType == 'payment',
                  onSelected: (val) => setState(() => _filterType = 'payment'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Hủy / Hoàn tác'),
                  selected: _filterType == 'cancellation',
                  onSelected: (val) => setState(() => _filterType = 'cancellation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(Customer customer) async {
    final ledgerState = ref.read(customerLedgerStreamProvider(widget.customerId));
    final entries = ledgerState.valueOrNull;
    if (entries == null) {
      showErrorSnackBar(context, 'Không thể xuất PDF khi chưa tải xong dữ liệu.');
      return;
    }

    try {
      final settings = await ref.read(settingsRepositoryProvider)?.getSettings() ?? const AppSettings();
      Uint8List? logoBytes;
      if (settings.logoLocalPath.isNotEmpty) {
        final f = File(settings.logoLocalPath);
        if (await f.exists()) logoBytes = await f.readAsBytes();
      }

      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xuất PDF sổ nợ'),
          content: const Text('Bạn muốn xem trước hay chia sẻ Zalo?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'preview'), child: const Text('Xem trước')),
            FilledButton(onPressed: () => Navigator.pop(ctx, 'share'), child: const Text('Chia sẻ Zalo')),
          ],
        ),
      );

      if (action == null) return;

      final service = CustomerExportService();
      if (action == 'preview') {
        await service.preview(
          customer: customer,
          entries: entries,
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
          settings: settings,
          logoBytes: logoBytes,
        );
      } else {
        await service.saveAndShare(
          customer: customer,
          entries: entries,
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
          settings: settings,
          logoBytes: logoBytes,
        );
        if (mounted) showSuccessSnackBar(context, 'Đã xuất PDF sổ nợ thành công.');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.customer, required this.currentDebt});

  final Customer customer;
  final int currentDebt;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng nợ hiện tại:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  MoneyUtils.format(currentDebt),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: currentDebt > 0 ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16),
                const SizedBox(width: 6),
                Text(customer.phone.isNotEmpty ? customer.phone : 'Không có SĐT'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(customer.address.isNotEmpty ? customer.address : 'Không có địa chỉ')),
              ],
            ),
            if (customer.defaultNote.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.navigation_outlined, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Chỉ dẫn giao: ${customer.defaultNote}', style: const TextStyle(fontStyle: FontStyle.italic))),
                ],
              ),
            ],
            if (customer.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.yellow.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes, size: 16, color: Colors.orange.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        customer.note,
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.entry, required this.runningBalance});

  final CustomerLedgerEntry entry;
  final int runningBalance;

  @override
  Widget build(BuildContext context) {
    final isSale = entry.type == LedgerEntryType.sale;
    final isCancellation = entry.type == LedgerEntryType.cancellation;
    final isReversal = entry.type == LedgerEntryType.paymentReversal;

    Color entryColor = Colors.green;
    IconData entryIcon = Icons.arrow_downward;
    String sign = '-';

    if (isSale) {
      entryColor = Colors.orange.shade800;
      entryIcon = Icons.arrow_upward;
      sign = '+';
    } else if (isCancellation) {
      entryColor = Colors.red;
      entryIcon = Icons.cancel;
      sign = '-';
    } else if (isReversal) {
      entryColor = Colors.purple;
      entryIcon = Icons.undo;
      sign = '+';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isSale 
                      ? Colors.orange.shade50 
                      : isCancellation 
                          ? Colors.red.shade50 
                          : isReversal
                              ? Colors.purple.shade50
                              : Colors.green.shade50,
                  child: Icon(entryIcon, color: entryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppDateUtils.formatDisplay(entry.date.toIso8601String().substring(0, 10)),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        isSale 
                            ? 'Bán hàng' 
                            : isCancellation 
                                ? 'Hủy hóa đơn' 
                                : isReversal
                                    ? 'Hoàn tác thanh toán'
                                    : 'Khách thanh toán',
                        style: TextStyle(color: entryColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sign${MoneyUtils.format(entry.amountCents)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: entryColor,
                      ),
                    ),
                    Text(
                      'Dư nợ: ${MoneyUtils.format(runningBalance)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Text(entry.description, style: const TextStyle(fontSize: 13)),
            if (entry.items.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...entry.items.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      '• ${item.materialName}: ${item.quantity} ${item.unit} × ${MoneyUtils.format(item.sellingPriceCents)} = ${MoneyUtils.format(item.lineTotalCents)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  )),
            ],
            if (entry.attachmentUrl != null && entry.attachmentUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt, size: 16),
                label: const Text('Xem ảnh biên nhận'),
                onPressed: () => _viewAttachment(context, entry.attachmentUrl!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _viewAttachment(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Biên nhận thanh toán'),
              leading: const CloseButton(),
            ),
            InteractiveViewer(
              child: Image.network(
                url,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 150,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 36),
                        SizedBox(height: 8),
                        Text('Không thể tải ảnh biên nhận'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

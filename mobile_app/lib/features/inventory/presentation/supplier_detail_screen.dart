import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/supplier.dart';
import '../../../domain/entities/supplier_ledger_entry.dart';
import '../../../domain/services/supplier_export_service.dart';
import '../../inventory/presentation/import_invoice_form_screen.dart';
import '../../inventory/presentation/inventory_screen.dart' show showSupplierFormDialog;

class SupplierDetailScreen extends ConsumerStatefulWidget {
  const SupplierDetailScreen({super.key, required this.supplierId});

  final String supplierId;

  @override
  ConsumerState<SupplierDetailScreen> createState() =>
      _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen> {
  String _filterType = 'all';
  DateTimeRange? _dateRange;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersStreamProvider(null));
    final ledgerAsync    = ref.watch(supplierLedgerStreamProvider(widget.supplierId));
    final settingsAsync  = ref.watch(settingsStreamProvider);

    return suppliersAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:   (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (suppliers) {
        Supplier? supplier;
        try {
          supplier = suppliers.firstWhere((s) => s.id == widget.supplierId);
        } catch (_) {}

        if (supplier == null) {
          return const Scaffold(
              body: Center(child: Text('Không tìm thấy nhà cung cấp')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(supplier.name),
            actions: [
              // Tạo hóa đơn nhập hàng (giống receipt icon bên khách hàng)
              IconButton(
                icon: const Icon(Icons.add_shopping_cart_outlined),
                tooltip: 'Tạo hóa đơn nhập hàng',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImportInvoiceFormScreen(supplier: supplier!),
                  ),
                ),
              ),
              // Sửa thông tin NCC
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Sửa thông tin',
                onPressed: () => showSupplierFormDialog(context, ref, supplier: supplier),
              ),
              // Thanh toán cho NCC
              IconButton(
                icon: const Icon(Icons.payments_outlined),
                tooltip: 'Thanh toán cho NCC',
                onPressed: () => _showPaymentDialog(context, supplier!),
              ),
              // Xuất PDF sổ nợ
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Xuất PDF sổ nợ',
                onPressed: () => _exportPdf(supplier!, settingsAsync.valueOrNull,
                    ledgerAsync.valueOrNull ?? []),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Tạo hóa đơn nhập hàng',
            onPressed: () async {
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ImportInvoiceFormScreen(supplier: supplier!),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          body: ledgerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Center(child: Text('$e')),
            data: (entries) {
              // ── Running balances ──
              final sorted = List<SupplierLedgerEntry>.from(entries)
                ..sort((a, b) {
                  final c = a.date.compareTo(b.date);
                  return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
                });

              int running = 0;
              final balances = <String, int>{};
              for (final e in sorted) {
                switch (e.type) {
                  case SupplierLedgerEntryType.importInvoice:
                    running += (e.amountCents - e.paidAmountCents);
                    break;
                  case SupplierLedgerEntryType.payment:
                    running -= e.amountCents;
                    break;
                  case SupplierLedgerEntryType.adjustment:
                    running += e.amountCents;
                    break;
                  case SupplierLedgerEntryType.cancellation:
                    break;
                }
                balances[e.id] = running;
              }

              // ── Filters ──
              var filtered = List<SupplierLedgerEntry>.from(entries);
              if (_dateRange != null) {
                filtered = filtered.where((e) =>
                  e.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                  e.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))
                ).toList();
              }
              switch (_filterType) {
                case 'import':
                  filtered = filtered
                      .where((e) => e.type == SupplierLedgerEntryType.importInvoice)
                      .toList();
                  break;
                case 'payment':
                  filtered = filtered
                      .where((e) => e.type == SupplierLedgerEntryType.payment)
                      .toList();
                  break;
                case 'cancellation':
                  filtered = filtered
                      .where((e) =>
                          e.type == SupplierLedgerEntryType.cancellation ||
                          e.type == SupplierLedgerEntryType.adjustment)
                      .toList();
                  break;
              }
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                filtered = filtered
                    .where((e) =>
                        e.description.toLowerCase().contains(q) ||
                        e.note.toLowerCase().contains(q) ||
                        e.items.any((i) => i.materialName.toLowerCase().contains(q)))
                    .toList();
              }
              filtered.sort((a, b) {
                final c = b.date.compareTo(a.date);
                return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
              });

              return Column(
                children: [
                  // ── Header công nợ ──
                  _SupplierHeader(supplier: supplier!, currentDebt: running),

                  // ── Date filter (y hệt customer: Row với nút + clear) ──
                  _buildDateFilter(),

                  // ── Search + chips (y hệt customer) ──
                  _buildSearchAndTypeFilters(),

                  // ── Ledger list ──
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'Chưa có giao dịch nào')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final entry = filtered[i];
                              final bal   = balances[entry.id] ?? 0;
                              return _LedgerCard(
                                entry:   entry,
                                balance: bal,
                                onEdit:  () => _editEntry(context, supplier!, entry),
                                onCancel: () => _cancelEntry(context, supplier!, entry),
                              );
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

  // ── Date filter — y hệt customer_detail_screen ──────────────────
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
                if (range != null) setState(() => _dateRange = range);
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

  // ── Search + chip filters — y hệt customer_detail_screen ────────
  Widget _buildSearchAndTypeFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Tìm theo vật tư, nội dung...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                  onSelected: (_) => setState(() => _filterType = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Đơn nhập'),
                  selected: _filterType == 'import',
                  onSelected: (_) => setState(() => _filterType = 'import'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Thanh toán'),
                  selected: _filterType == 'payment',
                  onSelected: (_) => setState(() => _filterType = 'payment'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Hủy / Hoàn tác'),
                  selected: _filterType == 'cancellation',
                  onSelected: (_) => setState(() => _filterType = 'cancellation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────
  Future<void> _exportPdf(
    Supplier supplier,
    AppSettings? settings,
    List<SupplierLedgerEntry> entries,
  ) async {
    try {
      final service = SupplierExportService();
      final bytes = await service.buildPdfBytes(
        supplier:  supplier,
        entries:   entries,
        startDate: _dateRange?.start,
        endDate:   _dateRange?.end,
        settings:  settings ?? const AppSettings(),
      );
      await Printing.sharePdf(
        bytes:    bytes,
        filename: 'cong_no_${supplier.name.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _showPaymentDialog(BuildContext context, Supplier supplier) async {
    final amountCtrl = TextEditingController();
    final noteCtrl   = TextEditingController();
    DateTime date    = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Thanh toán — ${supplier.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền thanh toán *',
                  suffixText: '₫',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(
                    'Ngày TT: ${AppDateUtils.formatDisplay(date.toIso8601String().substring(0, 10))}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setD(() => date = picked);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Ghi chú'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                final val   = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
                final cents = MoneyUtils.toCents(val);
                if (cents <= 0) {
                  showErrorSnackBar(ctx, 'Số tiền phải lớn hơn 0');
                  return;
                }
                final repo = ref.read(supplierRepositoryProvider);
                if (repo == null) return;
                try {
                  await repo.recordPayment(
                    supplierId:   supplier.id,
                    supplierName: supplier.name,
                    amountCents:  cents,
                    date:         date,
                    note:         noteCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) showSuccessSnackBar(context, 'Đã ghi thanh toán');
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

  Future<void> _editEntry(
      BuildContext context, Supplier supplier, SupplierLedgerEntry entry) async {
    // Chỉ import invoice mới có thể edit (mở lại form nhập hàng với dữ liệu cũ)
    if (entry.type != SupplierLedgerEntryType.importInvoice) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ImportInvoiceFormScreen(
          supplier:     supplier,
          existingEntry: entry,
        ),
      ),
    );
  }

  Future<void> _cancelEntry(
      BuildContext context, Supplier supplier, SupplierLedgerEntry entry) async {
    final ok = await showConfirmDialog(
      context,
      title:   'Hủy bút toán?',
      message: 'Hủy giao dịch "${entry.description}" ngày '
          '${AppDateUtils.formatDisplay(entry.date.toIso8601String().substring(0, 10))}?',
    );
    if (ok != true || !mounted) return;
    final repo = ref.read(supplierRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.cancelLedgerEntry(supplierId: supplier.id, entry: entry);
      if (mounted) showSuccessSnackBar(context, 'Đã hủy giao dịch');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Header widget
// ─────────────────────────────────────────────────────────────
class _SupplierHeader extends StatelessWidget {
  const _SupplierHeader({required this.supplier, required this.currentDebt});

  final Supplier supplier;
  final int currentDebt;

  @override
  Widget build(BuildContext context) {
    final isPositive = currentDebt > 0;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Công nợ hiện tại:',
                  style: TextStyle(fontSize: 13)),
              Text(
                MoneyUtils.format(currentDebt),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: currentDebt == 0
                      ? Colors.grey
                      : (isPositive ? Colors.red : Colors.green),
                ),
              ),
            ],
          ),
          if (supplier.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(supplier.phone,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Ledger card — y hệt _LedgerCard bên khách hàng: có InkWell onTap
// ─────────────────────────────────────────────────────────────
class _LedgerCard extends StatelessWidget {
  const _LedgerCard({
    required this.entry,
    required this.balance,
    required this.onEdit,
    required this.onCancel,
  });

  final SupplierLedgerEntry entry;
  final int balance;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isImport     = entry.type == SupplierLedgerEntryType.importInvoice;
    final isPayment    = entry.type == SupplierLedgerEntryType.payment;
    final isAdjustment = entry.type == SupplierLedgerEntryType.adjustment;
    final isCancel     = entry.type == SupplierLedgerEntryType.cancellation;

    Color entryColor = Colors.grey;
    String typeLabel = '';
    IconData typeIcon = Icons.receipt_outlined;
    String sign = '+';

    if (isImport) {
      entryColor = Colors.orange.shade800;
      typeLabel  = 'Đơn nhập';
      typeIcon   = Icons.arrow_upward;
      sign       = '+';
    } else if (isPayment) {
      entryColor = Colors.green;
      typeLabel  = 'Thanh toán';
      typeIcon   = Icons.arrow_downward;
      sign       = '-';
    } else if (isAdjustment) {
      entryColor = Colors.purple;
      typeLabel  = 'Điều chỉnh';
      typeIcon   = Icons.tune;
      sign       = '+';
    } else if (isCancel) {
      entryColor = Colors.red;
      typeLabel  = 'Hủy / Hoàn tác';
      typeIcon   = Icons.cancel;
      sign       = '-';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Chỉ import invoice mới có thể tap để sửa
        onTap: isImport ? onEdit : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isImport
                        ? Colors.orange.shade50
                        : isPayment
                            ? Colors.green.shade50
                            : isCancel
                                ? Colors.red.shade50
                                : Colors.purple.shade50,
                    child: Icon(typeIcon, color: entryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppDateUtils.formatDisplay(
                              entry.date.toIso8601String().substring(0, 10)),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          typeLabel,
                          style: TextStyle(
                              color: entryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
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
                        'Dư nợ: ${MoneyUtils.format(balance)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: Colors.grey),
                    itemBuilder: (_) => [
                      if (isImport)
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.edit_outlined, size: 18),
                            title: Text('Sửa hóa đơn nhập'),
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'cancel',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.undo,
                              size: 18, color: Colors.red),
                          title: Text('Hủy bút toán',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'cancel') onCancel();
                    },
                  ),
                ],
              ),
              const Divider(),
              Text(entry.description,
                  style: const TextStyle(fontSize: 13)),
              if (entry.items.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...entry.items.map((item) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '• ${item.materialName}: '
                        '${MoneyUtils.formatQty(item.quantity)} ${item.unit}'
                        '${item.importPriceCents > 0 ? ' × ${MoneyUtils.format(item.importPriceCents)} = ${MoneyUtils.format(item.lineTotalCents)}' : ''}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700),
                      ),
                    )),
              ],
              if (entry.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('📝 ${entry.note}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
              if (entry.paidAmountCents > 0 && isImport) ...[
                const SizedBox(height: 2),
                Text(
                  'Đã thanh toán ngay: ${MoneyUtils.format(entry.paidAmountCents)}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.green),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

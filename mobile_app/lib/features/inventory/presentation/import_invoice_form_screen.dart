import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/material.dart' show StockMaterial;
import '../../../domain/entities/supplier.dart';
import '../../../domain/entities/supplier_ledger_entry.dart';

// ─── Một dòng vật tư nhập ───────────────────────────────────
class _LineItem {
  StockMaterial? material;
  final qty          = TextEditingController();
  final importPrice  = TextEditingController();
  final sellingPrice = TextEditingController();

  void dispose() {
    qty.dispose();
    importPrice.dispose();
    sellingPrice.dispose();
  }

  int get lineTotalCents {
    final q = double.tryParse(qty.text.replaceAll(',', '').replaceAll('.', '')) ?? 0;
    final p = double.tryParse(importPrice.text.replaceAll(',', '').replaceAll('.', '')) ?? 0;
    return MoneyUtils.toCents(q * p);
  }

  bool get isValid =>
      material != null &&
      (double.tryParse(qty.text.replaceAll(',', '').replaceAll('.', '')) ?? 0) > 0;
}

// ─── Màn hình Tạo hóa đơn nhập hàng ────────────────────────
class ImportInvoiceFormScreen extends ConsumerStatefulWidget {
  const ImportInvoiceFormScreen({
    super.key,
    required this.supplier,
    this.existingEntry,
  });

  final Supplier supplier;
  final SupplierLedgerEntry? existingEntry;

  @override
  ConsumerState<ImportInvoiceFormScreen> createState() =>
      _ImportInvoiceFormScreenState();
}

class _ImportInvoiceFormScreenState
    extends ConsumerState<ImportInvoiceFormScreen> {
  late DateTime _date;
  final _noteCtrl = TextEditingController();
  final _paidCtrl = TextEditingController(text: '0');
  final List<_LineItem> _lines = [_LineItem()];
  bool _saving = false;
  bool _initialized = false;

  // Điều chỉnh công nợ
  int    _adjustCents = 0;
  bool   _adjustIsDebt = true; // true = nợ cũ (+), false = đặt cọc (-)
  String _adjustNote  = '';

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  void _initFromEntry(List<StockMaterial> materials) {
    if (_initialized) return;
    _initialized = true;
    final e = widget.existingEntry;
    if (e == null) return;
    _date = e.date;
    _noteCtrl.text = e.note;
    _paidCtrl.text = MoneyUtils.fromCents(e.paidAmountCents).toStringAsFixed(0);
    _lines.clear();
    for (final item in e.items) {
      final line = _LineItem();
      try {
        line.material = materials.firstWhere((m) => m.id == item.materialId);
      } catch (_) {}
      line.qty.text = MoneyUtils.formatQty(item.quantity);
      line.importPrice.text = MoneyUtils.fromCents(item.importPriceCents).toStringAsFixed(0);
      line.sellingPrice.text = MoneyUtils.fromCents(item.sellingPriceCents).toStringAsFixed(0);
      _lines.add(line);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _paidCtrl.dispose();
    for (final l in _lines) l.dispose();
    super.dispose();
  }

  int get _totalCents => _lines.fold(0, (s, l) => s + l.lineTotalCents);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _showAdjustmentDialog() async {
    bool isDebt      = _adjustIsDebt;
    final amountCtrl = TextEditingController(
      text: _adjustCents > 0
          ? MoneyUtils.fromCents(_adjustCents).toStringAsFixed(0)
          : '',
    );
    final noteCtrl = TextEditingController(text: _adjustNote);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Điều chỉnh công nợ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ghi số tiền nợ cũ hoặc đặt cọc với ${widget.supplier.name}:',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Nợ cũ (+)'),
                      selected: isDebt,
                      selectedColor: Colors.red.shade100,
                      onSelected: (v) { if (v) setD(() => isDebt = true); },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Đặt cọc (-)'),
                      selected: !isDebt,
                      selectedColor: Colors.green.shade100,
                      onSelected: (v) { if (v) setD(() => isDebt = false); },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VNĐ)',
                  hintText: 'Ví dụ: 5000000',
                  suffixText: '₫',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú lý do',
                  hintText: 'Ví dụ: Nợ cát đợt trước',
                ),
              ),
            ],
          ),
          actions: [
            if (_adjustCents > 0)
              TextButton(
                onPressed: () {
                  setState(() {
                    _adjustCents = 0;
                    _adjustNote = '';
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Xóa điều chỉnh',
                    style: TextStyle(color: Colors.red)),
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                final val   = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                final cents = MoneyUtils.toCents(val);
                setState(() {
                  _adjustCents = cents;
                  _adjustIsDebt = isDebt;
                  _adjustNote = noteCtrl.text.trim();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final validLines = _lines.where((l) => l.isValid).toList();
    if (validLines.isEmpty) {
      showErrorSnackBar(
          context, 'Vui lòng chọn ít nhất một vật tư với số lượng > 0');
      return;
    }
    setState(() => _saving = true);
    try {
      final supRepo = ref.read(supplierRepositoryProvider);
      final invRepo = ref.read(inventoryRepositoryProvider);
      if (supRepo == null || invRepo == null) return;

      final paidCents = MoneyUtils.toCents(
        double.tryParse(_paidCtrl.text.replaceAll(',', '').replaceAll('.', '')) ?? 0,
      );

      final items = validLines.map((l) {
        final q  = double.parse(l.qty.text.replaceAll(',', '').replaceAll('.', ''));
        final ip = MoneyUtils.toCents(
            double.tryParse(l.importPrice.text.replaceAll(',', '').replaceAll('.', '')) ?? 0);
        final sp = MoneyUtils.toCents(
            double.tryParse(l.sellingPrice.text.replaceAll(',', '').replaceAll('.', '')) ?? 0);
        return SupplierLedgerItem(
          materialId:        l.material!.id,
          materialName:      l.material!.name,
          unit:              l.material!.unit,
          quantity:          q,
          importPriceCents:  ip,
          sellingPriceCents: sp,
          lineTotalCents:    ip > 0 ? (q * ip).round() : 0,
        );
      }).toList();

      // Nhập kho từng vật tư
      for (final item in items) {
        await invRepo.addStock(
          materialId:       item.materialId,
          quantity:         item.quantity,
          importPriceCents: item.importPriceCents,
          note:             'Nhập từ NCC: ${widget.supplier.name}',
        );
      }

      // Ghi hóa đơn nhập + điều chỉnh công nợ (nếu có)
      await supRepo.createImportInvoice(
        supplierId:      widget.supplier.id,
        supplierName:    widget.supplier.name,
        date:            _date,
        items:           items,
        paidAmountCents: paidCents,
        note:            _noteCtrl.text.trim(),
        adjustCents:     _adjustCents != 0
            ? (_adjustIsDebt ? _adjustCents : -_adjustCents)
            : 0,
        adjustNote:      _adjustNote,
      );

      if (mounted) {
        showSuccessSnackBar(context, 'Đã lưu hóa đơn nhập hàng');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsStreamProvider);
    final materials = materialsAsync.valueOrNull?.cast<StockMaterial>() ?? [];

    // Pre-fill form when editing existing import invoice
    _initFromEntry(materials);

    final dateStr = AppDateUtils.formatDisplay(
        _date.toIso8601String().substring(0, 10));
    final isEditMode = widget.existingEntry != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Sửa hóa đơn nhập hàng' : 'Tạo hóa đơn nhập hàng'),
        centerTitle: true,
        // Icon "Điều chỉnh công nợ" nằm trên AppBar
        actions: [
          IconButton(
            icon: Icon(
              _adjustCents != 0
                  ? Icons.account_balance_wallet
                  : Icons.account_balance_wallet_outlined,
              color: _adjustCents != 0
                  ? (_adjustIsDebt ? Colors.red.shade300 : Colors.green.shade300)
                  : null,
            ),
            tooltip: 'Điều chỉnh công nợ',
            onPressed: _showAdjustmentDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Nhà cung cấp (khóa) ──
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Nhà cung cấp'),
            child: Row(
              children: [
                const Icon(Icons.store_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.supplier.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Ngày nhập hàng ──
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month, size: 18),
            label: Text(
              'Ngày nhập hàng: $dateStr',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: _pickDate,
          ),

          // ── Badge điều chỉnh công nợ (nếu có) ──
          if (_adjustCents != 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _adjustIsDebt ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _adjustIsDebt
                      ? Colors.red.shade300
                      : Colors.green.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 16,
                    color: _adjustIsDebt ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Điều chỉnh công nợ: '
                      '${_adjustIsDebt ? '+' : '-'}${MoneyUtils.format(_adjustCents)}'
                      '${_adjustNote.isNotEmpty ? ' (${_adjustNote})' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _adjustIsDebt
                            ? Colors.red.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _adjustCents = 0;
                      _adjustNote = '';
                    }),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text('Danh sách vật tư nhập',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          // ── Các dòng vật tư ──
          ..._lines.asMap().entries
              .map((e) => _buildLine(e.key, e.value, materials)),

          TextButton.icon(
            onPressed: () => setState(() => _lines.add(_LineItem())),
            icon: const Icon(Icons.add),
            label: const Text('Thêm dòng vật tư'),
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // ── Tổng tiền hàng ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng tiền hàng:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                MoneyUtils.format(_totalCents),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Số tiền thanh toán ngay ──
          TextField(
            controller: _paidCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Số tiền thanh toán ngay',
              prefixIcon: Icon(Icons.payments_outlined),
              suffixText: '₫',
            ),
          ),
          const SizedBox(height: 12),

          // ── Ghi chú ──
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Ghi chú đơn nhập',
              prefixIcon: Icon(Icons.edit_note_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // ── Nút lưu ──
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Lưu hóa đơn nhập hàng'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLine(int index, _LineItem line, List<StockMaterial> materials) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<StockMaterial>(
                    value: line.material,
                    decoration:
                        const InputDecoration(labelText: 'Vật tư', isDense: true),
                    items: materials
                        .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.name,
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        line.material = v;
                        if (v != null && v.defaultImportPriceCents > 0) {
                          line.importPrice.text =
                              MoneyUtils.fromCents(v.defaultImportPriceCents)
                                  .toStringAsFixed(0);
                        }
                      });
                    },
                  ),
                ),
                if (_lines.length > 1) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: Colors.red),
                    onPressed: () {
                      line.dispose();
                      setState(() => _lines.removeAt(index));
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: line.qty,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Số lượng',
                      isDense: true,
                      suffixText: line.material?.unit ?? '',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: line.importPrice,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Giá nhập', isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: line.sellingPrice,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Giá bán', isDense: true),
            ),
            if (line.lineTotalCents > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '= ${MoneyUtils.format(line.lineTotalCents)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/material.dart' show StockMaterial;
import '../../../domain/repositories/invoice_repository.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  const InvoiceFormScreen({super.key, this.invoice});

  final Invoice? invoice;

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _LineItem {
  StockMaterial? material;
  final qty = TextEditingController();
  final price = TextEditingController();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  Customer? _customer;
  final _lines = [_LineItem()];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      // Pre-fill handled after materials load in build
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final materialsAsync = ref.watch(materialsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.invoice == null ? 'Tạo hóa đơn' : 'Sửa hóa đơn')),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (customersRaw) => materialsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (materialsRaw) {
            final customers = customersRaw.cast<Customer>();
            final materials = materialsRaw.cast<StockMaterial>();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<Customer>(
                  value: _customer,
                  decoration: const InputDecoration(labelText: 'Khách hàng *'),
                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => _customer = v),
                ),
                const SizedBox(height: 16),
                ..._lines.asMap().entries.map((e) => _buildLine(e.key, e.value, materials)),
                TextButton.icon(
                  onPressed: () => setState(() => _lines.add(_LineItem())),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm dòng'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : () => _save(materials),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Lưu hóa đơn'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLine(int index, _LineItem line, List<StockMaterial> materials) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<StockMaterial>(
                    value: line.material,
                    decoration: const InputDecoration(labelText: 'Vật liệu'),
                    items: materials.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                    onChanged: (v) {
                      setState(() {
                        line.material = v;
                        line.price.text = v != null
                            ? MoneyUtils.fromCents(v.defaultSellingPriceCents).toString()
                            : '';
                      });
                    },
                  ),
                ),
                if (_lines.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _lines.removeAt(index)),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: line.qty,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'SL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: line.price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Đơn giá'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(List<StockMaterial> materials) async {
    if (_customer == null) {
      showErrorSnackBar(context, 'Chọn khách hàng');
      return;
    }
    final items = <InvoiceItemInput>[];
    for (final line in _lines) {
      if (line.material == null) continue;
      final qty = double.tryParse(line.qty.text);
      final price = double.tryParse(line.price.text);
      if (qty == null || qty <= 0 || price == null) continue;
      items.add(InvoiceItemInput(
        materialId: line.material!.id,
        quantity: qty,
        sellingPriceCents: MoneyUtils.toCents(price),
      ));
    }
    if (items.isEmpty) {
      showErrorSnackBar(context, 'Thêm ít nhất một dòng hợp lệ');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      if (repo == null) return;
      final date = AppDateUtils.todayIso();
      if (widget.invoice == null) {
        await repo.createInvoice(customerId: _customer!.id, invoiceDate: date, items: items);
      } else {
        await repo.updateInvoice(
          invoiceId: widget.invoice!.id,
          customerId: _customer!.id,
          invoiceDate: widget.invoice!.invoiceDate,
          items: items,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

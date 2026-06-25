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
  bool isTruck = false; // Sell by Truck instead of Block
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  Customer? _customer;
  final _lines = [_LineItem()];
  bool _saving = false;
  bool _initialized = false;
  
  final _deliveryAddress = TextEditingController();
  final _deliveryNote = TextEditingController();

  @override
  void dispose() {
    _deliveryAddress.dispose();
    _deliveryNote.dispose();
    for (final line in _lines) {
      line.qty.dispose();
      line.price.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final materialsAsync = ref.watch(materialsStreamProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);
    final truckVolume = settingsAsync.valueOrNull?.truckVolume ?? 4.0;

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

            if (!_initialized) {
              if (widget.invoice != null) {
                final inv = widget.invoice!;
                try {
                  _customer = customers.firstWhere((c) => c.id == inv.customerId);
                } catch (_) {}
                _deliveryAddress.text = inv.deliveryAddress;
                _deliveryNote.text = inv.deliveryNote;
                
                _lines.clear();
                for (final item in inv.items) {
                  final line = _LineItem();
                  try {
                    line.material = materials.firstWhere((m) => m.id == item.materialId);
                  } catch (_) {}
                  line.qty.text = item.quantity.toString();
                  line.price.text = MoneyUtils.fromCents(item.sellingPriceCents).toString();
                  _lines.add(line);
                }
              }
              _initialized = true;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<Customer>(
                  value: _customer,
                  decoration: const InputDecoration(labelText: 'Khách hàng *'),
                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _customer = v;
                      if (v != null) {
                        if (_deliveryAddress.text.isEmpty) {
                          _deliveryAddress.text = v.address;
                        }
                        if (_deliveryNote.text.isEmpty) {
                          _deliveryNote.text = v.defaultNote;
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _deliveryAddress,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ giao hàng (Công trình)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _deliveryNote,
                  decoration: const InputDecoration(
                    labelText: 'Chỉ đường / Ghi chú giao hàng',
                    prefixIcon: Icon(Icons.navigation_outlined),
                    hintText: 'Ví dụ: Ngõ thứ 2 bên trái, cạnh nhà văn hóa',
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text('Danh sách vật liệu', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._lines.asMap().entries.map((e) => _buildLine(e.key, e.value, materials, truckVolume)),
                TextButton.icon(
                  onPressed: () => setState(() => _lines.add(_LineItem())),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm dòng vật liệu'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : () => _save(materials, truckVolume),
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

  Widget _buildLine(int index, _LineItem line, List<StockMaterial> materials, double truckVolume) {
    final showVolumeToggle = line.material != null && 
        (line.material!.unit.toLowerCase() == 'khối' || line.material!.unit.toLowerCase() == 'm3');

    // Dynamic conversion calculation preview
    double parsedQty = double.tryParse(line.qty.text) ?? 0.0;
    double finalBlocks = line.isTruck ? parsedQty * truckVolume : parsedQty;

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
                    items: materials.map((m) => DropdownMenuItem(value: m, child: Text('${m.name} (${m.unit})'))).toList(),
                    onChanged: (v) {
                      setState(() {
                        line.material = v;
                        line.price.text = v != null
                            ? MoneyUtils.fromCents(v.defaultSellingPriceCents).toString()
                            : '';
                        line.isTruck = false; // Reset toggle
                      });
                    },
                  ),
                ),
                if (_lines.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => _lines.removeAt(index)),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: line.qty,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: line.isTruck ? 'Số xe' : 'Số lượng',
                          suffixText: line.isTruck ? 'xe' : (line.material?.unit ?? ''),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (showVolumeToggle && line.isTruck && parsedQty > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            '(= $finalBlocks khối)',
                            style: TextStyle(fontSize: 12, color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showVolumeToggle) ...[
                  const SizedBox(width: 12),
                  ToggleButtons(
                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(minHeight: 40, minWidth: 50),
                    isSelected: [!line.isTruck, line.isTruck],
                    onPressed: (toggleIndex) {
                      setState(() {
                        line.isTruck = toggleIndex == 1;
                      });
                    },
                    children: const [
                      Text('Khối'),
                      Text('Xe'),
                    ],
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: line.price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: line.isTruck ? 'Đơn giá / xe' : 'Đơn giá',
                      suffixText: 'đ',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(List<StockMaterial> materials, double truckVolume) async {
    if (_customer == null) {
      showErrorSnackBar(context, 'Chọn khách hàng');
      return;
    }
    final items = <InvoiceItemInput>[];
    for (final line in _lines) {
      if (line.material == null) continue;
      final qtyText = line.qty.text;
      final priceText = line.price.text;
      final qtyVal = double.tryParse(qtyText);
      final priceVal = double.tryParse(priceText);
      
      if (qtyVal == null || qtyVal <= 0 || priceVal == null) continue;
      
      // Calculate quantity and unit price based on conversion selection
      double finalQuantity = line.isTruck ? qtyVal * truckVolume : qtyVal;
      int finalPriceCents = line.isTruck 
          ? (MoneyUtils.toCents(priceVal) / truckVolume).round() 
          : MoneyUtils.toCents(priceVal);

      items.add(InvoiceItemInput(
        materialId: line.material!.id,
        quantity: finalQuantity,
        sellingPriceCents: finalPriceCents,
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
      final deliveryAddr = _deliveryAddress.text.trim();
      final deliveryNt = _deliveryNote.text.trim();
      
      if (widget.invoice == null) {
        await repo.createInvoice(
          customerId: _customer!.id,
          invoiceDate: DateTime.parse(date),
          items: items,
          deliveryAddress: deliveryAddr,
          deliveryNote: deliveryNt,
        );
      } else {
        await repo.updateInvoice(
          invoiceId: widget.invoice!.id,
          customerId: _customer!.id,
          invoiceDate: widget.invoice!.invoiceDate,
          items: items,
          deliveryAddress: deliveryAddr,
          deliveryNote: deliveryNt,
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


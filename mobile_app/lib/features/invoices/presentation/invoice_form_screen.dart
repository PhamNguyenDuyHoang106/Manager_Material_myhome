import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/app_settings.dart';
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

/// Returns the list of selectable sub-units based on the material's base unit.
List<String> _subUnitsFor(String? baseUnit) {
  switch (baseUnit?.toLowerCase()) {
    case 'khối':
    case 'm3':
      return ['khối', 'xe'];
    case 'tấn':
      return ['tấn', 'tạ'];
    case 'viên':
      return ['viên', 'vạn'];
    case 'cây':
      return ['cây'];
    case 'kg':
      return ['kg'];
    default:
      return [if (baseUnit != null && baseUnit.isNotEmpty) baseUnit];
  }
}

class _LineItem {
  StockMaterial? material;
  final qty = TextEditingController();
  final price = TextEditingController();
  String? selectedUnit;
  DateTime? deliveryDate;
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  Customer? _customer;
  final _lines = [_LineItem()];
  bool _saving = false;
  bool _initialized = false;

  final _deliveryAddress = TextEditingController();
  final _deliveryDirections = TextEditingController();
  final _deliveryNote = TextEditingController();

  @override
  void dispose() {
    _deliveryAddress.dispose();
    _deliveryDirections.dispose();
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
            final settings = settingsAsync.valueOrNull as AppSettings?;
            final double truckVolume = settings?.truckVolume ?? 4.0;

            if (!_initialized) {
              if (widget.invoice != null) {
                final inv = widget.invoice!;
                try {
                  _customer = customers.firstWhere((c) => c.id == inv.customerId);
                } catch (_) {}
                _deliveryAddress.text = inv.deliveryAddress;
                _deliveryDirections.text = inv.deliveryDirections;
                _deliveryNote.text = inv.deliveryNote;

                _lines.clear();
                for (final item in inv.items) {
                  final line = _LineItem();
                  try {
                    line.material = materials.firstWhere((m) => m.id == item.materialId);
                  } catch (_) {}
                  line.qty.text = MoneyUtils.formatQty(item.quantity);
                  line.price.text = MoneyUtils.formatInt(MoneyUtils.fromCents(item.sellingPriceCents).toInt());
                  line.deliveryDate = item.deliveryDate ?? inv.invoiceDate;
                  line.selectedUnit = item.unit;
                  _lines.add(line);
                }
              }
              _initialized = true;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Customer dropdown ──────────────────────────
                DropdownButtonFormField<Customer>(
                  value: _customer,
                  decoration: const InputDecoration(labelText: 'Khách hàng'),
                  items: customers
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _customer = v;
                      if (v != null) {
                        // defaultNote = Chỉ dẫn giao hàng mặc định
                        // note = Ghi chú khách hàng
                        _deliveryAddress.text = v.address;
                        _deliveryDirections.text = v.defaultNote;
                        _deliveryNote.text = v.note;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                // ── Delivery address ───────────────────────────
                TextField(
                  controller: _deliveryAddress,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ giao hàng',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                // ── Directions: chỉ hiện khi khách hàng có dữ liệu ──
                if (_customer != null && _customer!.defaultNote.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deliveryDirections,
                    decoration: const InputDecoration(
                      labelText: 'Chỉ đường',
                      prefixIcon: Icon(Icons.navigation_outlined),
                    ),
                  ),
                ],
                // ── Note: chỉ hiện khi khách hàng có ghi chú ──────
                if (_customer != null && _customer!.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deliveryNote,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú giao hàng',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text('Danh sách vật liệu',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._lines.asMap().entries
                    .map((e) => _buildLine(e.key, e.value, materials, truckVolume)),
                TextButton.icon(
                  onPressed: () => setState(() => _lines.add(_LineItem())),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm dòng vật liệu'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : () => _save(),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
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
    final subUnits = _subUnitsFor(line.material?.unit);
    // Ensure selectedUnit is valid for the current material
    if (line.selectedUnit != null && !subUnits.contains(line.selectedUnit)) {
      line.selectedUnit = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Material dropdown + delete button
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<StockMaterial>(
                    value: line.material,
                    decoration: const InputDecoration(labelText: 'Vật liệu'),
                    items: materials
                        .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.name)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        line.material = v;
                        line.selectedUnit = null; // reset unit on material change
                        line.price.text = v != null
                            ? MoneyUtils.formatInt(MoneyUtils.fromCents(v.defaultSellingPriceCents).toInt())
                            : '';
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
            const SizedBox(height: 8),
            // Quantity + unit dropdown in a Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: line.qty,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Số lượng',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                if (subUnits.length > 1)
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: line.selectedUnit,
                      hint: const Text('Đơn vị'),
                      decoration: const InputDecoration(labelText: 'Đơn vị'),
                      items: subUnits
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          line.selectedUnit = v;

                          // Auto-convert price in field
                          if (line.material != null) {
                            final basePrice = MoneyUtils.fromCents(line.material!.defaultSellingPriceCents);
                            final baseUnit = line.material!.unit.toLowerCase();
                            final selectedUnit = (v ?? baseUnit).toLowerCase();

                            double ratio = 1.0;
                            if (baseUnit == 'khối' || baseUnit == 'm3') {
                              if (selectedUnit == 'xe') {
                                ratio = truckVolume;
                              }
                            } else if (baseUnit == 'tấn') {
                              if (selectedUnit == 'tạ') {
                                ratio = 0.1;
                              }
                            } else if (baseUnit == 'viên') {
                              if (selectedUnit == 'vạn') {
                                ratio = 10000.0;
                              }
                            }

                            final double newPrice = basePrice * ratio;
                            line.price.text = MoneyUtils.formatInt(newPrice.toInt());
                          }
                        });
                      },
                    ),
                  )
                else
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Đơn vị'),
                      child: Text(subUnits.isNotEmpty ? subUnits.first : ''),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Price field (Full width)
            TextField(
              controller: line.price,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              decoration: const InputDecoration(
                labelText: 'Đơn giá',
                suffixText: 'đ',
              ),
            ),
            const SizedBox(height: 8),
            // Delivery date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: line.deliveryDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        line.deliveryDate = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    'Ngày vận chuyển: ${AppDateUtils.formatDisplay((line.deliveryDate ?? DateTime.now()).toIso8601String().substring(0, 10))}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_customer == null) {
      showErrorSnackBar(context, 'Chọn khách hàng');
      return;
    }
    final items = <InvoiceItemInput>[];
    for (final line in _lines) {
      if (line.material == null) continue;
      final qtyVal = double.tryParse(line.qty.text);
      final priceVal = double.tryParse(line.price.text.replaceAll('.', ''));

      if (qtyVal == null || qtyVal <= 0 || priceVal == null) continue;

      final subUnits = _subUnitsFor(line.material!.unit);
      final unit = subUnits.length == 1
          ? subUnits.first
          : (line.selectedUnit ?? '');

      if (unit.isEmpty) {
        showErrorSnackBar(context, 'Chọn đơn vị cho tất cả vật liệu');
        return;
      }

      items.add(InvoiceItemInput(
        materialId: line.material!.id,
        quantity: qtyVal,
        sellingPriceCents: MoneyUtils.toCents(priceVal),
        deliveryDate: line.deliveryDate,
        unit: unit,
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

      // Use the earliest delivery date from all items as invoice date
      DateTime? earliestDate;
      for (final item in items) {
        if (item.deliveryDate != null) {
          if (earliestDate == null || item.deliveryDate!.isBefore(earliestDate)) {
            earliestDate = item.deliveryDate;
          }
        }
      }
      final invoiceDate = earliestDate ?? DateTime.now();

      final deliveryAddr = _deliveryAddress.text.trim();
      final deliveryDirections = _deliveryDirections.text.trim();
      final deliveryNt = _deliveryNote.text.trim();

      if (widget.invoice == null) {
        await repo.createInvoice(
          customerId: _customer!.id,
          invoiceDate: invoiceDate,
          items: items,
          deliveryAddress: deliveryAddr,
          deliveryDirections: deliveryDirections,
          deliveryNote: deliveryNt,
        );
      } else {
        await repo.updateInvoice(
          invoiceId: widget.invoice!.id,
          customerId: _customer!.id,
          invoiceDate: invoiceDate,
          items: items,
          deliveryAddress: deliveryAddr,
          deliveryDirections: deliveryDirections,
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

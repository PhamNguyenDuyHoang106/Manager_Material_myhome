import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/services/invoice_export_service.dart';
import 'invoice_form_screen.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final inv = await ref.read(invoiceRepositoryProvider)?.getInvoice(widget.invoiceId);
    if (mounted) {
      setState(() {
        _invoice = inv;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final invoice = _invoice;
    if (invoice == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Không tìm thấy hóa đơn')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hóa đơn #${invoice.id.substring(0, 8)}'),
        actions: [
          if (invoice.paidAmountCents == 0)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => InvoiceFormScreen(invoice: invoice)),
                );
                _load();
              },
            ),
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pdf', child: Text('Xuất PDF / Chia sẻ Zalo')),
              const PopupMenuItem(value: 'preview', child: Text('Xem trước PDF')),
              if (invoice.paidAmountCents == 0)
                const PopupMenuItem(value: 'delete', child: Text('Xóa')),
            ],
            onSelected: (v) async {
              if (v == 'delete') await _delete(invoice);
              if (v == 'pdf' || v == 'preview') await _export(invoice, preview: v == 'preview');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.customerName, style: Theme.of(context).textTheme.titleLarge),
                  Text('Ngày: ${AppDateUtils.formatDisplay(invoice.invoiceDate)}'),
                  const Divider(),
                  Text('Tổng: ${MoneyUtils.format(invoice.totalAmountCents)}'),
                  Text('Đã TT: ${MoneyUtils.format(invoice.paidAmountCents)}'),
                  Text(
                    'Còn nợ: ${MoneyUtils.format(invoice.remainingCents)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Chi tiết', style: Theme.of(context).textTheme.titleMedium),
          ...invoice.items.map(
            (item) => Card(
              child: ListTile(
                title: Text(item.materialName),
                subtitle: Text('${item.quantity} ${item.unit} × ${MoneyUtils.format(item.sellingPriceCents)}'),
                trailing: Text(MoneyUtils.format(item.lineTotalCents)),
              ),
            ),
          ),
          if (invoice.status != InvoiceStatus.paid) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _addPayment(invoice),
              icon: const Icon(Icons.payments),
              label: const Text('Thêm thanh toán'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addPayment(Invoice invoice) async {
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thanh toán'),
        content: TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Số tiền (còn ${MoneyUtils.format(invoice.remainingCents)})',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(paymentRepositoryProvider)?.addPayment(
            invoiceId: invoice.id,
            customerId: invoice.customerId,
            amountCents: MoneyUtils.toCents(double.parse(amount.text)),
            paymentDate: AppDateUtils.todayIso(),
          );
      showSuccessSnackBar(context, 'Đã ghi nhận thanh toán');
      _load();
    } catch (e) {
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _export(Invoice invoice, {required bool preview}) async {
    try {
      final settings = await ref.read(settingsRepositoryProvider)?.getSettings() ?? const AppSettings();
      Uint8List? logoBytes;
      if (settings.logoLocalPath.isNotEmpty) {
        final f = File(settings.logoLocalPath);
        if (await f.exists()) logoBytes = await f.readAsBytes();
      }
      final service = InvoiceExportService();
      if (preview) {
        await service.preview(invoice: invoice, settings: settings, logoBytes: logoBytes);
      } else {
        await service.saveAndShare(invoice: invoice, settings: settings, logoBytes: logoBytes);
        showSuccessSnackBar(context, 'Đã xuất PDF — chọn Zalo để gửi');
      }
    } catch (e) {
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _delete(Invoice invoice) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa hóa đơn?',
      message: 'Tồn kho sẽ được hoàn lại.',
    );
    if (ok != true) return;
    try {
      await ref.read(invoiceRepositoryProvider)?.deleteInvoice(invoice.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      showErrorSnackBar(context, e);
    }
  }
}

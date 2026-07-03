import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../application/providers/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/payment.dart';
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
  Customer? _customer;
  List<Payment> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final invRepo = ref.read(invoiceRepositoryProvider);
    final payRepo = ref.read(paymentRepositoryProvider);
    final custRepo = ref.read(customerRepositoryProvider);
    final inv = await invRepo?.getInvoice(widget.invoiceId);
    List<Payment> payments = [];
    Customer? customer;
    if (inv != null) {
      if (payRepo != null) {
        payments = await payRepo.getPaymentsForInvoice(widget.invoiceId);
      }
      if (custRepo != null) {
        customer = await custRepo.getCustomer(inv.customerId);
      }
    }
    if (mounted) {
      setState(() {
        _invoice = inv;
        _customer = customer;
        _payments = payments;
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
          if (invoice.status == InvoiceStatus.unpaid)
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
              if (invoice.status == InvoiceStatus.unpaid)
                const PopupMenuItem(value: 'delete', child: Text('Hủy')),
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
                  Text('Thông tin khách hàng', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tên khách: ${invoice.customerName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Số điện thoại: ${_customer?.phone.isNotEmpty == true ? _customer!.phone : "N/A"}'),
                  Text('Địa chỉ khách: ${_customer?.address.isNotEmpty == true ? _customer!.address : "N/A"}'),
                  if (_customer?.note.isNotEmpty == true)
                    Text('Ghi chú khách: ${_customer!.note}'),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Thông tin giao hàng', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Ngày lập: ${AppDateUtils.formatDisplay(invoice.invoiceDate.toIso8601String().substring(0, 10))}'),
                  Text('Địa chỉ giao: ${invoice.deliveryAddress.isNotEmpty ? invoice.deliveryAddress : "N/A"}'),
                  if (invoice.deliveryDirections.isNotEmpty)
                    Text('Chỉ đường: ${invoice.deliveryDirections}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  if (invoice.deliveryNote.isNotEmpty)
                    Text('Ghi chú: ${invoice.deliveryNote}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Tổng cộng: ${MoneyUtils.format(invoice.totalAmountCents)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Đã thanh toán: ${MoneyUtils.format(invoice.paidAmountCents)}'),
                  Text(
                    'Còn nợ hóa đơn: ${MoneyUtils.format(invoice.remainingCents)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Chi tiết vật liệu', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.8), // Ngày
                  1: FlexColumnWidth(3.2), // Vật liệu
                  2: FlexColumnWidth(2.5), // Giá
                  3: FlexColumnWidth(2.5), // Tổng
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Ngày', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Vật liệu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Giá', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Tổng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                  ...invoice.items.map((item) {
                    final dateStr = AppDateUtils.formatDisplay(
                      (item.deliveryDate ?? invoice.invoiceDate).toIso8601String().substring(0, 10),
                    );
                    final shortDate = dateStr.split('/').take(2).join('/');
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(shortDate, style: const TextStyle(fontSize: 13)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${item.materialName}\n(${MoneyUtils.formatQty(item.quantity)} ${item.unit})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            MoneyUtils.format(item.sellingPriceCents),
                            style: const TextStyle(fontSize: 13),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            MoneyUtils.format(item.lineTotalCents),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          if (_payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Lịch sử thanh toán', style: Theme.of(context).textTheme.titleMedium),
            ..._payments.map(
              (p) => Card(
                child: ListTile(
                  leading: const Icon(Icons.payment, color: Colors.green),
                  title: Text(MoneyUtils.format(p.amountCents), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Ngày: ${AppDateUtils.formatDisplay(p.paymentDate.toIso8601String().substring(0, 10))}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.attachmentUrl.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: () => _viewReceiptImage(p.attachmentUrl),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final ok = await showConfirmDialog(
                            context,
                            title: 'Hủy đợt thanh toán này?',
                            message: 'Tổng nợ của khách hàng và trạng thái hóa đơn sẽ được cập nhật lại.',
                          );
                          if (ok == true) {
                            setState(() => _loading = true);
                            try {
                              await ref.read(paymentRepositoryProvider)?.deletePayment(p.id);
                              showSuccessSnackBar(context, 'Đã hủy đợt thanh toán');
                              _load();
                            } catch (e) {
                              showErrorSnackBar(context, e);
                              setState(() => _loading = false);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

  Future<String> _uploadReceipt(File file) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) throw Exception('Chưa đăng nhập');
    final storage = ref.read(firebaseStorageProvider);
    final refPath = storage.ref().child('users/$uid/receipts/${const Uuid().v4()}.jpg');
    final uploadTask = await refPath.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  void _viewReceiptImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Ảnh biên nhận'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            InteractiveViewer(
              child: Image.network(
                url,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Không thể tải ảnh'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPayment(Invoice invoice) async {
    final result = await showDialog<_AddPaymentResult>(
      context: context,
      builder: (ctx) => _AddPaymentDialog(remainingCents: invoice.remainingCents),
    );
    if (result == null) return;

    setState(() => _loading = true);
    try {
      String? attachmentUrl;
      if (result.imageFile != null) {
        attachmentUrl = await _uploadReceipt(result.imageFile!);
      }

      await ref.read(paymentRepositoryProvider)?.addPayment(
            invoiceId: invoice.id,
            customerId: invoice.customerId,
            amountCents: result.amountCents,
            paymentDate: DateTime.now(),
            attachmentUrl: attachmentUrl,
          );
      showSuccessSnackBar(context, 'Đã ghi nhận thanh toán');
      _load();
    } catch (e) {
      showErrorSnackBar(context, e);
      setState(() => _loading = false);
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

      int? customerDebtCents;
      final customerRepo = ref.read(customerRepositoryProvider);
      if (customerRepo != null) {
        final customer = await customerRepo.getCustomer(invoice.customerId);
        customerDebtCents = customer?.currentDebtCacheCents;
      }

      final service = InvoiceExportService();
      if (preview) {
        await service.preview(
          invoice: invoice,
          settings: settings,
          logoBytes: logoBytes,
          customerDebtCents: customerDebtCents,
        );
      } else {
        await service.saveAndShare(
          invoice: invoice,
          settings: settings,
          logoBytes: logoBytes,
          customerDebtCents: customerDebtCents,
        );
        showSuccessSnackBar(context, 'Đã xuất PDF — chọn Zalo để gửi');
      }
    } catch (e) {
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _delete(Invoice invoice) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hủy hóa đơn?',
      message: 'Tồn kho sẽ được hoàn lại và công nợ sẽ được trừ.',
    );
    if (ok != true) return;
    try {
      await ref.read(invoiceRepositoryProvider)?.cancelInvoice(invoice.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      showErrorSnackBar(context, e);
    }
  }
}

class _AddPaymentResult {
  const _AddPaymentResult({required this.amountCents, this.imageFile});
  final int amountCents;
  final File? imageFile;
}

class _AddPaymentDialog extends StatefulWidget {
  const _AddPaymentDialog({required this.remainingCents});
  final int remainingCents;

  @override
  State<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  final _amount = TextEditingController();
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi chọn ảnh: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm thanh toán'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              decoration: InputDecoration(
                labelText: 'Số tiền (còn ${MoneyUtils.format(widget.remainingCents)})',
                suffixText: 'đ',
              ),
            ),
            const SizedBox(height: 16),
            if (_imageFile != null) ...[
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
                  ),
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white70,
                      child: Icon(Icons.close, color: Colors.red),
                    ),
                    onPressed: () => setState(() => _imageFile = null),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Chụp ảnh'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Chọn ảnh'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () async {
                  final text = _amount.text.trim().replaceAll('.', '');
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền')));
                    return;
                  }
                  final amountVal = double.tryParse(text);
                  if (amountVal == null || amountVal <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số tiền không hợp lệ')));
                    return;
                  }
                  Navigator.pop(context, _AddPaymentResult(
                    amountCents: MoneyUtils.toCents(amountVal),
                    imageFile: _imageFile,
                  ));
                },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

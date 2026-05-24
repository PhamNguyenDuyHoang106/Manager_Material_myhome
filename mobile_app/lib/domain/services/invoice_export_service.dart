import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/money_utils.dart';
import '../entities/app_settings.dart';
import '../entities/invoice.dart';

class InvoiceExportService {
  Future<Uint8List> buildPdfBytes({
    required Invoice invoice,
    required AppSettings settings,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();
    final theme = await PdfGoogleFonts.notoSansRegular();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(base: theme),
          margin: const pw.EdgeInsets.all(32),
        ),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoBytes != null)
                pw.Container(
                  width: 64,
                  height: 64,
                  child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(settings.storeName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    if (settings.storeAddress.isNotEmpty) pw.Text(settings.storeAddress),
                    if (settings.storePhone.isNotEmpty) pw.Text('ĐT: ${settings.storePhone}'),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('HÓA ĐƠN BÁN HÀNG', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Mã: ${invoice.id.substring(0, 8).toUpperCase()}'),
                  pw.Text('Ngày: ${AppDateUtils.formatDisplay(invoice.invoiceDate)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('Khách hàng: ${invoice.customerName}', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Vật liệu', 'ĐVT', 'SL', 'Đơn giá', 'Thành tiền'],
            data: invoice.items
                .map(
                  (item) => [
                    item.materialName,
                    item.unit,
                    item.quantity.toString(),
                    MoneyUtils.format(item.sellingPriceCents),
                    MoneyUtils.format(item.lineTotalCents),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Tổng cộng: ${MoneyUtils.format(invoice.totalAmountCents)}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('Đã thanh toán: ${MoneyUtils.format(invoice.paidAmountCents)}'),
                pw.Text('Còn nợ: ${MoneyUtils.format(invoice.remainingCents)}'),
                pw.Text('Trạng thái: ${_statusLabel(invoice.status)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Center(child: pw.Text('Cảm ơn quý khách!', style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );

    return pdf.save();
  }

  String _statusLabel(InvoiceStatus status) => switch (status) {
        InvoiceStatus.paid => 'Đã thanh toán',
        InvoiceStatus.partiallyPaid => 'Thanh toán một phần',
        InvoiceStatus.unpaid => 'Chưa thanh toán',
      };

  Future<String> saveAndShare({
    required Invoice invoice,
    required AppSettings settings,
    Uint8List? logoBytes,
  }) async {
    final bytes = await buildPdfBytes(invoice: invoice, settings: settings, logoBytes: logoBytes);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/invoice_${invoice.id}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'Hóa đơn ${invoice.customerName}',
    );
    return file.path;
  }

  Future<void> preview({
    required Invoice invoice,
    required AppSettings settings,
    Uint8List? logoBytes,
  }) async {
    final bytes = await buildPdfBytes(invoice: invoice, settings: settings, logoBytes: logoBytes);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}

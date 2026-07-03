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
    int? customerDebtCents,
  }) async {
    final pdf = pw.Document();
    
    // Load Vietnamese fonts (Regular, Bold, Italic)
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final italic = await PdfGoogleFonts.notoSansItalic();
    
    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
    );

    // Sort items chronologically by delivery date (or invoice date if null)
    final sortedItems = List<InvoiceItem>.from(invoice.items);
    sortedItems.sort((a, b) {
      final dateA = a.deliveryDate ?? invoice.invoiceDate;
      final dateB = b.deliveryDate ?? invoice.invoiceDate;
      return dateA.compareTo(dateB);
    });

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
        ),
        build: (context) => [
          // Store header (Full width stacked column)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoBytes != null)
                pw.Container(
                  width: 64,
                  height: 64,
                  child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                ),
              if (logoBytes != null) pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      settings.storeName.isNotEmpty ? settings.storeName : 'Cửa hàng VLXD Hoàng Hạnh',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    if (settings.storeAddress.isNotEmpty)
                      pw.Text(settings.storeAddress),
                    if (settings.storePhone.isNotEmpty)
                      pw.Text('ĐT: ${settings.storePhone}'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),

          // Invoice Title section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'HÓA ĐƠN BÁN HÀNG',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Mã: ${invoice.id.substring(0, 8).toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Ngày: ${AppDateUtils.formatDisplay(invoice.invoiceDate.toIso8601String().substring(0, 10))}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Customer Info section
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Khách hàng: ${invoice.customerName}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                if (invoice.deliveryAddress.isNotEmpty)
                  pw.Text('Địa chỉ giao hàng: ${invoice.deliveryAddress}', style: const pw.TextStyle(fontSize: 11)),
                if (invoice.deliveryDirections.isNotEmpty)
                  pw.Text('Chỉ đường: ${invoice.deliveryDirections}', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
                if (invoice.deliveryNote.isNotEmpty)
                  pw.Text('Ghi chú: ${invoice.deliveryNote}', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Items Table
          pw.TableHelper.fromTextArray(
            headers: ['Ngày', 'Vật liệu', 'ĐVT', 'SL', 'Đơn giá', 'Thành tiền'],
            data: sortedItems
                .map(
                  (item) => [
                    AppDateUtils.formatDisplay((item.deliveryDate ?? invoice.invoiceDate).toIso8601String().substring(0, 10)),
                    item.materialName,
                    item.unit,
                    MoneyUtils.formatQty(item.quantity),
                    MoneyUtils.format(item.sellingPriceCents),
                    MoneyUtils.format(item.lineTotalCents),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
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
                pw.Text('Còn nợ hóa đơn: ${MoneyUtils.format(invoice.remainingCents)}'),
                if (customerDebtCents != null)
                  pw.Text('Tổng nợ hiện tại của khách: ${MoneyUtils.format(customerDebtCents)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
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
        InvoiceStatus.cancelled => 'Đã hủy',
      };

  Future<String> saveAndShare({
    required Invoice invoice,
    required AppSettings settings,
    Uint8List? logoBytes,
    int? customerDebtCents,
  }) async {
    final bytes = await buildPdfBytes(
      invoice: invoice, 
      settings: settings, 
      logoBytes: logoBytes,
      customerDebtCents: customerDebtCents,
    );
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
    int? customerDebtCents,
  }) async {
    final bytes = await buildPdfBytes(
      invoice: invoice, 
      settings: settings, 
      logoBytes: logoBytes,
      customerDebtCents: customerDebtCents,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}

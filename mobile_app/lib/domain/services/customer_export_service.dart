import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/money_utils.dart';
import '../entities/app_settings.dart';
import '../entities/customer.dart';
import '../entities/customer_ledger_entry.dart';

class CustomerExportService {
  Future<Uint8List> buildPdfBytes({
    required Customer customer,
    required List<CustomerLedgerEntry> entries,
    required DateTime? startDate,
    required DateTime? endDate,
    required AppSettings settings,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();
    
    // Load Vietnamese fonts
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final italic = await PdfGoogleFonts.notoSansItalic();
    
    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
    );

    // 1. Sort all entries chronologically to compute correct running balances
    final sortedAll = List<CustomerLedgerEntry>.from(entries);
    sortedAll.sort((a, b) {
      final cmp = a.date.compareTo(b.date);
      if (cmp != 0) return cmp;
      return a.createdAt.compareTo(b.createdAt);
    });

    int running = 0;
    final balances = <String, int>{};
    for (final entry in sortedAll) {
      if (entry.type == LedgerEntryType.sale) {
        running += entry.amountCents;
      } else {
        running -= entry.amountCents;
      }
      balances[entry.id] = running;
    }

    // 2. Filter entries by date range
    var filtered = List<CustomerLedgerEntry>.from(sortedAll);
    if (startDate != null && endDate != null) {
      filtered = filtered.where((e) {
        final date = e.date;
        // Start date is inclusive (00:00:00), End date is inclusive (23:59:59)
        final startLimit = DateTime(startDate.year, startDate.month, startDate.day);
        final endLimit = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        return date.isAfter(startLimit.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endLimit.add(const Duration(seconds: 1)));
      }).toList();
    }

    // 3. Keep chronological order for PDF report table
    final finalDebt = running;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
        ),
        build: (context) => [
          // Store Header Section
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
                  pw.Text('SỔ NỢ KHÁCH HÀNG', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    startDate != null && endDate != null
                        ? 'Từ: ${AppDateUtils.formatDisplay(startDate.toIso8601String().substring(0, 10))} - Đến: ${AppDateUtils.formatDisplay(endDate.toIso8601String().substring(0, 10))}'
                        : 'Tất cả thời gian',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),

          // Customer Info Section
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Khách hàng: ${customer.name}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Số điện thoại: ${customer.phone.isNotEmpty ? customer.phone : "N/A"}'),
                    pw.Text('Địa chỉ: ${customer.address.isNotEmpty ? customer.address : "N/A"}'),
                    if (customer.note.isNotEmpty)
                      pw.Text('Ghi chú: ${customer.note}', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.orange900)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('DƯ NỢ CUỐI KỲ', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text(
                    MoneyUtils.format(finalDebt),
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: finalDebt > 0 ? PdfColors.red800 : PdfColors.green800),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Ledger Entries Table
          pw.TableHelper.fromTextArray(
            headers: ['Ngày', 'Loại giao dịch / Chi tiết', 'Phát sinh', 'Dư nợ'],
            data: filtered.map((e) {
              final bal = balances[e.id] ?? 0;
              final isSale = e.type == LedgerEntryType.sale;
              final isCancellation = e.type == LedgerEntryType.cancellation;
              
              String typeLabel = '';
              String sign = '';
              if (isSale) {
                typeLabel = 'Bán hàng';
                sign = '+';
              } else if (isCancellation) {
                typeLabel = 'Hủy hóa đơn';
                sign = '-';
              } else {
                typeLabel = 'Thanh toán';
                sign = '-';
              }

              // Build detail text
              final itemsDesc = e.items.map((item) => '${item.materialName} (${item.quantity} ${item.unit})').join(', ');
              final fullDesc = itemsDesc.isNotEmpty ? '$typeLabel: $itemsDesc' : e.description;

              return [
                AppDateUtils.formatDisplay(e.date.toIso8601String().substring(0, 10)),
                fullDesc,
                '$sign${MoneyUtils.format(e.amountCents)}',
                MoneyUtils.format(bal),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 40),

          // Signatures Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Text('Khách hàng ký nhận', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 50),
                  pw.Text('(Ký và ghi rõ họ tên)', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Người lập sổ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 50),
                  pw.Text(settings.storeName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<String> saveAndShare({
    required Customer customer,
    required List<CustomerLedgerEntry> entries,
    required DateTime? startDate,
    required DateTime? endDate,
    required AppSettings settings,
    Uint8List? logoBytes,
  }) async {
    final bytes = await buildPdfBytes(
      customer: customer,
      entries: entries,
      startDate: startDate,
      endDate: endDate,
      settings: settings,
      logoBytes: logoBytes,
    );
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ledger_${customer.name}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'Sổ nợ khách hàng ${customer.name}',
    );
    return file.path;
  }

  Future<void> preview({
    required Customer customer,
    required List<CustomerLedgerEntry> entries,
    required DateTime? startDate,
    required DateTime? endDate,
    required AppSettings settings,
    Uint8List? logoBytes,
  }) async {
    final bytes = await buildPdfBytes(
      customer: customer,
      entries: entries,
      startDate: startDate,
      endDate: endDate,
      settings: settings,
      logoBytes: logoBytes,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}

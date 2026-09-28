import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/money_utils.dart';
import '../entities/app_settings.dart';
import '../entities/supplier.dart';
import '../entities/supplier_ledger_entry.dart';

class SupplierExportService {
  Future<Uint8List> buildPdfBytes({
    required Supplier supplier,
    required List<SupplierLedgerEntry> entries,
    required DateTime? startDate,
    required DateTime? endDate,
    required AppSettings settings,
  }) async {
    final pdf = pw.Document();

    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold    = await PdfGoogleFonts.notoSansBold();
    final italic  = await PdfGoogleFonts.notoSansItalic();

    final theme = pw.ThemeData.withFont(
      base: regular, bold: bold, italic: italic,
    );

    // 1. Sort chronologically & compute running balances
    final sortedAll = List<SupplierLedgerEntry>.from(entries)
      ..sort((a, b) {
        final c = a.date.compareTo(b.date);
        return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
      });

    int running       = 0;
    int totalImport   = 0;
    int totalPayment  = 0;
    final balances    = <String, int>{};

    for (final e in sortedAll) {
      switch (e.type) {
        case SupplierLedgerEntryType.importInvoice:
          final delta = e.amountCents - e.paidAmountCents;
          running     += delta;
          totalImport += e.amountCents;
          break;
        case SupplierLedgerEntryType.payment:
          running      -= e.amountCents;
          totalPayment += e.amountCents;
          break;
        case SupplierLedgerEntryType.adjustment:
          running += e.amountCents;
          break;
        case SupplierLedgerEntryType.cancellation:
          break;
      }
      balances[e.id] = running;
    }

    // 2. Filter by date
    var filtered = List<SupplierLedgerEntry>.from(sortedAll);
    if (startDate != null && endDate != null) {
      final s   = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      filtered  = filtered.where((e) => !e.date.isBefore(s) && !e.date.isAfter(end)).toList();
    }

    // 3. Build PDF
    pdf.addPage(
      pw.MultiPage(
        theme:      theme,
        pageFormat: PdfPageFormat.a4,
        margin:     const pw.EdgeInsets.all(24),
        build: (ctx) => [
          // ── Header ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(settings.storeName.isNotEmpty
                      ? settings.storeName : 'Sổ công nợ nhà cung cấp',
                      style: pw.TextStyle(font: bold, fontSize: 14)),
                  pw.SizedBox(height: 4),
                  pw.Text('SỔ CÔNG NỢ NHÀ CUNG CẤP',
                      style: pw.TextStyle(font: bold, fontSize: 11,
                          color: PdfColors.green800)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Nhà cung cấp: ${supplier.name}',
                      style: pw.TextStyle(font: bold, fontSize: 10)),
                  if (supplier.phone.isNotEmpty)
                    pw.Text('SĐT: ${supplier.phone}',
                        style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    startDate != null && endDate != null
                        ? 'Từ ${AppDateUtils.formatDisplay(startDate.toIso8601String().substring(0,10))}'
                          ' đến ${AppDateUtils.formatDisplay(endDate.toIso8601String().substring(0,10))}'
                        : 'Xuất ngày: ${AppDateUtils.formatDisplay(DateTime.now().toIso8601String().substring(0,10))}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // ── Summary row ──
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tổng nhập: ${MoneyUtils.format(totalImport)}',
                    style: pw.TextStyle(font: bold, fontSize: 9)),
                pw.Text('Đã thanh toán: ${MoneyUtils.format(totalPayment)}',
                    style: pw.TextStyle(font: bold, fontSize: 9,
                        color: PdfColors.green700)),
                pw.Text('Còn nợ: ${MoneyUtils.format(running)}',
                    style: pw.TextStyle(font: bold, fontSize: 9,
                        color: running > 0 ? PdfColors.red700 : PdfColors.green700)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // ── Table header ──
          _buildTableHeader(bold),
          pw.SizedBox(height: 4),

          // ── Data rows ──
          ...filtered.map((e) => _buildEntryRow(e, balances[e.id] ?? 0, regular, bold)),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTableHeader(pw.Font bold) {
    return pw.Container(
      color: PdfColors.grey200,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Row(children: [
        pw.Expanded(flex: 12, child: pw.Text('Ngày',
            style: pw.TextStyle(font: bold, fontSize: 8))),
        pw.Expanded(flex: 18, child: pw.Text('Loại',
            style: pw.TextStyle(font: bold, fontSize: 8))),
        pw.Expanded(flex: 30, child: pw.Text('Vật tư / Nội dung',
            style: pw.TextStyle(font: bold, fontSize: 8))),
        pw.Expanded(flex: 18, child: pw.Text('Tiền hàng',
            style: pw.TextStyle(font: bold, fontSize: 8),
            textAlign: pw.TextAlign.right)),
        pw.Expanded(flex: 18, child: pw.Text('Dư nợ',
            style: pw.TextStyle(font: bold, fontSize: 8),
            textAlign: pw.TextAlign.right)),
      ]),
    );
  }

  pw.Widget _buildEntryRow(SupplierLedgerEntry e, int balance,
      pw.Font regular, pw.Font bold) {
    String typeLabel;
    PdfColor typeColor = PdfColors.black;

    switch (e.type) {
      case SupplierLedgerEntryType.importInvoice:
        typeLabel = 'Đơn nhập';
        typeColor = PdfColors.red700;
        break;
      case SupplierLedgerEntryType.payment:
        typeLabel = 'Thanh toán';
        typeColor = PdfColors.green700;
        break;
      case SupplierLedgerEntryType.adjustment:
        typeLabel = 'Điều chỉnh';
        typeColor = PdfColors.orange700;
        break;
      case SupplierLedgerEntryType.cancellation:
        typeLabel = 'Hủy';
        typeColor = PdfColors.grey600;
        break;
    }

    final itemsText = e.items.isNotEmpty
        ? e.items
            .map((i) =>
                '${i.materialName}: ${MoneyUtils.formatQty(i.quantity)} ${i.unit}')
            .join('\n')
        : e.description;

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
              flex: 12,
              child: pw.Text(
                  AppDateUtils.formatDisplay(
                      e.date.toIso8601String().substring(0, 10)),
                  style: const pw.TextStyle(fontSize: 8))),
          pw.Expanded(
              flex: 18,
              child: pw.Text(typeLabel,
                  style: pw.TextStyle(
                      font: bold, fontSize: 8, color: typeColor))),
          pw.Expanded(
              flex: 30,
              child: pw.Text(itemsText,
                  style: const pw.TextStyle(fontSize: 8))),
          pw.Expanded(
              flex: 18,
              child: pw.Text(MoneyUtils.format(e.amountCents),
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.right)),
          pw.Expanded(
              flex: 18,
              child: pw.Text(MoneyUtils.format(balance),
                  style: pw.TextStyle(
                      font: bold,
                      fontSize: 8,
                      color:
                          balance > 0 ? PdfColors.red700 : PdfColors.green700),
                  textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }
}

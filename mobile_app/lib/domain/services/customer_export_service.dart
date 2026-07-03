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

    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final italic = await PdfGoogleFonts.notoSansItalic();

    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
    );

    // ── 1. Sort all entries chronologically & compute running balances ──
    final sortedAll = List<CustomerLedgerEntry>.from(entries)
      ..sort((a, b) {
        final cmp = a.date.compareTo(b.date);
        return cmp != 0 ? cmp : a.createdAt.compareTo(b.createdAt);
      });

    int running = 0;
    final balances = <String, int>{};
    int totalSaleCents = 0;
    int totalPaymentCents = 0;

    for (final e in sortedAll) {
      if (e.type == LedgerEntryType.sale) {
        running += e.amountCents;
        totalSaleCents += e.amountCents;
      } else if (e.type == LedgerEntryType.cancellation) {
        running -= e.amountCents;
        totalSaleCents -= e.amountCents;
      } else if (e.type == LedgerEntryType.payment) {
        running -= e.amountCents;
        totalPaymentCents += e.amountCents;
      } else if (e.type == LedgerEntryType.paymentReversal) {
        running += e.amountCents;
        totalPaymentCents -= e.amountCents;
      }
      balances[e.id] = running;
    }

    // ── 2. Filter by date range ──────────────────────────────────────
    var filtered = List<CustomerLedgerEntry>.from(sortedAll);
    if (startDate != null && endDate != null) {
      filtered = filtered.where((e) {
        final s = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        return !e.date.isBefore(s) && !e.date.isAfter(end);
      }).toList();
    }

    // ── 3. Group filtered entries by day key ─────────────────────────
    final Map<String, List<CustomerLedgerEntry>> byDay = {};
    for (final e in filtered) {
      final key = e.date.toIso8601String().substring(0, 10);
      byDay.putIfAbsent(key, () => []).add(e);
    }
    final sortedDays = byDay.keys.toList()..sort();

    // ── 4. Build table rows ──────────────────────────────────────────
    // Each row: [date, vật liệu, đơn vị, đã TT, dư nợ]
    // Styles
    final headerStyle = const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
    final cellStyle = const pw.TextStyle(fontSize: 8);
    final cellStyleBold = const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8);
    final cellStyleGreen = const pw.TextStyle(fontSize: 8, color: PdfColors.green800);

    // Border color (#666)
    const borderColor = PdfColor.fromInt(0xff666666);
    final borderSide = pw.BorderSide(color: borderColor, width: 1.0);

    // Tally filtered payment total and sale total for footer
    int filteredPaymentTotal = 0;
    int filteredSaleTotal = 0;
    for (final e in filtered) {
      if (e.type == LedgerEntryType.payment) filteredPaymentTotal += e.amountCents;
      if (e.type == LedgerEntryType.sale) filteredSaleTotal += e.amountCents;
      if (e.type == LedgerEntryType.cancellation) filteredSaleTotal -= e.amountCents;
    }

    pw.Widget buildCell(
      String text, {
      pw.TextStyle? style,
      pw.Alignment alignment = pw.Alignment.centerLeft,
      required int rowIdx,
      required int colIdx,
      bool isHeader = false,
      bool isFirstInGroup = true,
      bool isLastInGroup = true,
      bool isGroupedColumn = false,
      bool drawLeftBorder = true,
      bool isLastRow = false,
      PdfColor? backgroundColor,
    }) {
      final hasTop = rowIdx == 0 || !isGroupedColumn || isFirstInGroup;
      final hasLeft = colIdx == 0 || drawLeftBorder;
      final hasBottom = isLastRow || (isGroupedColumn && isLastInGroup);
      final hasRight = colIdx == 6;

      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        constraints: const pw.BoxConstraints(minHeight: 28),
        decoration: pw.BoxDecoration(
          color: isHeader ? PdfColors.grey200 : backgroundColor,
          border: pw.Border(
            top: hasTop ? borderSide : pw.BorderSide.none,
            left: hasLeft ? borderSide : pw.BorderSide.none,
            bottom: hasBottom ? borderSide : pw.BorderSide.none,
            right: hasRight ? borderSide : pw.BorderSide.none,
          ),
        ),
        alignment: alignment,
        child: pw.Text(
          text,
          style: style ?? (isHeader ? headerStyle : cellStyle),
          textAlign: alignment == pw.Alignment.centerRight
              ? pw.TextAlign.right
              : (alignment == pw.Alignment.centerLeft ? pw.TextAlign.left : pw.TextAlign.center),
        ),
      );
    }

    // Build header row
    final headerRow = pw.TableRow(children: [
      buildCell('Ngày', rowIdx: 0, colIdx: 0, isHeader: true, alignment: pw.Alignment.center),
      buildCell('Vật liệu', rowIdx: 0, colIdx: 1, isHeader: true, alignment: pw.Alignment.centerLeft),
      buildCell('Số lượng', rowIdx: 0, colIdx: 2, isHeader: true, alignment: pw.Alignment.center),
      buildCell('Đơn vị', rowIdx: 0, colIdx: 3, isHeader: true, alignment: pw.Alignment.center),
      buildCell('Giá', rowIdx: 0, colIdx: 4, isHeader: true, alignment: pw.Alignment.centerRight),
      buildCell('Đã thanh toán', rowIdx: 0, colIdx: 5, isHeader: true, alignment: pw.Alignment.centerRight),
      buildCell('Tiền', rowIdx: 0, colIdx: 6, isHeader: true, alignment: pw.Alignment.centerRight),
    ]);

    // Build data rows grouped by day
    final dataRows = <pw.TableRow>[];
    int globalRowIdx = 1;

    for (final day in sortedDays) {
      final dayEntries = byDay[day]!;
      dayEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final dayLabel = AppDateUtils.formatDisplay(day);

      final rowData = <Map<String, dynamic>>[];
      int daySaleTotal = 0;
      int dayPaymentTotal = 0;

      for (final e in dayEntries) {
        if (e.type == LedgerEntryType.sale) {
          daySaleTotal += e.amountCents;
          if (e.items.isNotEmpty) {
            for (final item in e.items) {
              rowData.add({
                'material': item.materialName,
                'quantity': item.quantity,
                'unit': item.unit,
                'price': item.sellingPriceCents,
              });
            }
          } else {
            rowData.add({
              'material': e.description.isNotEmpty ? e.description : 'Bán hàng',
              'quantity': null,
              'unit': '',
              'price': e.amountCents,
            });
          }
        } else if (e.type == LedgerEntryType.cancellation) {
          daySaleTotal -= e.amountCents;
          rowData.add({
            'material': e.description.isNotEmpty ? e.description : 'Hủy hóa đơn',
            'quantity': null,
            'unit': '',
            'price': -e.amountCents,
          });
        } else if (e.type == LedgerEntryType.payment) {
          dayPaymentTotal += e.amountCents;
        } else if (e.type == LedgerEntryType.paymentReversal) {
          dayPaymentTotal -= e.amountCents;
        }
      }

      if (rowData.isEmpty) {
        rowData.add({'material': '', 'quantity': null, 'unit': '', 'price': null});
      }

      final dayTotalLabel = daySaleTotal != 0 ? MoneyUtils.format(daySaleTotal) : '';
      final dayPaymentLabel = dayPaymentTotal != 0 ? MoneyUtils.format(dayPaymentTotal) : '';
      final N = rowData.length;

      for (int i = 0; i < N; i++) {
        final r = rowData[i];
        final isFirst = i == 0;
        final isLast = i == N - 1;

        dataRows.add(pw.TableRow(children: [
          buildCell(isFirst ? dayLabel : '', rowIdx: globalRowIdx, colIdx: 0, isFirstInGroup: isFirst, isLastInGroup: isLast, isGroupedColumn: true, alignment: pw.Alignment.center),
          buildCell(r['material'] as String, rowIdx: globalRowIdx, colIdx: 1),
          buildCell(r['quantity'] != null ? MoneyUtils.formatQty(r['quantity'] as double) : '', rowIdx: globalRowIdx, colIdx: 2, alignment: pw.Alignment.center),
          buildCell(r['unit'] as String, rowIdx: globalRowIdx, colIdx: 3, alignment: pw.Alignment.center),
          buildCell(r['price'] != null ? MoneyUtils.format(r['price'] as int) : '', rowIdx: globalRowIdx, colIdx: 4, alignment: pw.Alignment.centerRight),
          buildCell(isFirst ? dayPaymentLabel : '', rowIdx: globalRowIdx, colIdx: 5, isFirstInGroup: isFirst, isLastInGroup: isLast, isGroupedColumn: true, style: cellStyleGreen, alignment: pw.Alignment.centerRight),
          buildCell(isFirst ? dayTotalLabel : '', rowIdx: globalRowIdx, colIdx: 6, isFirstInGroup: isFirst, isLastInGroup: isLast, isGroupedColumn: true, alignment: pw.Alignment.centerRight),
        ]));
        globalRowIdx++;
      }
    }

    // ── Summary rows ─────────────────────────────────────────────────
    final lastRowIdx1 = globalRowIdx;
    final rowTotal = pw.TableRow(children: [
      buildCell('TỔNG', rowIdx: lastRowIdx1, colIdx: 0, style: cellStyleBold, alignment: pw.Alignment.center, backgroundColor: PdfColors.grey100),
      buildCell('', rowIdx: lastRowIdx1, colIdx: 1, drawLeftBorder: true, backgroundColor: PdfColors.grey100),
      buildCell('', rowIdx: lastRowIdx1, colIdx: 2, drawLeftBorder: false, backgroundColor: PdfColors.grey100),
      buildCell('', rowIdx: lastRowIdx1, colIdx: 3, drawLeftBorder: false, backgroundColor: PdfColors.grey100),
      buildCell('', rowIdx: lastRowIdx1, colIdx: 4, drawLeftBorder: false, backgroundColor: PdfColors.grey100),
      buildCell(MoneyUtils.format(filteredPaymentTotal), rowIdx: lastRowIdx1, colIdx: 5, style: cellStyleBold, alignment: pw.Alignment.centerRight, backgroundColor: PdfColors.grey100),
      buildCell(MoneyUtils.format(filteredSaleTotal), rowIdx: lastRowIdx1, colIdx: 6, style: cellStyleBold, alignment: pw.Alignment.centerRight, backgroundColor: PdfColors.grey100),
    ]);
    dataRows.add(rowTotal);
    globalRowIdx++;

    final diff = filteredSaleTotal - filteredPaymentTotal;
    final String diffLabel = diff > 0 ? 'CÒN THIẾU' : 'CÒN THỪA';
    final String diffValue = MoneyUtils.format(diff > 0 ? diff : -diff);
    final pw.TextStyle diffStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 8,
      color: diff > 0 ? PdfColors.red800 : PdfColors.green800,
    );

    final lastRowIdx2 = globalRowIdx;
    final rowDiff = pw.TableRow(children: [
      buildCell(diffLabel, rowIdx: lastRowIdx2, colIdx: 0, style: diffStyle, alignment: pw.Alignment.centerLeft, isLastRow: true, backgroundColor: PdfColors.grey100),
      buildCell('', rowIdx: lastRowIdx2, colIdx: 1, drawLeftBorder: true, isLastRow: true, backgroundColor: PdfColors.grey100),
      buildCell('', rowIdx: lastRowIdx2, colIdx: 2, drawLeftBorder: false, isLastRow: true, backgroundColor: PdfColors.grey100),
      buildCell('', rowIdx: lastRowIdx2, colIdx: 3, drawLeftBorder: false, isLastRow: true, backgroundColor: PdfColors.grey100),
      buildCell('', rowIdx: lastRowIdx2, colIdx: 4, drawLeftBorder: false, isLastRow: true, backgroundColor: PdfColors.grey100),
      buildCell('', rowIdx: lastRowIdx2, colIdx: 5, drawLeftBorder: false, isLastRow: true, backgroundColor: PdfColors.grey100),
      buildCell(diffValue, rowIdx: lastRowIdx2, colIdx: 6, style: diffStyle, alignment: pw.Alignment.centerRight, isLastRow: true, backgroundColor: PdfColors.grey100),
    ]);
    dataRows.add(rowDiff);

    // ── 5. Build PDF page ─────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          margin: const pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          // Header (Centered)
          pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoBytes != null) ...[
                  pw.Container(
                    height: 48,
                    child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(height: 8),
                ],
                pw.Text(
                  settings.storeName,
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                if (settings.storeAddress.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    settings.storeAddress,
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
                if (settings.storePhone.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'ĐT: ${settings.storePhone}',
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 12),

          // Customer info (Left-aligned)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Khách hàng: ${customer.name}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Số điện thoại: ${customer.phone.isNotEmpty ? customer.phone : "N/A"}',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 4),
              pw.Text('Địa chỉ: ${customer.address.isNotEmpty ? customer.address : "N/A"}',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              'SỔ CHI TIẾT CÔNG NỢ',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),

          // Table
          pw.Table(
            columnWidths: const {
              0: pw.FractionColumnWidth(0.12),
              1: pw.FractionColumnWidth(0.23),
              2: pw.FractionColumnWidth(0.12),
              3: pw.FractionColumnWidth(0.09),
              4: pw.FractionColumnWidth(0.13),
              5: pw.FractionColumnWidth(0.18),
              6: pw.FractionColumnWidth(0.13),
            },
            children: [headerRow, ...dataRows],
          ),
          pw.SizedBox(height: 28),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Text('Khách hàng ký nhận',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 48),
                  pw.Text('(Ký và ghi rõ họ tên)',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Người lập sổ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 48),
                  pw.Text(settings.storeName,
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
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

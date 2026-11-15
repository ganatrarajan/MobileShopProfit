import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/dashboard/models/profit_ledger_model.dart';
import 'app_feedback.dart';
import 'used_mobile_export_helper.dart';

class ProfitLedgerExportHelper {
  static String _escapeCsv(dynamic value) {
    if (value == null) return '""';
    final str = value.toString().replaceAll('"', '""');
    return '"$str"';
  }

  /// Export Profit Ledger to CSV / Excel compatible spreadsheet
  static Future<void> exportToCsv({
    required BuildContext context,
    required ProfitLedgerResponse data,
    required String shopName,
  }) async {
    try {
      final buffer = StringBuffer();

      // UTF-8 BOM so Microsoft Excel opens it cleanly with Rupee symbols
      buffer.write('\uFEFF');

      // Title & Metadata Section
      buffer.writeln(_escapeCsv('$shopName - NET PROFIT STATEMENT & LEDGER'));
      final now = DateTime.now();
      final nowStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      buffer.writeln('${_escapeCsv("Generated on")},${_escapeCsv(nowStr)}');
      buffer.writeln(
          '${_escapeCsv("Filter Period")},${_escapeCsv("${data.period.toUpperCase()} (${data.startDate} to ${data.endDate})")}');
      buffer.writeln(
          '${_escapeCsv("Category")},${_escapeCsv(data.category.toUpperCase())}');
      buffer.writeln('');

      // Summary KPIs Block
      buffer.writeln(
          '${_escapeCsv("TOTAL NET PROFIT")},${_escapeCsv("₹ ${data.summary.totalNetProfit.toStringAsFixed(2)}")},${_escapeCsv("Total Revenue")},${_escapeCsv("₹ ${data.summary.totalRevenue.toStringAsFixed(2)}")},${_escapeCsv("Total Costs")},${_escapeCsv("₹ ${data.summary.totalCost.toStringAsFixed(2)}")},${_escapeCsv("Transactions")},${_escapeCsv("${data.summary.totalCount}")}');
      buffer.writeln(
          '${_escapeCsv("Sales Profit")},${_escapeCsv("₹ ${data.summary.salesProfit.toStringAsFixed(2)} (${data.summary.salesCount} Sales)")},${_escapeCsv("Repair Profit")},${_escapeCsv("₹ ${data.summary.repairProfit.toStringAsFixed(2)} (${data.summary.repairCount} Repairs)")},${_escapeCsv("Used Mobile Profit")},${_escapeCsv("₹ ${data.summary.usedMobileProfit.toStringAsFixed(2)} (${data.summary.usedMobileCount} Phones)")}');
      buffer.writeln('');

      // Table Header
      buffer.writeln([
        _escapeCsv('#'),
        _escapeCsv('Date'),
        _escapeCsv('Type'),
        _escapeCsv('Reference No'),
        _escapeCsv('Customer Name'),
        _escapeCsv('Phone'),
        _escapeCsv('Item / Device Description'),
        _escapeCsv('Cost Breakdown'),
        _escapeCsv('Revenue (₹)'),
        _escapeCsv('Total Cost (₹)'),
        _escapeCsv('Net Profit (₹)'),
        _escapeCsv('Margin %'),
      ].join(','));

      // Table Rows
      int index = 1;
      for (final item in data.items) {
        buffer.writeln([
          _escapeCsv(index++),
          _escapeCsv(item.formattedDate),
          _escapeCsv(item.typeLabel),
          _escapeCsv(item.refNumber),
          _escapeCsv(item.customerName),
          _escapeCsv(item.customerPhone),
          _escapeCsv(item.title),
          _escapeCsv(item.costBreakdown),
          _escapeCsv(item.revenue.toStringAsFixed(2)),
          _escapeCsv(item.cost.toStringAsFixed(2)),
          _escapeCsv(item.profit.toStringAsFixed(2)),
          _escapeCsv('${item.profitMargin.toStringAsFixed(1)}%'),
        ].join(','));
      }

      // Total Row
      buffer.writeln('');
      buffer.writeln([
        _escapeCsv(''),
        _escapeCsv('TOTALS'),
        _escapeCsv(''),
        _escapeCsv(''),
        _escapeCsv(''),
        _escapeCsv(''),
        _escapeCsv(''),
        _escapeCsv(''),
        _escapeCsv(data.summary.totalRevenue.toStringAsFixed(2)),
        _escapeCsv(data.summary.totalCost.toStringAsFixed(2)),
        _escapeCsv(data.summary.totalNetProfit.toStringAsFixed(2)),
        _escapeCsv(''),
      ].join(','));

      final bytes = utf8.encode(buffer.toString());
      final safePeriod = data.period.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName =
          'Profit_Statement_${safePeriod}_${DateTime.now().millisecondsSinceEpoch}.csv';

      final savedFile = await UsedMobileExportHelper.saveFileToDevice(
        fileName: fileName,
        bytes: bytes,
      );

      if (savedFile != null && context.mounted) {
        UsedMobileExportHelper.showDownloadSuccessDialog(
          context,
          title: '📊 Profit Excel / CSV Exported',
          fileName: fileName,
          filePath: savedFile.path,
          mimeType: 'text/csv',
        );
      } else if (context.mounted) {
        AppFeedback.showError(context, message: 'Failed to save CSV file to device.');
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, message: 'Export error: $e');
      }
    }
  }

  /// Export Profit Ledger to professional PDF Report
  static Future<void> exportToPdf({
    required BuildContext context,
    required ProfitLedgerResponse data,
    required String shopName,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shopName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'NET PROFIT LEDGER & BUSINESS PERFORMANCE STATEMENT',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal800,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Period: ${data.period.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                        pw.Text(
                          '${data.startDate} to ${data.endDate}',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 6),
              ],
            );
          },
          build: (pw.Context ctx) {
            return [
              // Summary Cards Row
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.teal200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL NET PROFIT',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.SizedBox(height: 2),
                        pw.Text('Rs. ${data.summary.totalNetProfit.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                                fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Sales Profit',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        pw.Text('Rs. ${data.summary.salesProfit.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Repair Profit',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        pw.Text('Rs. ${data.summary.repairProfit.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Used Mob. Profit',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        pw.Text('Rs. ${data.summary.usedMobileProfit.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan900)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Ledger Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                headers: [
                  '#',
                  'Date',
                  'Type',
                  'Ref No.',
                  'Customer / Item Details',
                  'Revenue',
                  'Total Cost',
                  'Net Profit',
                ],
                data: List.generate(data.items.length, (i) {
                  final it = data.items[i];
                  return [
                    '${i + 1}',
                    it.formattedDate,
                    it.typeLabel,
                    it.refNumber,
                    '${it.customerName}\n${it.title}',
                    'Rs. ${it.revenue.toStringAsFixed(0)}',
                    'Rs. ${it.cost.toStringAsFixed(0)}',
                    'Rs. ${it.profit.toStringAsFixed(0)}',
                  ];
                }),
              ),
              pw.SizedBox(height: 10),

              // Footer Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Text(
                      'TOTAL NET PROFIT: Rs. ${data.summary.totalNetProfit.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final safePeriod = data.period.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName =
          'Profit_Statement_${safePeriod}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final savedFile = await UsedMobileExportHelper.saveFileToDevice(
        fileName: fileName,
        bytes: pdfBytes,
      );

      if (savedFile != null && context.mounted) {
        UsedMobileExportHelper.showDownloadSuccessDialog(
          context,
          title: '📄 Profit PDF Report Saved',
          fileName: fileName,
          filePath: savedFile.path,
          mimeType: 'application/pdf',
        );
      } else if (context.mounted) {
        // Fallback: Preview using printing
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, message: 'PDF Generation error: $e');
      }
    }
  }
}

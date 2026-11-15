import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'app_feedback.dart';
import 'used_mobile_export_helper.dart';

class ReportExportSummaryItem {
  final String title;
  final String value;

  const ReportExportSummaryItem({
    required this.title,
    required this.value,
  });
}

class ReportExportHelper {
  static String _escapeCsv(dynamic value) {
    if (value == null) return '""';
    final str = value.toString().replaceAll('"', '""');
    return '"$str"';
  }

  /// Export generic report data to CSV / Excel compatible spreadsheet
  static Future<void> exportToCsv({
    required BuildContext context,
    required String reportTitle,
    required String shopName,
    required String period,
    required List<String> headers,
    required List<List<dynamic>> rows,
    List<ReportExportSummaryItem> summaryItems = const [],
    List<dynamic>? totalsRow,
  }) async {
    try {
      final buffer = StringBuffer();

      // UTF-8 BOM so Microsoft Excel opens it cleanly with Rupee symbols
      buffer.write('\uFEFF');

      // Title & Metadata Section
      buffer.writeln(_escapeCsv('${shopName.toUpperCase()} - ${reportTitle.toUpperCase()}'));
      final now = DateTime.now();
      final nowStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      buffer.writeln('${_escapeCsv("Generated on")},${_escapeCsv(nowStr)}');
      buffer.writeln('${_escapeCsv("Period / Filter")},${_escapeCsv(period.toUpperCase())}');
      buffer.writeln('');

      // Summary KPIs Block
      if (summaryItems.isNotEmpty) {
        final summaryHeader = summaryItems.map((s) => _escapeCsv(s.title)).join(',');
        final summaryValues = summaryItems.map((s) => _escapeCsv(s.value)).join(',');
        buffer.writeln(summaryHeader);
        buffer.writeln(summaryValues);
        buffer.writeln('');
      }

      // Table Header
      buffer.writeln(headers.map((h) => _escapeCsv(h)).join(','));

      // Table Rows
      for (final row in rows) {
        buffer.writeln(row.map((cell) => _escapeCsv(cell)).join(','));
      }

      // Totals Row
      if (totalsRow != null && totalsRow.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(totalsRow.map((cell) => _escapeCsv(cell)).join(','));
      }

      final bytes = utf8.encode(buffer.toString());
      final safeTitle = reportTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.csv';

      final savedFile = await UsedMobileExportHelper.saveFileToDevice(
        fileName: fileName,
        bytes: bytes,
      );

      if (savedFile != null && context.mounted) {
        UsedMobileExportHelper.showDownloadSuccessDialog(
          context,
          title: '📊 $reportTitle Excel / CSV Exported',
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

  /// Export generic report data to professional multipage PDF
  static Future<void> exportToPdf({
    required BuildContext context,
    required String reportTitle,
    required String shopName,
    required String period,
    required List<String> headers,
    required List<List<dynamic>> rows,
    List<ReportExportSummaryItem> summaryItems = const [],
    List<dynamic>? totalsRow,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(22),
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
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          reportTitle.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo800,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Period: ${period.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                        pw.Text(
                          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 4),
              ],
            );
          },
          build: (pw.Context ctx) {
            return [
              // Summary KPI cards (if any)
              if (summaryItems.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.blue200),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: summaryItems.map((item) {
                      // Replace Rupee symbol with Rs. for standard PDF fonts
                      final cleanVal = item.value.replaceAll('₹', 'Rs. ');
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            item.title.toUpperCase(),
                            style: pw.TextStyle(fontSize: 7.5, color: PdfColors.blueGrey700, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            cleanVal,
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                pw.SizedBox(height: 10),
              ],

              // Main Data Table
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: rows.map((r) {
                  return r.map((cell) {
                    if (cell == null) return '';
                    return cell.toString().replaceAll('₹', 'Rs. ');
                  }).toList();
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellStyle: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
              ),

              // Totals Row (if any)
              if (totalsRow != null && totalsRow.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: totalsRow.map((cell) {
                      final str = cell != null ? cell.toString().replaceAll('₹', 'Rs. ') : '';
                      return pw.Text(
                        str,
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ];
          },
          footer: (pw.Context ctx) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Report Generated by Mobile Shop Management System',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  pw.Text('Date: ${DateTime.now().toIso8601String().split('T')[0]}',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                ],
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final safeTitle = reportTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final savedFile = await UsedMobileExportHelper.saveFileToDevice(
        fileName: fileName,
        bytes: bytes,
      );

      if (savedFile != null && context.mounted) {
        UsedMobileExportHelper.showDownloadSuccessDialog(
          context,
          title: '📄 $reportTitle PDF Exported',
          fileName: fileName,
          filePath: savedFile.path,
          mimeType: 'application/pdf',
        );
      } else if (context.mounted) {
        AppFeedback.showError(context, message: 'Failed to save PDF to device.');
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, message: 'PDF export error: $e');
      }
    }
  }

  /// Generic AppBar action button that shows a popup menu for PDF & Excel download
  static Widget buildExportActionButton({
    required VoidCallback onExportPdf,
    required VoidCallback onExportExcel,
    Color iconColor = Colors.white,
  }) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.download_rounded, color: iconColor),
      tooltip: 'Download Report (PDF / Excel)',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (val == 'pdf') {
          onExportPdf();
        } else if (val == 'excel') {
          onExportExcel();
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 10),
              Text('Download PDF Report', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.table_view_rounded, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 10),
              Text('Download Excel / CSV', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}


import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/utils/used_mobile_export_helper.dart';
import '../models/customer.dart';

class CustomerExportHelper {
  static String _escapeCsv(dynamic value) {
    if (value == null) return '""';
    final str = value.toString().replaceAll('"', '""');
    return '"$str"';
  }

  /// 1. Export Customers to Excel (.csv format with UTF-8 BOM)
  static Future<void> exportToExcelCsv({
    required BuildContext context,
    required List<Customer> customers,
    required String shopName,
  }) async {
    try {
      final buffer = StringBuffer();
      // UTF-8 BOM so Microsoft Excel opens it cleanly with Rupee & Special Characters
      buffer.write('\uFEFF');

      final now = DateTime.now();
      final nowStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Header info
      buffer.writeln('${_escapeCsv(shopName)} - CUSTOMER DIRECTORY & BALANCE REPORT');
      buffer.writeln('Generated on:,${_escapeCsv(nowStr)}');
      buffer.writeln('Total Customers:,${customers.length}');

      final double totalOutstanding = customers.fold(0.0, (sum, c) => sum + c.totalDue);
      buffer.writeln('Total Outstanding Balance:,₹${totalOutstanding.toStringAsFixed(2)}');
      buffer.writeln(); // Empty row

      // Table columns
      buffer.writeln(
        [
          _escapeCsv('#'),
          _escapeCsv('Customer Name'),
          _escapeCsv('Mobile Number'),
          _escapeCsv('Alternate Mobile'),
          _escapeCsv('Email Address'),
          _escapeCsv('City'),
          _escapeCsv('Address'),
          _escapeCsv('Outstanding Due (₹)'),
          _escapeCsv('Total Spent (₹)'),
          _escapeCsv('Repairs Count'),
          _escapeCsv('Sales Count'),
          _escapeCsv('Customer Notes'),
          _escapeCsv('Created Date'),
        ].join(','),
      );

      // Data Rows
      for (int i = 0; i < customers.length; i++) {
        final c = customers[i];
        buffer.writeln(
          [
            _escapeCsv(i + 1),
            _escapeCsv(c.name),
            _escapeCsv(c.mobile),
            _escapeCsv(c.alternateMobile ?? ''),
            _escapeCsv(c.email ?? ''),
            _escapeCsv(c.city ?? ''),
            _escapeCsv(c.address ?? ''),
            _escapeCsv(c.totalDue.toStringAsFixed(2)),
            _escapeCsv(c.totalSpent.toStringAsFixed(2)),
            _escapeCsv(c.repairsCount),
            _escapeCsv(c.salesCount),
            _escapeCsv(c.notes ?? ''),
            _escapeCsv(c.createdAt ?? ''),
          ].join(','),
        );
      }

      final bytes = utf8.encode(buffer.toString());
      final fileName = 'Customers_${shopName.replaceAll(RegExp(r'\W+'), '_')}_${now.day}_${now.month}_${now.year}.csv';

      final savedFile = await UsedMobileExportHelper.saveFileToDevice(
        fileName: fileName,
        bytes: bytes,
      );

      if (savedFile != null && context.mounted) {
        UsedMobileExportHelper.showDownloadSuccessDialog(
          context,
          title: '📊 Customer Excel (.csv) Downloaded',
          fileName: fileName,
          filePath: savedFile.path,
          mimeType: 'text/csv',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 2. Export Customers to Professional PDF Document
  static Future<void> exportToPdf({
    required BuildContext context,
    required List<Customer> customers,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      final double totalOutstanding = customers.fold(0.0, (sum, c) => sum + c.totalDue);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (pw.Context ctx) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shopName.toUpperCase(),
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      if (shopAddress != null && shopAddress.isNotEmpty)
                        pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      if (shopPhone != null && shopPhone.isNotEmpty)
                        pw.Text('Tel: $shopPhone', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'CUSTOMER DIRECTORY',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                      pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            );
          },
          build: (pw.Context ctx) => [
            // KPI / Stats Bar
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('TOTAL CUSTOMERS', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('${customers.length}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ],
                  ),
                  pw.Container(height: 24, width: 1, color: PdfColors.grey300),
                  pw.Column(
                    children: [
                      pw.Text('CUSTOMERS WITH DUES', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${customers.where((c) => c.totalDue > 0).length}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                      ),
                    ],
                  ),
                  pw.Container(height: 24, width: 1, color: PdfColors.grey300),
                  pw.Column(
                    children: [
                      pw.Text('TOTAL OUTSTANDING BALANCE', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Rs. ${totalOutstanding.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Customers Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26), // #
                1: const pw.FlexColumnWidth(3),   // Name
                2: const pw.FlexColumnWidth(2.2), // Mobile
                3: const pw.FlexColumnWidth(2),   // City
                4: const pw.FlexColumnWidth(1.4), // Repairs
                5: const pw.FlexColumnWidth(1.4), // Sales
                6: const pw.FlexColumnWidth(2.2), // Due
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _buildTh('#', align: pw.TextAlign.center),
                    _buildTh('Customer Name'),
                    _buildTh('Mobile'),
                    _buildTh('City'),
                    _buildTh('Repairs', align: pw.TextAlign.center),
                    _buildTh('Sales', align: pw.TextAlign.center),
                    _buildTh('Balance Due', align: pw.TextAlign.right),
                  ],
                ),
                // Table Rows
                ...customers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final c = entry.value;
                  final isEven = idx % 2 == 0;
                  final hasDue = c.totalDue > 0;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey50),
                    children: [
                      _buildTd('${idx + 1}', align: pw.TextAlign.center),
                      _buildTd(c.name, bold: true),
                      _buildTd(c.mobile),
                      _buildTd(c.city ?? '-'),
                      _buildTd('${c.repairsCount}', align: pw.TextAlign.center),
                      _buildTd('${c.salesCount}', align: pw.TextAlign.center),
                      _buildTd(
                        hasDue ? 'Rs. ${c.totalDue.toStringAsFixed(2)}' : 'Rs. 0.00',
                        align: pw.TextAlign.right,
                        bold: hasDue,
                        color: hasDue ? PdfColors.red800 : PdfColors.grey700,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final fileName = 'Customer_Directory_${shopName.replaceAll(RegExp(r'\W+'), '_')}_${now.day}_${now.month}_${now.year}.pdf';

      final savedFile = await UsedMobileExportHelper.saveFileToDevice(
        fileName: fileName,
        bytes: pdfBytes,
      );

      if (savedFile != null && context.mounted) {
        UsedMobileExportHelper.showDownloadSuccessDialog(
          context,
          title: '📄 Customer PDF Directory Downloaded',
          fileName: fileName,
          filePath: savedFile.path,
          mimeType: 'application/pdf',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _buildTh(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8.5),
      ),
    );
  }

  static pw.Widget _buildTd(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 8.5,
        ),
      ),
    );
  }

  /// 3. Generate & Download Sample CSV Template with Dummy Data
  static Future<File?> downloadSampleCsvTemplate(BuildContext context) async {
    try {
      final buffer = StringBuffer();
      // UTF-8 BOM
      buffer.write('\uFEFF');

      // Header row
      buffer.writeln('Name,Mobile,Alternate_Mobile,Email,Address,City,Notes');

      // 4 Dummy Rows
      buffer.writeln('Rajesh Patel,9876543210,9876543211,rajesh.patel@example.com,"Shop 4, Market Complex",Ahmedabad,Regular VIP customer');
      buffer.writeln('Priya Sharma,9123456780,,priya.s@example.com,"Flat 201, Royal Heights",Surat,Frequent repair visits');
      buffer.writeln('Amit Kumar,9988776655,,,Station Road Near Tower,Vadodara,Prefers WhatsApp updates');
      buffer.writeln('Suresh Verma,9822334455,9822334456,suresh@verma.in,"Plot 12, GIDC Phase 2",Rajkot,Corporate client');

      const fileName = 'Customer_Import_Sample_Template.csv';
      final bytes = utf8.encode(buffer.toString());

      final savedFile = await UsedMobileExportHelper.saveFileToDevice(
        fileName: fileName,
        bytes: bytes,
      );

      if (savedFile != null && context.mounted) {
        UsedMobileExportHelper.showDownloadSuccessDialog(
          context,
          title: '📥 Sample CSV Template Downloaded',
          fileName: fileName,
          filePath: savedFile.path,
          mimeType: 'text/csv',
        );
      }
      return savedFile;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download sample: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  /// 4. Parse CSV string into list of customer maps
  static List<Map<String, dynamic>> parseCsv(String csvContent) {
    // Remove BOM if present
    var cleanContent = csvContent;
    if (cleanContent.startsWith('\uFEFF')) {
      cleanContent = cleanContent.substring(1);
    }

    final lines = const LineSplitter().convert(cleanContent);
    if (lines.isEmpty) return [];

    final headerCols = _parseCsvLine(lines.first).map((c) => c.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '')).toList();

    final result = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = _parseCsvLine(line);
      final row = <String, dynamic>{};

      for (int c = 0; c < headerCols.length && c < cols.length; c++) {
        final key = headerCols[c];
        final val = cols[c].trim();

        if (['name', 'customername'].contains(key)) {
          row['name'] = val;
        } else if (['mobile', 'phone', 'contact', 'mobilenumber', 'phonenumber'].contains(key)) {
          row['mobile'] = val;
        } else if (['alternatemobile', 'altmobile', 'alternatephone', 'secondmobile'].contains(key)) {
          row['alternate_mobile'] = val;
        } else if (['email', 'emailaddress'].contains(key)) {
          row['email'] = val;
        } else if (['address', 'customeraddress'].contains(key)) {
          row['address'] = val;
        } else if (['city'].contains(key)) {
          row['city'] = val;
        } else if (['notes', 'note', 'remark', 'remarks'].contains(key)) {
          row['notes'] = val;
        }
      }

      if ((row['name'] != null && row['name'].toString().isNotEmpty) ||
          (row['mobile'] != null && row['mobile'].toString().isNotEmpty)) {
        result.add(row);
      }
    }

    return result;
  }

  static List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        values.add(sb.toString());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    values.add(sb.toString());
    return values;
  }
}

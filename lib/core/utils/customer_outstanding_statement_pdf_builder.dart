import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../storage/auth_storage.dart';
import 'app_feedback.dart';
import 'date_helper.dart';
import 'pdf_text_helper.dart';
import 'used_mobile_export_helper.dart';
import '../../features/reports/domain/report_models.dart';

class CustomerOutstandingStatementPdfBuilder {
  static final PdfColor brandNavy = PdfColor.fromHex('#0F172A');
  static final PdfColor brandBlue = PdfColor.fromHex('#1E40AF');
  static final PdfColor accentCrimson = PdfColor.fromHex('#DC2626');
  static final PdfColor crimsonBg = PdfColor.fromHex('#FEF2F2');
  static final PdfColor crimsonBorder = PdfColor.fromHex('#FCA5A5');
  static final PdfColor greyBg = PdfColor.fromHex('#F8FAFC');
  static final PdfColor borderGrey = PdfColor.fromHex('#E2E8F0');
  static final PdfColor textDark = PdfColor.fromHex('#1E293B');
  static final PdfColor textMuted = PdfColor.fromHex('#64748B');

  /// Generate professional customer outstanding statement PDF bytes
  static Future<Uint8List> generateStatementPdfBytes({
    required Map<String, dynamic>? shop,
    required String customerName,
    required String customerPhone,
    String? customerAddress,
    required String statementPeriod,
    required List<OutstandingReportItem> items,
  }) async {
    final pdf = pw.Document();

    final shopName = (shop?['name']?.toString() ?? 'Mobile Repair & Retail Shop').trim();
    final shopPhone = (shop?['phone']?.toString() ?? shop?['mobile']?.toString() ?? '').trim();
    final shopEmail = (shop?['email']?.toString() ?? '').trim();
    final shopAddress = [
      shop?['address']?.toString(),
      shop?['city']?.toString(),
      shop?['state']?.toString(),
      shop?['pincode']?.toString(),
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
    final gstin = (shop?['gst_number']?.toString() ?? shop?['gstin']?.toString() ?? '').trim();

    final now = DateTime.now();
    final nowFormatted = DateHelper.formatDate(now.toIso8601String());

    final totalDue = items.fold(0.0, (sum, i) => sum + i.amountDue);
    final totalBilled = items.fold(0.0, (sum, i) => sum + i.totalAmount);
    final totalPaid = items.fold(0.0, (sum, i) => sum + i.amountPaid);

    final repairItems = items.where((i) => i.category == 'repairs').toList();
    final salesItems = items.where((i) => i.category == 'sales').toList();
    final rawTerms = shop?['terms_and_conditions'] ?? shop?['terms'];
    final termsList = PdfTextHelper.parseTerms(rawTerms);

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
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shopName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: brandNavy,
                          ),
                        ),
                        if (shopAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            shopAddress,
                            style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                          ),
                        ],
                        pw.SizedBox(height: 2),
                        pw.Row(
                          children: [
                            if (shopPhone.isNotEmpty)
                              pw.Text(
                                'Phone: $shopPhone',
                                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark),
                              ),
                            if (shopPhone.isNotEmpty && shopEmail.isNotEmpty)
                              pw.Text('  |  ', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                            if (shopEmail.isNotEmpty)
                              pw.Text(
                                'Email: $shopEmail',
                                style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                              ),
                          ],
                        ),
                        if (gstin.isNotEmpty) ...[
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'GSTIN: $gstin',
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandBlue),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: brandBlue,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'OUTSTANDING STATEMENT',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Date: $nowFormatted',
                        style: pw.TextStyle(fontSize: 8.5, color: textDark),
                      ),
                      pw.Text(
                        'Period: ${statementPeriod.toUpperCase()}',
                        style: pw.TextStyle(fontSize: 8, color: textMuted),
                      ),
                      pw.Text(
                        'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                        style: pw.TextStyle(fontSize: 8, color: textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1.2, color: borderGrey),
              pw.SizedBox(height: 6),
            ],
          );
        },
        build: (pw.Context ctx) {
          return [
            // Customer Details & Outstanding Hero Box
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Customer Details Left Box
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: greyBg,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: borderGrey),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'STATEMENT FOR (CUSTOMER)',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textMuted),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          customerName.isNotEmpty ? customerName : 'Valued Customer',
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: brandNavy),
                        ),
                        if (customerPhone.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Mobile: $customerPhone',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark),
                          ),
                        ],
                        if (customerAddress != null && customerAddress.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Address: $customerAddress',
                            style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                // Prominent Hero Outstanding Due Box Right
                pw.Expanded(
                  flex: 6,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: crimsonBg,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: crimsonBorder, width: 1.2),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TOTAL OUTSTANDING BALANCE',
                              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: accentCrimson),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: accentCrimson,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(
                                'PAYMENT DUE',
                                style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Rs. ${totalDue.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: accentCrimson,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Divider(thickness: 0.5, color: crimsonBorder),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Invoiced: Rs. ${totalBilled.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 7.5, color: textDark)),
                            pw.Text('Total Paid: Rs. ${totalPaid.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            // 1. REPAIR JOBS BREAKDOWN SECTION (WITH SPARE PARTS)
            if (repairItems.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F59E0B'),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PENDING REPAIR SERVICES & USED SPARE PARTS (${repairItems.length})',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                    pw.Text(
                      'Repair Dues: Rs. ${repairItems.fold(0.0, (s, i) => s + i.amountDue).toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              ...repairItems.map((r) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: borderGrey),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Job Header
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Row(
                            children: [
                              pw.Text(
                                'Job #${r.refNumber}',
                                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: brandNavy),
                              ),
                              pw.Text('  |  Date: ${DateHelper.formatDate(r.date)}', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                              if (r.deviceName != null && r.deviceName!.isNotEmpty) ...[
                                pw.Text('  |  Device: ', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                                pw.Text(r.deviceName!, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                              ],
                            ],
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Text(
                              r.status.toUpperCase(),
                              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: textDark),
                            ),
                          ),
                        ],
                      ),

                      if (r.problemDescription != null && r.problemDescription!.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Problem Reported: ${PdfTextHelper.sanitize(r.problemDescription!.trim())}',
                          style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: textMuted),
                        ),
                      ],

                      pw.SizedBox(height: 5),

                      // Spare Parts Used Breakdown
                      if (r.parts.isNotEmpty) ...[
                        pw.Text(
                          'Spare Parts Used:',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textDark),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Table(
                          border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                          columnWidths: {
                            0: const pw.FlexColumnWidth(1),
                            1: const pw.FlexColumnWidth(6),
                            2: const pw.FlexColumnWidth(2),
                            3: const pw.FlexColumnWidth(3),
                            4: const pw.FlexColumnWidth(3),
                          },
                          children: [
                            pw.TableRow(
                              decoration: pw.BoxDecoration(color: greyBg),
                              children: [
                                _cell('#', isHeader: true),
                                _cell('Part Description', isHeader: true),
                                _cell('Qty', isHeader: true, align: pw.TextAlign.center),
                                _cell('Rate (Rs.)', isHeader: true, align: pw.TextAlign.right),
                                _cell('Total (Rs.)', isHeader: true, align: pw.TextAlign.right),
                              ],
                            ),
                            ...r.parts.asMap().entries.map((entry) {
                              final pIdx = entry.key + 1;
                              final part = entry.value;
                              final pName = PdfTextHelper.sanitize(part['part_name']?.toString() ?? 'Spare Part');
                              final pQty = (part['quantity'] ?? 1).toString();
                              final pPrice = (double.tryParse(part['selling_price']?.toString() ?? '') ?? 0.0).toStringAsFixed(2);
                              final pTotal = (double.tryParse(part['total']?.toString() ?? '') ?? 0.0).toStringAsFixed(2);

                              return pw.TableRow(
                                children: [
                                  _cell('$pIdx', align: pw.TextAlign.center),
                                  _cell(pName),
                                  _cell(pQty, align: pw.TextAlign.center),
                                  _cell(pPrice, align: pw.TextAlign.right),
                                  _cell(pTotal, align: pw.TextAlign.right),
                                ],
                              );
                            }),
                          ],
                        ),
                      ] else ...[
                        pw.Text(
                          'Spare Parts: No separate replacement parts billed (Labor / Service repair)',
                          style: pw.TextStyle(fontSize: 7.5, color: textMuted),
                        ),
                      ],

                      if (r.labourCost != null && r.labourCost! > 0) ...[
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Service / Labor Charges: Rs. ${r.labourCost!.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textDark),
                            ),
                          ],
                        ),
                      ],

                      pw.SizedBox(height: 5),
                      pw.Divider(thickness: 0.5, color: borderGrey),
                      pw.SizedBox(height: 2),

                      // Repair Financial Summary Bar
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Repair Total: Rs. ${r.totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 8, color: textDark),
                          ),
                          pw.Text(
                            'Paid / Advance: Rs. ${r.amountPaid.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.green800, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: crimsonBg,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Text(
                              'Balance Due: Rs. ${r.amountDue.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: accentCrimson),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // 2. SALES BREAKDOWN SECTION
            if (salesItems.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: brandBlue,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PENDING SALES & PRODUCTS (${salesItems.length})',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                    pw.Text(
                      'Sales Dues: Rs. ${salesItems.fold(0.0, (s, i) => s + i.amountDue).toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              ...salesItems.map((s) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: borderGrey),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Sale Header
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Row(
                            children: [
                              pw.Text(
                                'Invoice #${s.refNumber}',
                                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: brandNavy),
                              ),
                              pw.Text('  |  Date: ${DateHelper.formatDate(s.date)}', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                              pw.Text('  |  ${s.description}', style: pw.TextStyle(fontSize: 8.5, color: textDark)),
                            ],
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Text(
                              s.status.toUpperCase(),
                              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: textDark),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),

                      // Items Table
                      if (s.items.isNotEmpty) ...[
                        pw.Table(
                          border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                          columnWidths: {
                            0: const pw.FlexColumnWidth(1),
                            1: const pw.FlexColumnWidth(6),
                            2: const pw.FlexColumnWidth(2),
                            3: const pw.FlexColumnWidth(3),
                            4: const pw.FlexColumnWidth(3),
                          },
                          children: [
                            pw.TableRow(
                              decoration: pw.BoxDecoration(color: greyBg),
                              children: [
                                _cell('#', isHeader: true),
                                _cell('Item / Product Name', isHeader: true),
                                _cell('Qty', isHeader: true, align: pw.TextAlign.center),
                                _cell('Rate (Rs.)', isHeader: true, align: pw.TextAlign.right),
                                _cell('Total (Rs.)', isHeader: true, align: pw.TextAlign.right),
                              ],
                            ),
                            ...s.items.asMap().entries.map((entry) {
                              final iIdx = entry.key + 1;
                              final item = entry.value;
                              final iName = PdfTextHelper.sanitize(item['product_name']?.toString() ?? 'Item');
                              final iQty = (item['quantity'] ?? 1).toString();
                              final iPrice = (double.tryParse(item['unit_price']?.toString() ?? '') ?? 0.0).toStringAsFixed(2);
                              final iTotal = (double.tryParse(item['total']?.toString() ?? '') ?? 0.0).toStringAsFixed(2);

                              return pw.TableRow(
                                children: [
                                  _cell('$iIdx', align: pw.TextAlign.center),
                                  _cell(iName),
                                  _cell(iQty, align: pw.TextAlign.center),
                                  _cell(iPrice, align: pw.TextAlign.right),
                                  _cell(iTotal, align: pw.TextAlign.right),
                                ],
                              );
                            }),
                          ],
                        ),
                      ],

                      pw.SizedBox(height: 5),
                      pw.Divider(thickness: 0.5, color: borderGrey),
                      pw.SizedBox(height: 2),

                      // Sale Financial Summary Bar
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Invoice Total: Rs. ${s.totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 8, color: textDark),
                          ),
                          pw.Text(
                            'Amount Paid: Rs. ${s.amountPaid.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.green800, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: crimsonBg,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Text(
                              'Balance Due: Rs. ${s.amountDue.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: accentCrimson),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
            ],

            // FINAL OVERALL STATEMENT SUMMARY CARD
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: greyBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderGrey, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'OVERALL STATEMENT SUMMARY',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Invoiced / Bill Amount:', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                      pw.Text('Rs. ${totalBilled.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Amount Paid:', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                      pw.Text('Rs. ${totalPaid.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Divider(thickness: 1, color: borderGrey),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL REMAINING BALANCE DUE:',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: accentCrimson),
                      ),
                      pw.Text(
                        'Rs. ${totalDue.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accentCrimson),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // Polite payment notice
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.amber200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PAYMENT REMINDER & NOTES:',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '- Kindly review the detailed statement above and settle the outstanding balance of Rs. ${totalDue.toStringAsFixed(2)} at your earliest convenience.',
                    style: pw.TextStyle(fontSize: 7.5, color: textDark),
                  ),
                  if (shopPhone.isNotEmpty) ...[
                    pw.SizedBox(height: 1),
                    pw.Text(
                      '- For UPI / Bank payment or any clarification regarding repair parts or sales, please call/WhatsApp: $shopPhone.',
                      style: pw.TextStyle(fontSize: 7.5, color: textDark),
                    ),
                  ],
                  pw.SizedBox(height: 1),
                  pw.Text(
                    '- Thank you for your continued trust and business!',
                    style: pw.TextStyle(fontSize: 7.5, color: textDark, fontStyle: pw.FontStyle.italic),
                  ),
                ],
              ),
            ),
            if (termsList.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              PdfTextHelper.buildTermsWidget(
                terms: termsList,
                title: 'TERMS & CONDITIONS:',
                titleColor: brandNavy,
                textColor: textDark,
                textSize: 7.5,
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
                pw.Text(
                  '$shopName - Customer Dues Statement',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Generated on ${DateHelper.formatDate(DateTime.now().toIso8601String())}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _cell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? textDark : textDark,
        ),
      ),
    );
  }

  /// Download and save customer statement PDF to device
  static Future<void> downloadCustomerStatementPdf({
    required BuildContext context,
    required String customerName,
    required String customerPhone,
    String? customerAddress,
    required String statementPeriod,
    required List<OutstandingReportItem> items,
  }) async {
    try {
      final shop = await AuthStorage().getShop();
      final pdfBytes = await generateStatementPdfBytes(
        shop: shop,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        statementPeriod: statementPeriod,
        items: items,
      );

      final safeName = customerName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'Statement_${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final savedFile = await UsedMobileExportHelper.saveFileToDevice(
        fileName: fileName,
        bytes: pdfBytes,
      );

      if (savedFile != null && context.mounted) {
        UsedMobileExportHelper.showDownloadSuccessDialog(
          context,
          title: '📄 Customer Statement Downloaded',
          fileName: fileName,
          filePath: savedFile.path,
          mimeType: 'application/pdf',
        );
      } else if (context.mounted) {
        AppFeedback.showError(context, message: 'Failed to save statement PDF.');
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, message: 'Statement PDF error: $e');
      }
    }
  }

  /// Send statement directly to customer via WhatsApp with attached PDF and breakdown message
  static Future<void> sendStatementOnWhatsApp({
    required BuildContext context,
    required String customerName,
    required String customerPhone,
    String? customerAddress,
    required String statementPeriod,
    required List<OutstandingReportItem> items,
  }) async {
    try {
      final shop = await AuthStorage().getShop();
      final shopName = (shop?['name']?.toString() ?? 'Mobile Repair & Retail Shop').trim();
      final shopPhone = (shop?['phone']?.toString() ?? shop?['mobile']?.toString() ?? '').trim();

      final totalDue = items.fold(0.0, (sum, i) => sum + i.amountDue);
      final totalBilled = items.fold(0.0, (sum, i) => sum + i.totalAmount);
      final totalPaid = items.fold(0.0, (sum, i) => sum + i.amountPaid);

      final repairItems = items.where((i) => i.category == 'repairs').toList();
      final salesItems = items.where((i) => i.category == 'sales').toList();

      // Generate PDF
      final pdfBytes = await generateStatementPdfBytes(
        shop: shop,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        statementPeriod: statementPeriod,
        items: items,
      );

      final tempDir = await getTemporaryDirectory();
      final safeName = customerName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'Statement_${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Construct itemized polite WhatsApp message
      final msg = StringBuffer();
      msg.writeln('📋 *OUTSTANDING DUES STATEMENT*');
      msg.writeln('━━━━━━━━━━━━━━━━━━━━');
      msg.writeln('🏢 *$shopName*');
      if (shopPhone.isNotEmpty) msg.writeln('📞 Contact: $shopPhone');
      msg.writeln('👤 *Customer:* $customerName');
      if (customerPhone.isNotEmpty) msg.writeln('📱 Mobile: $customerPhone');
      msg.writeln('━━━━━━━━━━━━━━━━━━━━');
      msg.writeln('🔴 *TOTAL OUTSTANDING DUE: ₹${totalDue.toStringAsFixed(2)}*');
      msg.writeln('━━━━━━━━━━━━━━━━━━━━');
      msg.writeln('📊 *Financial Summary:*');
      msg.writeln('• Total Billed: ₹${totalBilled.toStringAsFixed(2)}');
      msg.writeln('• Amount Paid: ₹${totalPaid.toStringAsFixed(2)}');
      msg.writeln('• *Remaining Balance: ₹${totalDue.toStringAsFixed(2)}*');
      msg.writeln('');

      if (repairItems.isNotEmpty) {
        msg.writeln('🔧 *Pending Repairs Breakdown:*');
        for (final r in repairItems) {
          final datePart = r.date.isNotEmpty ? ' - ${DateHelper.formatDate(r.date)}' : '';
          msg.writeln('• *Job #${r.refNumber}* (${r.deviceName ?? r.description})$datePart');
          if (r.problemDescription != null && r.problemDescription!.isNotEmpty) {
            msg.writeln('   Problem: ${r.problemDescription}');
          }
          if (r.parts.isNotEmpty) {
            final partsList = r.parts.map((p) => '${p['part_name']} (x${p['quantity']})').join(', ');
            msg.writeln('   Used Parts: $partsList');
          }
          msg.writeln('   Bill: ₹${r.totalAmount.toStringAsFixed(0)} | Paid: ₹${r.amountPaid.toStringAsFixed(0)} | *Due: ₹${r.amountDue.toStringAsFixed(2)}*');
        }
        msg.writeln('');
      }

      if (salesItems.isNotEmpty) {
        msg.writeln('🛍️ *Pending Sales Breakdown:*');
        for (final s in salesItems) {
          final datePart = s.date.isNotEmpty ? ' - ${DateHelper.formatDate(s.date)}' : '';
          msg.writeln('• *Invoice #${s.refNumber}*$datePart');
          if (s.items.isNotEmpty) {
            final itemsList = s.items.map((i) => '${i['product_name']} (x${i['quantity']})').join(', ');
            msg.writeln('   Items: $itemsList');
          }
          msg.writeln('   Bill: ₹${s.totalAmount.toStringAsFixed(0)} | Paid: ₹${s.amountPaid.toStringAsFixed(0)} | *Due: ₹${s.amountDue.toStringAsFixed(2)}*');
        }
        msg.writeln('');
      }

      msg.writeln('📄 *Detailed statement PDF is attached for your complete record.*');
      msg.writeln('🙏 Kindly clear the pending balance at your earliest convenience.');
      msg.writeln('Thank you for your business!');

      // Share PDF file with caption
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
        subject: 'Outstanding Statement - $shopName',
        text: msg.toString(),
      );
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, message: 'WhatsApp sharing error: $e');
      }
    }
  }

  /// Launch direct WhatsApp chat with message pre-filled
  static Future<void> openDirectWhatsApp({
    required BuildContext context,
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) {
      AppFeedback.showError(context, message: 'No phone number available.');
      return;
    }

    final formattedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final encoded = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse('whatsapp://send?phone=$formattedPhone&text=$encoded');
    final wameUri = Uri.parse('https://wa.me/$formattedPhone?text=$encoded');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(wameUri)) {
        await launchUrl(wameUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(wameUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, message: 'Could not open WhatsApp.');
      }
    }
  }
}

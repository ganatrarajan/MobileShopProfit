import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'date_helper.dart';
import '../storage/auth_storage.dart';
import '../../features/sales/models/sale.dart';

class PdfInvoiceBuilder {
  // Brand color palette matching the requested sample design
  static final PdfColor brandBlue = PdfColor.fromHex('#0B63CE');      // Vibrant Royal Blue
  static final PdfColor headerNavy = PdfColor.fromHex('#0F172A');     // Dark Slate Navy
  static final PdfColor cardBgBlue = PdfColor.fromHex('#F4F8FD');     // Soft Blue Card Tint
  static final PdfColor borderBlue = PdfColor.fromHex('#D0E2F7');     // Light Blue Border
  static final PdfColor tableHeaderBg = PdfColor.fromHex('#E3EFFC');  // Table Header Tint
  static final PdfColor textDark = PdfColor.fromHex('#1E293B');       // Main Text
  static final PdfColor textMuted = PdfColor.fromHex('#64748B');      // Subtitle Text
  static final PdfColor watermarkColor = PdfColor.fromHex('#E2E8F0'); // Faint Shadow Watermark

  static Future<Uint8List?> _loadMediaBytes(String? rawPath) async {
    if (rawPath == null || rawPath.trim().isEmpty) return null;
    final path = rawPath.trim();
    try {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final request = await HttpClient().getUrl(Uri.parse(path));
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>([], (previous, element) => previous..addAll(element));
          return Uint8List.fromList(bytes);
        }
      } else {
        final file = File(path);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Generates a modern sales bill PDF with REPAIREHUB background watermark, clean badges & balanced height.
  static Future<Uint8List> generateInvoicePdf(Sale sale) async {
    final pdf = pw.Document();

    String shopName = 'Akash Enterprises';
    String shopAddress = '';
    String shopPhone = '';
    String shopGstin = '';
    String shopPan = '';
    List<String> termsList = [];
    Uint8List? logoBytes;
    Uint8List? signatureBytes;

    try {
      final shop = await AuthStorage().getShop();
      if (shop != null) {
        if (shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
          shopName = shop['name'].toString().trim();
        }

        final addressParts = [
          if (shop['address'] != null && shop['address'].toString().trim().isNotEmpty) shop['address'].toString().trim(),
          if (shop['state'] != null && shop['state'].toString().trim().isNotEmpty) shop['state'].toString().trim(),
          if (shop['pincode'] != null && shop['pincode'].toString().trim().isNotEmpty) shop['pincode'].toString().trim(),
        ];
        shopAddress = addressParts.join(', ');

        if (shop['mobile'] != null && shop['mobile'].toString().trim().isNotEmpty) {
          shopPhone = shop['mobile'].toString().trim();
        } else if (shop['phone'] != null && shop['phone'].toString().trim().isNotEmpty) {
          shopPhone = shop['phone'].toString().trim();
        }

        if (shop['gstin'] != null && shop['gstin'].toString().trim().isNotEmpty) {
          shopGstin = shop['gstin'].toString().trim();
        }

        if (shop['pan_number'] != null && shop['pan_number'].toString().trim().isNotEmpty) {
          shopPan = shop['pan_number'].toString().trim();
        } else if (shop['pan'] != null && shop['pan'].toString().trim().isNotEmpty) {
          shopPan = shop['pan'].toString().trim();
        }

        if (shop['terms_and_conditions'] != null && shop['terms_and_conditions'].toString().trim().isNotEmpty) {
          final termsRaw = shop['terms_and_conditions'].toString();
          termsList = termsRaw
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }

        final logoPath = shop['logo_path'] ?? shop['logo_url'] ?? shop['logo'];
        logoBytes = await _loadMediaBytes(logoPath?.toString());

        final sigPath = shop['signature_path'] ?? shop['signature_url'] ?? shop['signature'];
        signatureBytes = await _loadMediaBytes(sigPath?.toString());
      }
    } catch (_) {}

    if (termsList.isEmpty) {
      termsList = [
        '1. Customer will pay applicable taxes.',
        '2. Delivery charges non-refundable once goods leave premises.',
        '3. Pay due amount within 10 days of invoice date.',
      ];
    }

    final customerName = sale.customerName?.trim().isNotEmpty == true
        ? sale.customerName!.trim()
        : (sale.customer?.name.trim().isNotEmpty == true ? sale.customer!.name.trim() : 'Customer');

    final customerPhone = sale.customerMobile?.trim().isNotEmpty == true
        ? sale.customerMobile!.trim()
        : (sale.customer?.mobile.trim().isNotEmpty == true ? sale.customer!.mobile.trim() : '');

    final invoiceNum = sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : 'RH-INV-${sale.id}';
    final rawDate = sale.saleDate.isNotEmpty ? sale.saleDate : DateTime.now().toIso8601String();
    final dateStr = DateHelper.formatDate(rawDate);

    final contactParts = <String>[];
    if (shopPhone.isNotEmpty) contactParts.add('Phone: $shopPhone');
    if (shopGstin.isNotEmpty) contactParts.add('GSTIN: $shopGstin');
    if (shopPan.isNotEmpty) contactParts.add('PAN: $shopPan');
    final contactLine = contactParts.join('  |  ');

    final isPaidFull = sale.amountDue <= 0;
    final paymentStatusText = isPaidFull ? 'PAID' : (sale.amountPaid > 0 ? 'PARTIAL' : 'DUE');
    final paymentStatusColor = isPaidFull ? PdfColors.green700 : (sale.amountPaid > 0 ? PdfColors.orange700 : PdfColors.red700);
    final paymentStatusBg = isPaidFull ? PdfColor.fromHex('#DCFCE7') : (sale.amountPaid > 0 ? PdfColor.fromHex('#FFEDD5') : PdfColor.fromHex('#FEE2E2'));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(26),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // BACKGROUND WATERMARK SHADOW: "REPAIREHUB"
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: -0.38,
                    child: pw.Text(
                      'REPAIREHUB',
                      style: pw.TextStyle(
                        fontSize: 64,
                        fontWeight: pw.FontWeight.bold,
                        color: watermarkColor,
                      ),
                    ),
                  ),
                ),
              ),

              // MAIN CONTENT LAYOUT
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP HEADER: SHOP DETAILS & LOGO (Left) + TAGLINE (Right)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Left Side: Shop Logo & Name
                      pw.Expanded(
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            if (logoBytes != null) ...[
                              pw.Container(
                                height: 42,
                                width: 65,
                                margin: const pw.EdgeInsets.only(right: 10),
                                child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                              ),
                            ],
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    shopName,
                                    style: pw.TextStyle(
                                      fontSize: 18,
                                      fontWeight: pw.FontWeight.bold,
                                      color: headerNavy,
                                    ),
                                  ),
                                  if (shopAddress.isNotEmpty) ...[
                                    pw.SizedBox(height: 2),
                                    pw.Text(
                                      shopAddress,
                                      style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                                    ),
                                  ],
                                  if (contactLine.isNotEmpty) ...[
                                    pw.SizedBox(height: 2),
                                    pw.Text(
                                      contactLine,
                                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textDark),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right Side: Shop Tagline Promise
                      pw.Container(
                        margin: const pw.EdgeInsets.only(left: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Your Device', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                            pw.Text('Our Expertise', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                            pw.Text('A Better Tomorrow', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandBlue)),
                            pw.SizedBox(height: 2),
                            pw.Container(width: 45, height: 1.5, color: brandBlue),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 10),

                  // 2. BLUE BANNER CARD: "Sales Invoice" + Invoice No & Date
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: brandBlue,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Left Banner Title
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Sales Invoice',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'SALES   |   SERVICE   |   ACCESSORIES   |   SUPPORT',
                              style: pw.TextStyle(
                                fontSize: 7.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                        // Right Invoice Specs
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Container(width: 1, height: 28, color: PdfColors.white),
                            pw.SizedBox(width: 10),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  children: [
                                    pw.Text('Invoice No: ', style: pw.TextStyle(fontSize: 8.5, color: PdfColors.white)),
                                    pw.Text(invoiceNum, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                  ],
                                ),
                                pw.SizedBox(height: 2),
                                pw.Row(
                                  children: [
                                    pw.Text('Date: ', style: pw.TextStyle(fontSize: 8.5, color: PdfColors.white)),
                                    pw.Text(dateStr, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // 3. CUSTOMER DETAILS CARD (CLEAN EMBEDDED TYPOGRAPHY, NO TALL CIRCLE ICON)
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: cardBgBlue,
                      border: pw.Border.all(color: borderBlue, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Left Column: Customer Details
                        pw.Expanded(
                          flex: 6,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: brandBlue)),
                              pw.SizedBox(height: 2),
                              pw.Text(customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: headerNavy)),
                              if (customerPhone.isNotEmpty) ...[
                                pw.SizedBox(height: 1),
                                pw.Text('Mobile: $customerPhone', style: pw.TextStyle(fontSize: 8.5, color: textDark)),
                              ],
                            ],
                          ),
                        ),
                        // Right Column: Service Slogan
                        pw.Expanded(
                          flex: 4,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.only(left: 10),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(left: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'A GREATER LIFE FOR YOUR DEVICES',
                                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: headerNavy),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Container(width: 28, height: 1.5, color: brandBlue),
                                pw.SizedBox(height: 3),
                                pw.Text('Repairs  |  Sales  |  Accessories', style: pw.TextStyle(fontSize: 7, color: textMuted)),
                                pw.Text('All Under One Roof', style: pw.TextStyle(fontSize: 7, color: textMuted)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // 4. ITEMS TABLE (MATCHING SAMPLE IMAGE)
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Table(
                      border: const pw.TableBorder(
                        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.6),
                      ),
                      columnWidths: const {
                        0: pw.FixedColumnWidth(28),  // #
                        1: pw.FlexColumnWidth(4.5),  // Item
                        2: pw.FlexColumnWidth(2.0),  // Quantity
                        3: pw.FlexColumnWidth(2.5),  // Price/Unit
                        4: pw.FlexColumnWidth(2.8),  // Amount
                      },
                      children: [
                        // Header Row
                        pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: tableHeaderBg,
                            borderRadius: pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(5),
                              topRight: pw.Radius.circular(5),
                            ),
                          ),
                          children: [
                            _headerCell('#', align: pw.TextAlign.center),
                            _headerCell('Item'),
                            _headerCell('Quantity', align: pw.TextAlign.center),
                            _headerCell('Price / Unit', align: pw.TextAlign.right),
                            _headerCell('Amount', align: pw.TextAlign.right),
                          ],
                        ),

                        // Actual Items Rows
                        ...sale.items.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final item = entry.value;
                          final itemTitle = '${item.brand ?? ''} ${item.model ?? ''}'.trim().isNotEmpty
                              ? '${item.productName} (${item.brand ?? ''} ${item.model ?? ''})'.trim()
                              : item.productName;
                          return pw.TableRow(
                            children: [
                              _dataCell('$idx', align: pw.TextAlign.center),
                              _dataCell(itemTitle, isBold: true),
                              _dataCell('${item.quantity}', align: pw.TextAlign.center),
                              _dataCell('Rs. ${item.unitPrice.toStringAsFixed(2)}', align: pw.TextAlign.right),
                              _dataCell('Rs. ${item.total.toStringAsFixed(2)}', isBold: true, align: pw.TextAlign.right),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 12),

                  // 5. SUMMARY CARDS & GRAND TOTAL BANNER
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left Column: Payment & Warranty Status Cards (SLEEK BADGES, NO TALL CIRCLE ICONS)
                      pw.Expanded(
                        flex: 4,
                        child: pw.Column(
                          children: [
                            // Payment Status Card
                            pw.Container(
                              decoration: pw.BoxDecoration(
                                color: cardBgBlue,
                                border: pw.Border.all(color: borderBlue, width: 0.8),
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Payment Status:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textMuted)),
                                  pw.Container(
                                    decoration: pw.BoxDecoration(
                                      color: paymentStatusBg,
                                      borderRadius: pw.BorderRadius.circular(4),
                                    ),
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    child: pw.Text(
                                      paymentStatusText,
                                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: paymentStatusColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            pw.SizedBox(height: 6),

                            // Warranty Card
                            pw.Container(
                              decoration: pw.BoxDecoration(
                                color: cardBgBlue,
                                border: pw.Border.all(color: borderBlue, width: 0.8),
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Warranty:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textMuted)),
                                  pw.Container(
                                    decoration: pw.BoxDecoration(
                                      color: PdfColors.blue50,
                                      borderRadius: pw.BorderRadius.circular(4),
                                      border: pw.Border.all(color: PdfColors.blue200, width: 0.6),
                                    ),
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    child: pw.Text(
                                      sale.warranty != null ? '${sale.warranty!.durationDays} Days' : 'Standard',
                                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandBlue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(width: 12),

                      // Right Column: Subtotal, Discount & GRAND TOTAL BANNER
                      pw.Expanded(
                        flex: 6,
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            color: cardBgBlue,
                            border: pw.Border.all(color: borderBlue, width: 0.8),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 9.5, color: textDark)),
                                    pw.Text('Rs. ${sale.subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                                  ],
                                ),
                              ),
                              if (sale.totalDiscount > 0)
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  child: pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Discount:', style: pw.TextStyle(fontSize: 9.5, color: textDark)),
                                      pw.Text('- Rs. ${sale.totalDiscount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                                    ],
                                  ),
                                ),

                              // GRAND TOTAL BLUE BANNER
                              pw.Container(
                                decoration: pw.BoxDecoration(
                                  color: brandBlue,
                                  borderRadius: const pw.BorderRadius.only(
                                    bottomLeft: pw.Radius.circular(5),
                                    bottomRight: pw.Radius.circular(5),
                                  ),
                                ),
                                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                    pw.Text('Rs. ${sale.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  pw.Spacer(),

                  // 6. FOOTER SECTION
                  pw.Container(
                    padding: const pw.EdgeInsets.only(top: 8),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Left Footer Text
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Thank you for choosing $shopName', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandBlue)),
                            pw.SizedBox(height: 2),
                            pw.Text('Same Devices  |  Happier People  |  Always Here for You', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                          ],
                        ),
                        // Right Footer Text & Authorised Signature
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            if (signatureBytes != null) ...[
                              pw.Container(
                                height: 24,
                                child: pw.Image(pw.MemoryImage(signatureBytes), fit: pw.BoxFit.contain),
                              ),
                              pw.SizedBox(height: 2),
                            ],
                            pw.Text('Buy   |   Repair   |   Upgrade', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                            pw.SizedBox(height: 2),
                            pw.Text('Reliable Care for a Connected World', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                            pw.SizedBox(height: 2),
                            pw.Container(width: 50, height: 1.5, color: brandBlue),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _headerCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: brandBlue,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _dataCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textDark,
        ),
        textAlign: align,
      ),
    );
  }
}
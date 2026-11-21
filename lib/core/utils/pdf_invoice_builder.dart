import '../../features/auth/data/auth_repository.dart';
import '../../features/customer/data/customer_repository.dart';
import '../../features/repair/models/repair.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../config/env_config.dart';
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
    var path = rawPath.trim();

    // 1. Base64 Data URI check
    if (path.startsWith('data:image/') || path.contains(';base64,')) {
      try {
        final base64String = path.contains(';base64,') ? path.split(';base64,').last : path;
        return base64Decode(base64String.replaceAll('\n', '').replaceAll('\r', '').trim());
      } catch (_) {}
    }

    // 2. Local File path check (from file picker or local storage cache)
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}

    // 3. Resolve relative URL or normalize localhost / 127.0.0.1
    try {
      final baseHostUri = Uri.parse(EnvConfig.webBaseUrl);
      if (!path.startsWith('http://') && !path.startsWith('https://')) {
        // Prepend webBaseUrl
        final cleanPath = path.startsWith('/') ? path.substring(1) : path;
        if (!cleanPath.startsWith('storage/')) {
          path = '${EnvConfig.webBaseUrl}/storage/$cleanPath';
        } else {
          path = '${EnvConfig.webBaseUrl}/$cleanPath';
        }
      } else {
        // Normalize localhost/127.0.0.1 to EnvConfig host & port
        final uri = Uri.parse(path);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          path = uri.replace(
            scheme: baseHostUri.scheme,
            host: baseHostUri.host,
            port: baseHostUri.hasPort ? baseHostUri.port : null,
          ).toString();
        }
      }

      // 4. Network fetch with 5-second timeout
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse(path)).timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (previous, element) => previous..addAll(element)).timeout(const Duration(seconds: 5));
        return Uint8List.fromList(bytes);
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
      var shop = await AuthStorage().getShop();
      final hasGst = shop != null &&
          (shop['gst_number'] != null || shop['gstin'] != null || shop['gst'] != null) &&
          (shop['gst_number']?.toString().trim().isNotEmpty == true ||
              shop['gstin']?.toString().trim().isNotEmpty == true ||
              shop['gst']?.toString().trim().isNotEmpty == true);

      final hasSignature = shop != null &&
          ((shop['signature_path'] != null && shop['signature_path'].toString().trim().isNotEmpty) ||
           (shop['signature_url'] != null && shop['signature_url'].toString().trim().isNotEmpty) ||
           (shop['signature'] != null && shop['signature'].toString().trim().isNotEmpty));

      if (shop == null || !hasGst || !hasSignature) {
        try {
          final res = await AuthRepository().fetchShop();
          if (res.success && res.data != null && res.data is Map<String, dynamic>) {
            shop = res.data as Map<String, dynamic>;
          }
        } catch (_) {}
      }

      if (shop != null) {
        if (shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
          shopName = shop['name'].toString().trim();
        }

        final addressParts = [
          if (shop['address'] != null && shop['address'].toString().trim().isNotEmpty) shop['address'].toString().trim(),
          if (shop['city'] != null && shop['city'].toString().trim().isNotEmpty) shop['city'].toString().trim(),
          if (shop['state'] != null && shop['state'].toString().trim().isNotEmpty) shop['state'].toString().trim(),
          if (shop['pincode'] != null && shop['pincode'].toString().trim().isNotEmpty) shop['pincode'].toString().trim(),
        ];
        shopAddress = addressParts.join(', ');

        if (shop['phone'] != null && shop['phone'].toString().trim().isNotEmpty) {
          shopPhone = shop['phone'].toString().trim();
        } else if (shop['shop_phone'] != null && shop['shop_phone'].toString().trim().isNotEmpty) {
          shopPhone = shop['shop_phone'].toString().trim();
        } else if (shop['mobile'] != null && shop['mobile'].toString().trim().isNotEmpty) {
          shopPhone = shop['mobile'].toString().trim();
        }

        final rawGst = shop['gst_number'] ?? shop['gstin'] ?? shop['gst'] ?? shop['gst_no'];
        if (rawGst != null && rawGst.toString().trim().isNotEmpty) {
          shopGstin = rawGst.toString().trim();
        }

        final rawPan = shop['pan_number'] ?? shop['pan'] ?? shop['pan_no'];
        if (rawPan != null && rawPan.toString().trim().isNotEmpty) {
          shopPan = rawPan.toString().trim();
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

    Uint8List? customerSignatureBytes;
    try {
      final custSig = sale.customer?.signatureUrl ?? sale.customer?.signaturePath;
      if (custSig != null && custSig.isNotEmpty) {
        customerSignatureBytes = await _loadMediaBytes(custSig);
      } else if (sale.customerId != null && sale.customerId! > 0) {
        final custRes = await CustomerRepository().getCustomerDetails(sale.customerId!);
        if (custRes.success && custRes.data != null) {
          final s = custRes.data!.signatureUrl ?? custRes.data!.signaturePath;
          if (s != null && s.isNotEmpty) {
            customerSignatureBytes = await _loadMediaBytes(s);
          }
        }
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

    final itemsTaxSum = sale.items.fold<double>(0.0, (sum, i) => sum + i.taxAmount);
    final hasTax = sale.taxAmount > 0 || sale.taxRate > 0 || itemsTaxSum > 0;
    final effectiveTaxAmount = sale.taxAmount > 0 ? sale.taxAmount : itemsTaxSum;
    final effectiveTaxRate = sale.taxRate > 0
        ? sale.taxRate
        : (sale.items.any((i) => i.taxRate > 0) ? sale.items.firstWhere((i) => i.taxRate > 0).taxRate : 0.0);
    final effectiveTaxType = sale.taxRate > 0
        ? sale.taxType
        : (sale.items.any((i) => i.taxRate > 0) ? sale.items.firstWhere((i) => i.taxRate > 0).taxType : 'exclusive');
    final effectiveCgst = sale.cgstAmount > 0 ? sale.cgstAmount : (sale.isInterState ? 0.0 : effectiveTaxAmount / 2);
    final effectiveSgst = sale.sgstAmount > 0 ? sale.sgstAmount : (sale.isInterState ? 0.0 : effectiveTaxAmount / 2);
    final effectiveIgst = sale.igstAmount > 0 ? sale.igstAmount : (sale.isInterState ? effectiveTaxAmount : 0.0);
    final taxableBase = effectiveTaxType == 'inclusive'
        ? (sale.subtotal - sale.totalDiscount - effectiveTaxAmount > 0 ? sale.subtotal - sale.totalDiscount - effectiveTaxAmount : 0.0)
        : (sale.subtotal - sale.totalDiscount > 0 ? sale.subtotal - sale.totalDiscount : 0.0);

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
                      'MYREPAIRHUB',
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
                                   if (shopGstin.isNotEmpty) ...[
                                     pw.SizedBox(height: 2.5),
                                     pw.Container(
                                       padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                       decoration: pw.BoxDecoration(
                                         color: PdfColors.blue50,
                                         borderRadius: pw.BorderRadius.circular(3),
                                         border: pw.Border.all(color: PdfColors.blue200, width: 0.6),
                                       ),
                                       child: pw.Text(
                                         'GSTIN: $shopGstin',
                                         style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: brandBlue),
                                       ),
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
                              hasTax ? 'Tax Invoice' : 'Sales Invoice',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              hasTax
                                  ? 'ORIGINAL FOR RECIPIENT   |   GST TAX INVOICE'
                                  : 'SALES   |   SERVICE   |   ACCESSORIES   |   SUPPORT',
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

                          final notesList = <String>[];
                          if (item.imei1 != null && item.imei1!.isNotEmpty) {
                            notesList.add('IMEI: ${item.imei1}');
                          } else if (item.serialNumber != null && item.serialNumber!.isNotEmpty) {
                            notesList.add('S/N: ${item.serialNumber}');
                          }
                          if (item.taxRate > 0 || item.taxAmount > 0) {
                            final rateLabel = item.taxRate > 0 ? '${item.taxRate.toStringAsFixed(item.taxRate % 1 == 0 ? 0 : 1)}% ' : '';
                            final modeLabel = item.taxType == 'inclusive' ? 'Incl.' : 'Excl.';
                            notesList.add('GST $rateLabel($modeLabel: Rs. ${item.taxAmount.toStringAsFixed(2)})');
                          }
                          final subtext = notesList.isNotEmpty ? notesList.join('  |  ') : null;

                          return pw.TableRow(
                            children: [
                              _dataCell('$idx', align: pw.TextAlign.center),
                              _dataCell(itemTitle, isBold: true, subtext: subtext),
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
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Warranty:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textMuted)),
                                      pw.Container(
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.blue50,
                                          borderRadius: pw.BorderRadius.circular(4),
                                          border: pw.Border.all(color: PdfColors.blue200, width: 0.6),
                                        ),
                                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        child: pw.Text(
                                          sale.warranty != null ? '${sale.warranty!.durationDays} Days' : 'Standard',
                                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandBlue),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (sale.warranty != null) ...[
                                    pw.SizedBox(height: 3),
                                    pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text('Valid Until:', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                                        pw.Text(
                                          DateHelper.formatDate(sale.warranty!.warrantyEndDate),
                                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textDark),
                                        ),
                                      ],
                                    ),
                                    if (sale.warranty!.warrantyNumber.isNotEmpty) ...[
                                      pw.SizedBox(height: 1.5),
                                      pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Warranty #:', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                                          pw.Text(
                                            sale.warranty!.warrantyNumber,
                                            style: pw.TextStyle(fontSize: 7.5, color: brandBlue, fontWeight: pw.FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if ((sale.warranty!.warrantyTerms?.trim().isNotEmpty == true) || (sale.warranty!.notes?.trim().isNotEmpty == true)) ...[
                                      pw.SizedBox(height: 2),
                                      pw.Text(
                                        'Note: ${sale.warranty!.warrantyTerms?.trim().isNotEmpty == true ? sale.warranty!.warrantyTerms!.trim() : sale.warranty!.notes!.trim()}',
                                        style: pw.TextStyle(fontSize: 7, color: textMuted),
                                        maxLines: 2,
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            if (hasTax) ...[
                              pw.SizedBox(height: 6),
                              pw.Container(
                                decoration: pw.BoxDecoration(
                                  color: cardBgBlue,
                                  border: pw.Border.all(color: borderBlue, width: 0.8),
                                  borderRadius: pw.BorderRadius.circular(6),
                                ),
                                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('GST TAX SUMMARY', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: brandBlue)),
                                    if (shopGstin.isNotEmpty) ...[
                                      pw.SizedBox(height: 2),
                                      pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Shop GSTIN:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                                          pw.Text(shopGstin, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: brandBlue)),
                                        ],
                                      ),
                                    ],
                                    pw.SizedBox(height: 3),
                                    pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text('Tax Rate & Mode:', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                                        pw.Text('${effectiveTaxRate > 0 ? "${effectiveTaxRate.toStringAsFixed(effectiveTaxRate % 1 == 0 ? 0 : 1)}% " : ""}(${effectiveTaxType == "inclusive" ? "Incl. in Price" : "Added Extra"})', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                                      ],
                                    ),
                                    if (effectiveTaxType == 'inclusive') ...[
                                      pw.SizedBox(height: 2),
                                      pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Taxable Base Value:', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                                          pw.Text('Rs. ${taxableBase.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                                        ],
                                      ),
                                    ],
                                    pw.SizedBox(height: 2),
                                    pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text('Total Tax Amount:', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                                        pw.Text('Rs. ${effectiveTaxAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: brandBlue)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                                    pw.Text(effectiveTaxType == 'inclusive' ? 'Taxable Value (Base):' : 'Subtotal:', style: pw.TextStyle(fontSize: 9.5, color: textDark)),
                                    pw.Text('Rs. ${effectiveTaxType == 'inclusive' ? taxableBase.toStringAsFixed(2) : sale.subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark)),
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
                              if (hasTax) ...[
                                if (sale.isInterState) ...[
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                                    child: pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text('IGST (${effectiveTaxRate > 0 ? effectiveTaxRate.toStringAsFixed(effectiveTaxRate % 1 == 0 ? 0 : 1) : ""}${effectiveTaxRate > 0 ? "%" : ""}):', style: pw.TextStyle(fontSize: 9.5, color: textDark)),
                                        pw.Text('${effectiveTaxType == 'exclusive' ? "+ " : ""}Rs. ${effectiveIgst.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    child: pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text('CGST (${effectiveTaxRate > 0 ? (effectiveTaxRate / 2).toStringAsFixed((effectiveTaxRate / 2) % 1 == 0 ? 0 : 1) : ""}${effectiveTaxRate > 0 ? "%" : ""}):', style: pw.TextStyle(fontSize: 9.5, color: textDark)),
                                        pw.Text('${effectiveTaxType == 'exclusive' ? "+ " : ""}Rs. ${effectiveCgst.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                                      ],
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    child: pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text('SGST (${effectiveTaxRate > 0 ? (effectiveTaxRate / 2).toStringAsFixed((effectiveTaxRate / 2) % 1 == 0 ? 0 : 1) : ""}${effectiveTaxRate > 0 ? "%" : ""}):', style: pw.TextStyle(fontSize: 9.5, color: textDark)),
                                        pw.Text('${effectiveTaxType == 'exclusive' ? "+ " : ""}Rs. ${effectiveSgst.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                                      ],
                                    ),
                                  ),
                                ],
                                if (effectiveTaxType == 'inclusive')
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    child: pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text('Tax Mode:', style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic, color: textMuted)),
                                        pw.Text('Incl. in price (Rs. ${effectiveTaxAmount.toStringAsFixed(2)})', style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic, color: textMuted)),
                                      ],
                                    ),
                                  ),
                              ],

                              // GRAND TOTAL BLUE BANNER
                              pw.Container(
                                decoration: pw.BoxDecoration(
                                  color: brandBlue,
                                  borderRadius: pw.BorderRadius.only(
                                    bottomLeft: (sale.amountPaid > 0 || sale.amountDue > 0) ? const pw.Radius.circular(0) : const pw.Radius.circular(5),
                                    bottomRight: (sale.amountPaid > 0 || sale.amountDue > 0) ? const pw.Radius.circular(0) : const pw.Radius.circular(5),
                                  ),
                                ),
                                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                    pw.Text('Rs. ${sale.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                  ],
                                ),
                              ),
                              if (sale.amountPaid > 0 || sale.amountDue > 0) ...[
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  child: pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Paid: Rs. ${sale.amountPaid.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                                      if (sale.amountDue > 0)
                                        pw.Text('Due: Rs. ${sale.amountDue.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red700))
                                      else
                                        pw.Text('Due: Rs. 0.00', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                                    ],
                                  ),
                                ),
                              ],
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
                        // Left: Customer Signature & Thank You
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (customerSignatureBytes != null) ...[
                              pw.Container(
                                height: 32,
                                width: 95,
                                alignment: pw.Alignment.centerLeft,
                                child: pw.Image(pw.MemoryImage(customerSignatureBytes), fit: pw.BoxFit.contain),
                              ),
                              pw.SizedBox(height: 2),
                            ],
                            pw.Container(width: 95, height: 1, color: borderBlue),
                            pw.SizedBox(height: 2),
                            pw.Text('Customer Signature', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                            pw.SizedBox(height: 4),
                            pw.Text('Thank you for choosing $shopName', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandBlue)),
                          ],
                        ),
                        // Right: Authorised Shop Signature
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            if (signatureBytes != null) ...[
                              pw.Container(
                                height: 32,
                                width: 95,
                                alignment: pw.Alignment.centerRight,
                                child: pw.Image(pw.MemoryImage(signatureBytes), fit: pw.BoxFit.contain),
                              ),
                              pw.SizedBox(height: 2),
                            ],
                            pw.Container(width: 95, height: 1.5, color: brandBlue),
                            pw.SizedBox(height: 2),
                            pw.Text('Authorised Shop Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textDark)),
                            pw.Text('For $shopName', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
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

  static pw.Widget _dataCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    String? subtext,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Column(
        crossAxisAlignment: align == pw.TextAlign.right
            ? pw.CrossAxisAlignment.end
            : (align == pw.TextAlign.center ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start),
        children: [
          pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textDark,
            ),
            textAlign: align,
          ),
          if (subtext != null && subtext.isNotEmpty) ...[
            pw.SizedBox(height: 1.5),
            pw.Text(
              subtext,
              style: pw.TextStyle(fontSize: 6.5, color: textMuted),
              textAlign: align,
            ),
          ],
        ],
      ),
    );
  }

  /// Generates a modern repair job sheet / bill PDF for a Repair job.
  static Future<Uint8List> generateRepairPdf(Repair repair) async {
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
      var shop = await AuthStorage().getShop();
      final hasGst = shop != null &&
          (shop['gst_number'] != null || shop['gstin'] != null || shop['gst'] != null) &&
          (shop['gst_number']?.toString().trim().isNotEmpty == true ||
              shop['gstin']?.toString().trim().isNotEmpty == true ||
              shop['gst']?.toString().trim().isNotEmpty == true);

      final hasSignature = shop != null &&
          ((shop['signature_path'] != null && shop['signature_path'].toString().trim().isNotEmpty) ||
           (shop['signature_url'] != null && shop['signature_url'].toString().trim().isNotEmpty) ||
           (shop['signature'] != null && shop['signature'].toString().trim().isNotEmpty));

      if (shop == null || !hasGst || !hasSignature) {
        try {
          final res = await AuthRepository().fetchShop();
          if (res.success && res.data != null && res.data is Map<String, dynamic>) {
            shop = res.data as Map<String, dynamic>;
          }
        } catch (_) {}
      }

      if (shop != null) {
        if (shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
          shopName = shop['name'].toString().trim();
        }

        final addressParts = [
          if (shop['address'] != null && shop['address'].toString().trim().isNotEmpty) shop['address'].toString().trim(),
          if (shop['city'] != null && shop['city'].toString().trim().isNotEmpty) shop['city'].toString().trim(),
          if (shop['state'] != null && shop['state'].toString().trim().isNotEmpty) shop['state'].toString().trim(),
          if (shop['pincode'] != null && shop['pincode'].toString().trim().isNotEmpty) shop['pincode'].toString().trim(),
        ];
        shopAddress = addressParts.join(', ');

        if (shop['phone'] != null && shop['phone'].toString().trim().isNotEmpty) {
          shopPhone = shop['phone'].toString().trim();
        } else if (shop['shop_phone'] != null && shop['shop_phone'].toString().trim().isNotEmpty) {
          shopPhone = shop['shop_phone'].toString().trim();
        } else if (shop['mobile'] != null && shop['mobile'].toString().trim().isNotEmpty) {
          shopPhone = shop['mobile'].toString().trim();
        }

        final rawGst = shop['gst_number'] ?? shop['gstin'] ?? shop['gst'] ?? shop['gst_no'];
        if (rawGst != null && rawGst.toString().trim().isNotEmpty) {
          shopGstin = rawGst.toString().trim();
        }

        final rawPan = shop['pan_number'] ?? shop['pan'] ?? shop['pan_no'];
        if (rawPan != null && rawPan.toString().trim().isNotEmpty) {
          shopPan = rawPan.toString().trim();
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

    Uint8List? customerSignatureBytes;
    try {
      final custSig = repair.customer?.signatureUrl ?? repair.customer?.signaturePath;
      if (custSig != null && custSig.isNotEmpty) {
        customerSignatureBytes = await _loadMediaBytes(custSig);
      } else if (repair.customerId > 0) {
        final custRes = await CustomerRepository().getCustomerDetails(repair.customerId);
        if (custRes.success && custRes.data != null) {
          final s = custRes.data!.signatureUrl ?? custRes.data!.signaturePath;
          if (s != null && s.isNotEmpty) {
            customerSignatureBytes = await _loadMediaBytes(s);
          }
        }
      }
    } catch (_) {}

    if (termsList.isEmpty) {
      termsList = [
        '1. Please inspect device thoroughly before leaving premises.',
        '2. Shop is not responsible for data loss. Backup is recommended.',
        '3. Unclaimed devices after 30 days may be subject to storage fees.',
      ];
    }

    final customerName = repair.customer?.name.trim().isNotEmpty == true
        ? repair.customer!.name.trim()
        : 'Customer';

    final customerPhone = repair.customer?.mobile.trim().isNotEmpty == true
        ? repair.customer!.mobile.trim()
        : '';

    final jobNum = repair.jobNumber.isNotEmpty ? repair.jobNumber : 'RH-REP-${repair.id}';
    final rawDate = repair.dateReceived.isNotEmpty ? repair.dateReceived : DateTime.now().toIso8601String();
    final dateStr = DateHelper.formatDate(rawDate);
    final expectedDelivery = repair.expectedDeliveryDate != null && repair.expectedDeliveryDate!.isNotEmpty
        ? DateHelper.formatDate(repair.expectedDeliveryDate!)
        : 'N/A';

    final contactParts = <String>[];
    if (shopPhone.isNotEmpty) contactParts.add('Phone: $shopPhone');
    if (shopGstin.isNotEmpty) contactParts.add('GSTIN: $shopGstin');
    if (shopPan.isNotEmpty) contactParts.add('PAN: $shopPan');
    final contactLine = contactParts.join('  |  ');

    final isPaidFull = repair.amountDue <= 0;
    final paymentStatusText = isPaidFull ? 'PAID' : (repair.amountPaid > 0 ? 'PARTIAL' : 'DUE');
    final paymentStatusColor = isPaidFull ? PdfColors.green700 : (repair.amountPaid > 0 ? PdfColors.orange700 : PdfColors.red700);
    final paymentStatusBg = isPaidFull ? PdfColor.fromHex('#DCFCE7') : (repair.amountPaid > 0 ? PdfColor.fromHex('#FFEDD5') : PdfColor.fromHex('#FEE2E2'));

    final deviceBrandModel = '${repair.device?.brand ?? ''} ${repair.device?.model ?? ''}'.trim();
    final serialImei = repair.device?.serialNumber ?? (repair.device?.imei1 ?? (repair.device?.imei2 ?? 'N/A'));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(26),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // BACKGROUND WATERMARK
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: -0.38,
                    child: pw.Text(
                      'MYREPAIRHUB',
                      style: pw.TextStyle(
                        fontSize: 64,
                        fontWeight: pw.FontWeight.bold,
                        color: watermarkColor,
                      ),
                    ),
                  ),
                ),
              ),

              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 1. TOP HEADER SECTION
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              shopName,
                              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: headerNavy),
                            ),
                            if (shopAddress.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(shopAddress, style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                            ],
                            if (contactLine.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(contactLine, style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                            ],
                          ],
                        ),
                      ),
                      if (logoBytes != null) ...[
                        pw.SizedBox(width: 12),
                        pw.Container(
                          height: 42,
                          width: 80,
                          child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                        ),
                      ],
                    ],
                  ),

                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.grey300, thickness: 0.8),
                  pw.SizedBox(height: 8),

                  // 2. REPAIR TICKET TITLE & BADGES
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'REPAIR JOB TICKET',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: brandBlue),
                          ),
                          pw.Text(
                            'Job No: #$jobNum',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Container(
                            decoration: pw.BoxDecoration(
                              color: cardBgBlue,
                              borderRadius: pw.BorderRadius.circular(4),
                              border: pw.Border.all(color: borderBlue, width: 0.6),
                            ),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: pw.Text(
                              'Status: ${repair.repairStatus.toUpperCase()}',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandBlue),
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Container(
                            decoration: pw.BoxDecoration(
                              color: paymentStatusBg,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: pw.Text(
                              paymentStatusText,
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: paymentStatusColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 10),

                  // 3. CUSTOMER & DEVICE INFO BOXES
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Customer Box
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: cardBgBlue,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: borderBlue, width: 0.6),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandBlue)),
                              pw.SizedBox(height: 4),
                              pw.Text('Name: $customerName', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
                              if (customerPhone.isNotEmpty)
                                pw.Text('Phone: $customerPhone', style: pw.TextStyle(fontSize: 8.5, color: textDark)),
                              pw.Text('Date Received: $dateStr', style: pw.TextStyle(fontSize: 8.5, color: textDark)),
                              pw.Text('Target Delivery: $expectedDelivery', style: pw.TextStyle(fontSize: 8.5, color: textDark)),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      // Device Box
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: cardBgBlue,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: borderBlue, width: 0.6),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('DEVICE & REPAIR DETAILS', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandBlue)),
                              pw.SizedBox(height: 4),
                              pw.Text('Device: ${deviceBrandModel.isNotEmpty ? deviceBrandModel : "Mobile Device"}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
                              pw.Text('IMEI / Serial: $serialImei', style: pw.TextStyle(fontSize: 8.5, color: textDark)),
                              pw.Text('Problem: ${repair.problemDescription.isNotEmpty ? repair.problemDescription : "Repair Service"}', style: pw.TextStyle(fontSize: 8.5, color: textDark)),
                              if (repair.deviceCondition.isNotEmpty)
                                pw.Text('Condition: ${repair.deviceCondition.join(", ")}', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                              if (repair.accessoriesReceived.isNotEmpty)
                                pw.Text('Accessories: ${repair.accessoriesReceived.join(", ")}', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                              if (repair.customerNotes != null && repair.customerNotes!.trim().isNotEmpty)
                                pw.Text('Customer Note: ${repair.customerNotes!.trim()}', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 12),

                  // 4. REPAIR SERVICE & CHARGES TABLE (CLEAN SINGLE FULL PRICE, NO PART PRICE / NO TECH BREAKDOWN)
                  pw.Table(
                    border: pw.TableBorder.all(color: borderBlue, width: 0.6),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(28),
                      1: pw.FlexColumnWidth(4),
                      2: pw.FixedColumnWidth(40),
                      3: pw.FixedColumnWidth(65),
                      4: pw.FixedColumnWidth(75),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: tableHeaderBg),
                        children: [
                          _headerCell('#', align: pw.TextAlign.center),
                          _headerCell('Item / Service Description'),
                          _headerCell('Qty', align: pw.TextAlign.center),
                          _headerCell('Rate (Rs.)', align: pw.TextAlign.right),
                          _headerCell('Total (Rs.)', align: pw.TextAlign.right),
                        ],
                      ),

                      // Clean Full Price Repair Service Row
                      pw.TableRow(
                        children: [
                          _dataCell('1', align: pw.TextAlign.center),
                          _dataCell(
                            'Mobile Device Repair Service (${deviceBrandModel.isNotEmpty ? deviceBrandModel : "Device"})',
                            isBold: true,
                            subtext: repair.problemDescription.isNotEmpty ? 'Problem: ${repair.problemDescription}' : null,
                          ),
                          _dataCell('1', align: pw.TextAlign.center),
                          _dataCell(repair.netCost.toStringAsFixed(2), align: pw.TextAlign.right),
                          _dataCell(repair.netCost.toStringAsFixed(2), isBold: true, align: pw.TextAlign.right),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 12),

                  // 5. SUMMARY & TOTALS
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left Column: Payment & Warranty Status Cards + Terms
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Payment Status Card
                            pw.Container(
                              decoration: pw.BoxDecoration(
                                color: cardBgBlue,
                                border: pw.Border.all(color: borderBlue, width: 0.8),
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Payment Status:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textMuted)),
                                  pw.Container(
                                    decoration: pw.BoxDecoration(
                                      color: paymentStatusBg,
                                      borderRadius: pw.BorderRadius.circular(4),
                                    ),
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    child: pw.Text(
                                      paymentStatusText,
                                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: paymentStatusColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 5),

                            // Warranty Card
                            pw.Container(
                              decoration: pw.BoxDecoration(
                                color: cardBgBlue,
                                border: pw.Border.all(color: borderBlue, width: 0.8),
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Repair Warranty:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textMuted)),
                                      pw.Container(
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.blue50,
                                          borderRadius: pw.BorderRadius.circular(4),
                                          border: pw.Border.all(color: PdfColors.blue200, width: 0.6),
                                        ),
                                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        child: pw.Text(
                                          repair.warranty != null ? '${repair.warranty!.durationDays} Days' : 'Testing Warranty',
                                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandBlue),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (repair.warranty != null) ...[
                                    pw.SizedBox(height: 3),
                                    pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text('Valid Until:', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                                        pw.Text(
                                          DateHelper.formatDate(repair.warranty!.warrantyEndDate),
                                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textDark),
                                        ),
                                      ],
                                    ),
                                    if (repair.warranty!.warrantyNumber.isNotEmpty) ...[
                                      pw.SizedBox(height: 1.5),
                                      pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Warranty #:', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                                          pw.Text(
                                            repair.warranty!.warrantyNumber,
                                            style: pw.TextStyle(fontSize: 7.5, color: brandBlue, fontWeight: pw.FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if ((repair.warranty!.warrantyTerms?.trim().isNotEmpty == true) || (repair.warranty!.notes?.trim().isNotEmpty == true)) ...[
                                      pw.SizedBox(height: 2),
                                      pw.Text(
                                        'Note: ${repair.warranty!.warrantyTerms?.trim().isNotEmpty == true ? repair.warranty!.warrantyTerms!.trim() : repair.warranty!.notes!.trim()}',
                                        style: pw.TextStyle(fontSize: 7, color: textMuted),
                                        maxLines: 2,
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 6),

                            pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: headerNavy)),
                            pw.SizedBox(height: 2),
                            ...termsList.map(
                              (term) => pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 1.5),
                                child: pw.Text(term, style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      // Right Column: Summary Card
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
                                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Total Repair Cost:', style: pw.TextStyle(fontSize: 9.5, color: textDark)),
                                    pw.Text('Rs. ${repair.netCost.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                                  ],
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Advance Paid:', style: pw.TextStyle(fontSize: 9.5, color: textDark)),
                                    pw.Text('Rs. ${repair.amountPaid.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                                  ],
                                ),
                              ),
                              if (repair.amountDue > 0)
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  child: pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Balance Due:', style: pw.TextStyle(fontSize: 9.5, color: textDark)),
                                      pw.Text('Rs. ${repair.amountDue.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                                    ],
                                  ),
                                ),

                              // GRAND TOTAL BANNER
                              pw.Container(
                                decoration: pw.BoxDecoration(
                                  color: brandBlue,
                                  borderRadius: const pw.BorderRadius.only(
                                    bottomLeft: pw.Radius.circular(5),
                                    bottomRight: pw.Radius.circular(5),
                                  ),
                                ),
                                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Net Payable:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                    pw.Text('Rs. ${repair.netCost.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
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
                        // Left: Customer Signature & Thank You
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (customerSignatureBytes != null) ...[
                              pw.Container(
                                height: 32,
                                width: 95,
                                alignment: pw.Alignment.centerLeft,
                                child: pw.Image(pw.MemoryImage(customerSignatureBytes), fit: pw.BoxFit.contain),
                              ),
                              pw.SizedBox(height: 2),
                            ],
                            pw.Container(width: 95, height: 1, color: borderBlue),
                            pw.SizedBox(height: 2),
                            pw.Text('Customer Signature', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                            pw.SizedBox(height: 4),
                            pw.Text('Thank you for choosing $shopName', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandBlue)),
                          ],
                        ),
                        // Right: Authorised Shop Signature
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            if (signatureBytes != null) ...[
                              pw.Container(
                                height: 32,
                                width: 95,
                                alignment: pw.Alignment.centerRight,
                                child: pw.Image(pw.MemoryImage(signatureBytes), fit: pw.BoxFit.contain),
                              ),
                              pw.SizedBox(height: 2),
                            ],
                            pw.Container(width: 95, height: 1.5, color: brandBlue),
                            pw.SizedBox(height: 2),
                            pw.Text('Authorised Shop Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textDark)),
                            pw.Text('For $shopName', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
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

}

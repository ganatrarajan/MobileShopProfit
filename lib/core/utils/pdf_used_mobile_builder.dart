import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../storage/auth_storage.dart';
import '../../features/used_mobile/models/used_mobile.dart';
import 'date_helper.dart';

class PdfUsedMobileBuilder {
  static final PdfColor brandPurple = PdfColor.fromHex('#6D28D9');
  static final PdfColor headerNavy = PdfColor.fromHex('#0F172A');
  static final PdfColor cardBg = PdfColor.fromHex('#F8FAFC');
  static final PdfColor borderSlate = PdfColor.fromHex('#E2E8F0');
  static final PdfColor tableHeaderBg = PdfColor.fromHex('#F1F5F9');
  static final PdfColor textDark = PdfColor.fromHex('#1E293B');
  static final PdfColor textMuted = PdfColor.fromHex('#64748B');
  static final PdfColor successGreen = PdfColor.fromHex('#10B981');
  static final PdfColor warningAmber = PdfColor.fromHex('#D97706');

  static Future<Uint8List?> _loadMediaBytes(String? rawPath) async {
    if (rawPath == null || rawPath.trim().isEmpty) return null;
    final path = rawPath.trim();
    try {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final request = await HttpClient().getUrl(Uri.parse(path));
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
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

  static Future<Map<String, dynamic>> _fetchShopInfo() async {
    String shopName = 'Mobile Care & Sales Hub';
    String shopAddress = '';
    String shopPhone = '';
    String shopGstin = '';
    String shopPan = '';
    Uint8List? logoBytes;
    Uint8List? signatureBytes;

    try {
      final shop = await AuthStorage().getShop();
      if (shop != null) {
        if (shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
          shopName = shop['name'].toString().trim();
        }
        final parts = [
          if (shop['address'] != null && shop['address'].toString().trim().isNotEmpty) shop['address'].toString().trim(),
          if (shop['city'] != null && shop['city'].toString().trim().isNotEmpty) shop['city'].toString().trim(),
          if (shop['state'] != null && shop['state'].toString().trim().isNotEmpty) shop['state'].toString().trim(),
          if (shop['pincode'] != null && shop['pincode'].toString().trim().isNotEmpty) shop['pincode'].toString().trim(),
        ];
        shopAddress = parts.join(', ');

        if (shop['mobile'] != null && shop['mobile'].toString().trim().isNotEmpty) {
          shopPhone = shop['mobile'].toString().trim();
        } else if (shop['phone'] != null && shop['phone'].toString().trim().isNotEmpty) {
          shopPhone = shop['phone'].toString().trim();
        }

        if (shop['gstin'] != null) shopGstin = shop['gstin'].toString().trim();
        if (shop['pan_number'] != null) shopPan = shop['pan_number'].toString().trim();

        final logoPath = shop['logo_path'] ?? shop['logo_url'] ?? shop['logo'];
        logoBytes = await _loadMediaBytes(logoPath?.toString());
        final sigPath = shop['signature_path'] ?? shop['signature_url'] ?? shop['signature'];
        signatureBytes = await _loadMediaBytes(sigPath?.toString());
      }
    } catch (_) {}

    return {
      'name': shopName,
      'address': shopAddress,
      'phone': shopPhone,
      'gstin': shopGstin,
      'pan': shopPan,
      'logo': logoBytes,
      'signature': signatureBytes,
    };
  }

  /// 1. OLD MOBILE PURCHASE AGREEMENT & SELLER UNDERTAKING VOUCHER
  static Future<Uint8List> generatePurchaseAgreementPdf(UsedMobile mobile) async {
    final pdf = pw.Document();
    final shop = await _fetchShopInfo();

    final Uint8List? logoBytes = shop['logo'];
    final Uint8List? sigBytes = shop['signature'];

    final refNum = mobile.purchaseRefNumber.isNotEmpty ? mobile.purchaseRefNumber : 'UMP-${mobile.id}';
    final dateStr = DateHelper.formatDate(mobile.purchaseDate.toIso8601String());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shop['name'],
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: brandPurple,
                          ),
                        ),
                        if (shop['address'].toString().isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              shop['address'],
                              style: pw.TextStyle(fontSize: 9, color: textMuted),
                            ),
                          ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(
                            'Phone: ${shop['phone']}${shop['gstin'].toString().isNotEmpty ? ' | GST: ${shop['gstin']}' : ''}',
                            style: pw.TextStyle(fontSize: 9, color: textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (logoBytes != null)
                    pw.Container(
                      width: 55,
                      height: 55,
                      margin: const pw.EdgeInsets.only(left: 10),
                      child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                    ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                decoration: pw.BoxDecoration(
                  color: brandPurple,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'SECOND-HAND MOBILE PURCHASE VOUCHER & UNDERTAKING',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                    pw.Text(
                      'REF: $refNum',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Seller Details Box (Police anti-theft compliance)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderSlate),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SELLER IDENTITY & VERIFICATION (ORIGINAL OWNER)',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: headerNavy),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Full Name: ${mobile.sellerName}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 2),
                              pw.Text('Mobile: ${mobile.sellerPhone}', style: const pw.TextStyle(fontSize: 9)),
                              if (mobile.sellerAddress != null && mobile.sellerAddress!.trim().isNotEmpty)
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(top: 2),
                                  child: pw.Text('Address: ${mobile.sellerAddress}', style: const pw.TextStyle(fontSize: 9)),
                                ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Govt ID Proof: ${mobile.idProofType ?? 'Aadhaar Card'}',
                                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'ID Number: ${mobile.idProofNumber?.isNotEmpty == true ? mobile.idProofNumber : 'VERIFIED IN PERSON'}',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text('Purchase Date: $dateStr', style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Device Details Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderSlate),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PURCHASED DEVICE SPECIFICATIONS & IMEI VERIFICATION',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: headerNavy),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Table(
                      border: pw.TableBorder.all(color: borderSlate, width: 0.5),
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: tableHeaderBg),
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Item Description', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Primary IMEI 1', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Condition', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Amount Paid', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('${mobile.brand} ${mobile.model}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                  if (mobile.ram != null || mobile.storage != null || mobile.color != null)
                                    pw.Text(
                                      'Specs: ${[mobile.ram, mobile.storage, mobile.color].where((s) => s != null && s.trim().isNotEmpty).join(' / ')}',
                                      style: pw.TextStyle(fontSize: 8, color: textMuted),
                                    ),
                                  if (mobile.imei2 != null && mobile.imei2!.trim().isNotEmpty)
                                    pw.Text('IMEI 2: ${mobile.imei2}', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                                  if (mobile.accessoriesIncluded.isNotEmpty)
                                    pw.Text(
                                      'Accessories: ${mobile.accessoriesIncluded.join(', ')}',
                                      style: pw.TextStyle(fontSize: 8, color: textMuted),
                                    ),
                                ],
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                mobile.imei1,
                                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: headerNavy),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(mobile.conditionLabel, style: const pw.TextStyle(fontSize: 8.5)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Rs. ${mobile.purchasePrice.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: brandPurple),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Payment confirmation
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: borderSlate),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Payment Mode: ${mobile.paymentMode}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Total Paid in Full: Rs. ${mobile.purchasePrice.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: successGreen)),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Seller Legal Ownership Undertaking (Crucial anti-theft clause for Indian shops)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFFBEB'),
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColor.fromHex('#FDE68A')),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LEGAL UNDERTAKING & NO OBJECTION DECLARATION BY SELLER:',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: warningAmber),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'I, the seller named above, hereby unconditionally certify and declare that I am the sole, absolute, and legitimate owner of the mobile device described above. I confirm that this phone is not stolen, looted, reported lost, blacklisted, or under any police investigation, EMI default, or bank finance lien. I have received the full agreed amount from the shop owner. If any complaint or legal dispute arises regarding ownership of this device in the future, I shall be solely and personally responsible for all consequences and legal liabilities.',
                      style: pw.TextStyle(fontSize: 7.2, color: textDark, height: 1.25),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: borderSlate),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Seller Signature / Thumb',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark),
                      ),
                      pw.Text('(${mobile.sellerName})', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (sigBytes != null)
                        pw.Container(
                          width: 80,
                          height: 35,
                          child: pw.Image(pw.MemoryImage(sigBytes), fit: pw.BoxFit.contain),
                        ),
                      pw.Container(width: 140, height: 1, color: borderSlate),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorized Shop Sign & Stamp',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark),
                      ),
                      pw.Text('For ${shop['name']}', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Generated automatically via Mobile Repair Platform | System Verified',
                  style: pw.TextStyle(fontSize: 7, color: textMuted),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// 2. USED MOBILE SALE INVOICE & TESTING WARRANTY CERTIFICATE
  static Future<Uint8List> generateSaleInvoicePdf(UsedMobile mobile) async {
    final pdf = pw.Document();
    final shop = await _fetchShopInfo();

    final Uint8List? logoBytes = shop['logo'];
    final Uint8List? sigBytes = shop['signature'];

    final invNum = mobile.saleInvoiceNumber?.isNotEmpty == true ? mobile.saleInvoiceNumber! : 'UMS-${mobile.id}';
    final dateStr = DateHelper.formatDate((mobile.saleDate ?? DateTime.now()).toIso8601String());
    final warrantyDays = mobile.warrantyDays ?? 0;

    DateTime? warrantyExpiry;
    if (warrantyDays > 0 && mobile.saleDate != null) {
      warrantyExpiry = mobile.saleDate!.add(Duration(days: warrantyDays));
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shop['name'],
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: brandPurple,
                          ),
                        ),
                        if (shop['address'].toString().isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              shop['address'],
                              style: pw.TextStyle(fontSize: 9, color: textMuted),
                            ),
                          ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(
                            'Phone: ${shop['phone']}${shop['gstin'].toString().isNotEmpty ? ' | GST: ${shop['gstin']}' : ''}',
                            style: pw.TextStyle(fontSize: 9, color: textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (logoBytes != null)
                    pw.Container(
                      width: 55,
                      height: 55,
                      margin: const pw.EdgeInsets.only(left: 10),
                      child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                    ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                decoration: pw.BoxDecoration(
                  color: brandPurple,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PRE-OWNED MOBILE SALE INVOICE & WARRANTY CERTIFICATE',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                    pw.Text(
                      'INVOICE: $invNum',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Buyer Details
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderSlate),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILLED TO (BUYER):', style: pw.TextStyle(fontSize: 8.5, color: textMuted, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(mobile.buyerName ?? 'Customer', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: headerNavy)),
                        if (mobile.buyerPhone?.isNotEmpty == true)
                          pw.Text('Phone: ${mobile.buyerPhone}', style: const pw.TextStyle(fontSize: 9)),
                        if (mobile.buyerAddress?.isNotEmpty == true)
                          pw.Text('Address: ${mobile.buyerAddress}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Invoice Date: $dateStr', style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 2),
                        pw.Text('Payment Mode: ${mobile.salePaymentMode ?? 'Cash'}', style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Device Status: Certified Tested',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: successGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Sold Device Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderSlate),
                ),
                child: pw.Table(
                  border: pw.TableBorder.all(color: borderSlate, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: tableHeaderBg),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Item & Specifications', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('IMEI 1 & 2', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Testing Warranty', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Amount (Rs.)', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('${mobile.brand} ${mobile.model}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                              if (mobile.ram != null || mobile.storage != null || mobile.color != null)
                                pw.Text(
                                  'Specs: ${[mobile.ram, mobile.storage, mobile.color].where((s) => s != null && s.trim().isNotEmpty).join(' / ')}',
                                  style: pw.TextStyle(fontSize: 8, color: textMuted),
                                ),
                              if (mobile.accessoriesIncluded.isNotEmpty)
                                pw.Text(
                                  'Accessories Handed: ${mobile.accessoriesIncluded.join(', ')}',
                                  style: pw.TextStyle(fontSize: 8, color: textMuted),
                                ),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(mobile.imei1, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              if (mobile.imei2 != null && mobile.imei2!.trim().isNotEmpty)
                                pw.Text('2: ${mobile.imei2}', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                warrantyDays > 0 ? '$warrantyDays Days Testing Warranty' : 'No Warranty',
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: warrantyDays > 0 ? successGreen : textMuted,
                                ),
                              ),
                              if (warrantyExpiry != null)
                                pw.Text(
                                  'Valid till: ${DateHelper.formatDate(warrantyExpiry.toIso8601String())}',
                                  style: pw.TextStyle(fontSize: 7.5, color: textMuted),
                                ),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Rs. ${(mobile.sellingPrice ?? 0.0).toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandPurple),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Total Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: cardBg,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: borderSlate),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Net Total Paid:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark)),
                        pw.Text(
                          'Rs. ${(mobile.sellingPrice ?? 0.0).toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandPurple),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // Testing Warranty Terms
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: borderSlate),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TESTING WARRANTY TERMS & CONDITIONS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: headerNavy)),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '1. Testing warranty covers internal functional hardware defects (motherboard/network/mic/speaker).\n'
                      '2. Warranty is STRICTLY VOID if the device suffers physical drop damage, cracked glass/display, water/liquid ingress, or has been opened by any unauthorized technician.\n'
                      '3. Warranty slip or digital invoice is mandatory for any claim.\n'
                      '4. Pre-owned phones are sold in inspected working condition; no cash refunds provided.',
                      style: pw.TextStyle(fontSize: 7.2, color: textDark, height: 1.3),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: borderSlate),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Buyer Signature',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark),
                      ),
                      pw.Text('Accepted in Good Working Condition', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (sigBytes != null)
                        pw.Container(
                          width: 80,
                          height: 35,
                          child: pw.Image(pw.MemoryImage(sigBytes), fit: pw.BoxFit.contain),
                        ),
                      pw.Container(width: 140, height: 1, color: borderSlate),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorized Shop Sign & Stamp',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark),
                      ),
                      pw.Text('For ${shop['name']}', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Thank you for your purchase! | Mobile Repair & Retail Suite',
                  style: pw.TextStyle(fontSize: 7, color: textMuted),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// 3. USED MOBILE PURCHASES SUMMARY REPORT (Multi-Page PDF)
  static Future<Uint8List> generatePurchasesSummaryPdfReport(
    List<UsedMobile> mobiles, {
    String? reportTitle,
  }) async {
    final pdf = pw.Document();
    final shop = await _fetchShopInfo();
    final Uint8List? logoBytes = shop['logo'];

    double totalCost = 0.0;
    int inStockCount = 0;
    for (final m in mobiles) {
      totalCost += m.purchasePrice;
      if (m.isInStock) inStockCount++;
    }

    final nowStr = DateHelper.formatDate(DateTime.now().toIso8601String());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Column(
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
                          shop['name'],
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: brandPurple,
                          ),
                        ),
                        if (shop['address'].toString().isNotEmpty)
                          pw.Text(shop['address'], style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                        if (shop['phone'].toString().isNotEmpty)
                          pw.Text('Phone: ${shop['phone']}', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                      ],
                    ),
                  ),
                  if (logoBytes != null)
                    pw.Container(
                      width: 50,
                      height: 35,
                      child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                    ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F5F3FF'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#DDD6FE')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      reportTitle ?? 'USED MOBILE PURCHASES INVENTORY REPORT',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: brandPurple),
                    ),
                    pw.Text(
                      'Generated: $nowStr',
                      style: pw.TextStyle(fontSize: 9, color: textMuted),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Used Mobile Inventory & Accounting Suite', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Row
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                color: cardBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderSlate),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Total Phones', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                      pw.SizedBox(height: 2),
                      pw.Text('${mobiles.length} Units', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: textDark)),
                    ],
                  ),
                  pw.Container(width: 1, height: 24, color: borderSlate),
                  pw.Column(
                    children: [
                      pw.Text('In Stock', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                      pw.SizedBox(height: 2),
                      pw.Text('$inStockCount Units', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: brandPurple)),
                    ],
                  ),
                  pw.Container(width: 1, height: 24, color: borderSlate),
                  pw.Column(
                    children: [
                      pw.Text('Total Purchase Amount', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                      pw.SizedBox(height: 2),
                      pw.Text('INR ${totalCost.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: headerNavy)),
                    ],
                  ),
                ],
              ),
            ),

            // Itemized Table
            pw.Table(
              border: pw.TableBorder.all(color: borderSlate, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(24), // #
                1: const pw.FixedColumnWidth(70), // Ref #
                2: const pw.FixedColumnWidth(55), // Date
                3: const pw.FlexColumnWidth(2.5), // Device & Specs
                4: const pw.FlexColumnWidth(2.2), // IMEI 1
                5: const pw.FlexColumnWidth(2.2), // Seller
                6: const pw.FixedColumnWidth(65), // Cost
                7: const pw.FixedColumnWidth(45), // Status
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: tableHeaderBg),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('#', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Ref #', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Date', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Device & Specs', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('IMEI 1', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Seller / Phone', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Cost (INR)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: headerNavy), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Status', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: headerNavy), textAlign: pw.TextAlign.center)),
                  ],
                ),
                // Data rows
                ...mobiles.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final m = entry.value;
                  final isEven = idx % 2 == 0;
                  final specs = [if (m.ram != null) m.ram, if (m.storage != null) m.storage].join('/');

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColor.fromHex('#FAFAFA') : PdfColors.white),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text('$idx', style: const pw.TextStyle(fontSize: 7.5))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text(m.purchaseRefNumber, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text(DateHelper.formatDate(m.purchaseDate.toIso8601String()), style: const pw.TextStyle(fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text('${m.brand} ${m.model} ${specs.isNotEmpty ? "($specs)" : ""}', style: const pw.TextStyle(fontSize: 7.5))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text(m.imei1, style: const pw.TextStyle(fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text('${m.sellerName}\n${m.sellerPhone}', style: const pw.TextStyle(fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text(m.purchasePrice.toStringAsFixed(2), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4.5),
                        child: pw.Text(
                          m.isInStock ? 'IN STOCK' : 'SOLD',
                          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: m.isInStock ? brandPurple : successGreen),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
                // Total Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: tableHeaderBg),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${mobiles.length} Units', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('INR ${totalCost.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: headerNavy), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// 4. USED MOBILE SALES & NET PROFIT SUMMARY REPORT (Multi-Page PDF)
  static Future<Uint8List> generateSalesSummaryPdfReport(
    List<UsedMobile> mobiles, {
    String? reportTitle,
  }) async {
    final pdf = pw.Document();
    final shop = await _fetchShopInfo();
    final Uint8List? logoBytes = shop['logo'];

    final soldList = mobiles.where((m) => m.isSold || m.saleDate != null).toList();

    double totalCostSum = 0.0;
    double totalRevenueSum = 0.0;
    double totalProfitSum = 0.0;

    for (final m in soldList) {
      totalCostSum += m.totalCost;
      final salePrice = m.sellingPrice ?? 0.0;
      totalRevenueSum += salePrice;
      totalProfitSum += (m.profit ?? (salePrice - m.totalCost));
    }

    final double roiPercent = totalCostSum > 0 ? (totalProfitSum / totalCostSum * 100) : 0.0;
    final nowStr = DateHelper.formatDate(DateTime.now().toIso8601String());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Column(
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
                          shop['name'],
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: brandPurple,
                          ),
                        ),
                        if (shop['address'].toString().isNotEmpty)
                          pw.Text(shop['address'], style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                        if (shop['phone'].toString().isNotEmpty)
                          pw.Text('Phone: ${shop['phone']}', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                      ],
                    ),
                  ),
                  if (logoBytes != null)
                    pw.Container(
                      width: 50,
                      height: 35,
                      child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                    ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#ECFDF5'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#A7F3D0')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      reportTitle ?? 'USED MOBILE SALES & NET PROFIT REPORT',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: successGreen),
                    ),
                    pw.Text(
                      'Generated: $nowStr',
                      style: pw.TextStyle(fontSize: 9, color: textMuted),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Used Mobile Sales & Profit Ledger | Mobile Suite', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Row
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                color: cardBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderSlate),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Sold Units', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                      pw.SizedBox(height: 2),
                      pw.Text('${soldList.length} Mobiles', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: textDark)),
                    ],
                  ),
                  pw.Container(width: 1, height: 24, color: borderSlate),
                  pw.Column(
                    children: [
                      pw.Text('Total Sale Revenue', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                      pw.SizedBox(height: 2),
                      pw.Text('INR ${totalRevenueSum.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: headerNavy)),
                    ],
                  ),
                  pw.Container(width: 1, height: 24, color: borderSlate),
                  pw.Column(
                    children: [
                      pw.Text('Total Cost', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                      pw.SizedBox(height: 2),
                      pw.Text('INR ${totalCostSum.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: textMuted)),
                    ],
                  ),
                  pw.Container(width: 1, height: 24, color: borderSlate),
                  pw.Column(
                    children: [
                      pw.Text('Net Profit Earned', style: pw.TextStyle(fontSize: 9, color: successGreen)),
                      pw.SizedBox(height: 2),
                      pw.Text('INR ${totalProfitSum.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: successGreen)),
                      pw.Text('+${roiPercent.toStringAsFixed(1)}% ROI', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: successGreen)),
                    ],
                  ),
                ],
              ),
            ),

            // Itemized Table
            pw.Table(
              border: pw.TableBorder.all(color: borderSlate, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(22), // #
                1: const pw.FixedColumnWidth(65), // Invoice #
                2: const pw.FixedColumnWidth(55), // Date
                3: const pw.FlexColumnWidth(2.3), // Device
                4: const pw.FlexColumnWidth(2.2), // Buyer
                5: const pw.FixedColumnWidth(55), // Total Cost
                6: const pw.FixedColumnWidth(55), // Sale Price
                7: const pw.FixedColumnWidth(55), // Net Profit
                8: const pw.FixedColumnWidth(40), // ROI %
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: tableHeaderBg),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('#', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Invoice #', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Sale Date', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Device', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Buyer / Phone', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Cost (INR)', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: headerNavy), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Sale (INR)', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: headerNavy), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Profit (INR)', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: successGreen), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ROI', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: headerNavy), textAlign: pw.TextAlign.center)),
                  ],
                ),
                // Data rows
                ...soldList.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final m = entry.value;
                  final isEven = idx % 2 == 0;
                  final profit = m.profit ?? ((m.sellingPrice ?? 0.0) - m.totalCost);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColor.fromHex('#FAFAFA') : PdfColors.white),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('$idx', style: const pw.TextStyle(fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(m.saleInvoiceNumber ?? 'UMS-${m.id}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(m.saleDate != null ? DateHelper.formatDate(m.saleDate!.toIso8601String()) : '', style: const pw.TextStyle(fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${m.brand} ${m.model}', style: const pw.TextStyle(fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${m.buyerName ?? "Customer"}\n${m.buyerPhone ?? ""}', style: const pw.TextStyle(fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(m.totalCost.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((m.sellingPrice ?? 0.0).toStringAsFixed(0), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          profit >= 0 ? '+${profit.toStringAsFixed(0)}' : profit.toStringAsFixed(0),
                          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: profit >= 0 ? successGreen : PdfColors.red),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          '${m.profitPercentage.toStringAsFixed(0)}%',
                          style: pw.TextStyle(fontSize: 7, color: profit >= 0 ? successGreen : PdfColors.red),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
                // Total Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: tableHeaderBg),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text('', style: const pw.TextStyle(fontSize: 7.5))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: headerNavy))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text('${soldList.length} Sold', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text('', style: const pw.TextStyle(fontSize: 7.5))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text('', style: const pw.TextStyle(fontSize: 7.5))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text(totalCostSum.toStringAsFixed(0), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text(totalRevenueSum.toStringAsFixed(0), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text(totalProfitSum.toStringAsFixed(0), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: successGreen), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4.5), child: pw.Text('+${roiPercent.toStringAsFixed(0)}%', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: successGreen), textAlign: pw.TextAlign.center)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}


import 'dart:io';

void main() {
  final file = File('lib/core/utils/whatsapp_helper.dart');
  final lines = file.readAsLinesSync();

  final newLines = <String>[];
  bool inMethod = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.contains('static Future<bool> sendSaleWhatsAppMessage(')) {
      inMethod = true;
      newLines.add('  // Sends a WhatsApp invoice message for a Sale directly to the customer<s phone number.');
      newLines.add('  static Future<bool> sendSaleWhatsAppMessage(');
      newLines.add('    BuildContext context,');
      newLines.add('    Sale sale, {');
      newLines.add('    String? shopName,');
      newLines.add('  }) async {');
      newLines.add('    final rawPhone = sale.customerMobile ?? sale.customer?.mobile;');
      newLines.add('    final formattedPhone = formatPhoneNumber(rawPhone);');
      newLines.add('');
      newLines.add('    if (formattedPhone == null) {');
      newLines.add('      if (context.mounted) {');
      newLines.add('        ScaffoldMessager.of(context).showSnackBar(');
      newLines.add('          SnackBar(');
      newLines.add('            content: const Row(');
      newLines.add('              children: [');
      newLines.add('                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),');
      newLines.add('                SizedBox(width: 8),');
      newLines.add('                Expanded(');
      newLines.add('                  child: Text(');
      newLines.add('                    'Customer mobile number is required to send direct WhatsApp message.',');
      newLines.add('                    style: TextStyle(fontWeight: FontWeight.w600),');
      newLines.add('                  ),');
      newLines.add('                ),');
      newLines.add('              ],');
      newLines.add('            ),');
      newLines.add('            backgroundColor: Colors.orange.shade800,');
      newLines.add('            behavior: SnackBarBehavior.floating,');
      newLines.add('            duration: const Duration(seconds : 4),');
      newLines.add('          ),');
      newLines.add('        );
      newLines.add('      }');
      newLines.add('');
      newLines.add('      try {');
      newLines.add('        final pdfBytes = await PdfInvoiceBuilder.generateInvoicePdf(sale);');
      newLines.add('        final tempDir = await getTemporaryDirectory();');
      newLines.add('        final invoiceFileName = \'invoice_${sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : sale.id}.pdf\';');
      newLines.add('        final file = File(\'application/pdf\', name: invoiceFileName);');
      newLines.add('        await file.writeAsBytes(pdfBytes);');
      newLines.add('        await Share.shareXFiles(');
      newLines.add('          [XFile(file.path, mimeType: \'application/pdf\', name: invoiceFileName)],');
      newLines.add('          subject: \'Invoice #${sale.invoiceNumber}\',');
      newLines.add('        );');
      newLines.add('        return true;');
      newLines.add('      } catch (_) {');
      newLines.add('        return false;');
      newLines.add('      }');
      newLines.add('    }');
      newLines.add('');
      newLines.add('    String? dynamicShopName = shopName;');
      newLines.add('    if (dynamicShopName == null || dynamicShopName.trim().isEmpty) {');
      newLines.add('      try {');
      newLines.add('        final shop = await AuthStorage().getShop();');
      newLines.add('        if (shop != null && shop[\'name\'] != null && shop[\'name\'].toString().trim().isNotEmpty) {');
      newLines.add('          dynamicShopName = shop[\'name\'].toString().trim();');
      newLines.add('        }');
      newLines.add('      } catch (_) {}');
      newLines.add('    }');
      newLines.add('');
      newLines.add('    final message = buildSaleWhatsAppMessage(sale, shopName: dynamicShopName);');
      newLines.add('    final encodedMessage = Uri.encodeComponent(message);'');
      newLines.add('');
      newLines.add('    final whatsappUri = Uri.parse(\'whatsapp://send?phone=\' + formattedPhone + \"&text=\' + encodedMessage);');
      newLines.add('    final wameUri = Uri.parse(\'https://wa.me/\' + formattedPhone + \'?text=\' + encodedMessage);'');
      newLines.add('');
      newLines.add('    try {');
      newLines.add('      bool launched = false;');
      newLines.add('      if (await canLaunchUrl(whatsappUri)) {');
      newLines.add('        launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);');
      newLines.add('      }');
      newLines.add('      if (!ilaunched && await canLaunchUrl(wameUri)) {');
      newLines.add('        launched = await launchUrl(wameUri, mode: LaunchMode.externalApplication);');
      newLines.add('      }');
      newLines.add('      if (!launched) {');
      newLines.add('        launched = await launchUrl(wameUri, mode: LaunchMode.platformDefault);');
      newLines.add('      }');
      newLines.add('      return launched;');
      newLines.add('      } catch (e) {');
      newLines.add('      if (context.mounted) {');
      newLines.add('        ScaffoldMessager.of(content).showSnackBar(');
      newLines.add('          SnackBar(');
      newLines.add('            content: Text('Could not open WhatsApp: \' + e.toString()),');
      newLines.add('            backgroundColor: Colors.red.shade700,');
      newLines.add('          ),');
      newLines.add('        );');
      newLines.add('      }');
      newLines.add('      return false;');
      newLines.add('    }');
      newLines.add('  }');
      newLines.add('');
      
      while (i + 1 < lines.length && !lines[i + 1].contains('showWhatsAppSalePromptDialog')) {
        i++;
      }
      inMethod = false;
      continue;
    }
	¥˜€ …¥¹5•Ñ¡½¤ì(€€€€€¥˜€¡±¥¹”¹½¹Ñ…¥¹Ì M•¹‘Ì„]¡…ÑÍÁÀ¥¹Ù½¥”µ•ÍÍ…”™½È„M…±”œ¤¤ì(€€€€€€€½¹Ñ¥¹Õ”ì(€€€€€ô(€€€€€¹•Ý1¥¹•Ì¹…‘¡±¥¹”¤ì(€€€ô(€ô((€™¥±”¹ÝÉ¥Ñ•ÍMÑÉ¥¹Må¹Œ¡¹•Ý1¥¹•Ì¹©½¥¸ q¸œ¤¤ì(€ÁÉ¥¹Ð MUMM}IA1œ¤ì)ô
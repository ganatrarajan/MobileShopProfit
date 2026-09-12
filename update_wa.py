import os

path = 'lib/core/utils/whatsapp_helper.dart'
content = open(path, encoding='utf-8').read()

start_tag = '  // Sends a WhatsApp invoice message for a Sale including PDF file + formatted message text by default.'
if start_tag not in content:
    start_tag = '  static Future<bool> sendSaleWhatsAppMessage('

start_idx = content.find(start_tag)
end_tag = '  // Prompts user after sale creation'
end_idx = content.find(end_tag)

new_code = '''  // Sends a WhatsApp invoice message for a Sale directly to the customer's phone number.
  static Future<bool> sendSaleWhatsAppMessage(
    BuildContext context,
    Sale sale, {
    String? shopName,
  }) async {
    final rawPhone = sale.customerMobile ?C sale.customer?.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);

    if (formattedPhone == null) {
      if (context.mounted) {
        ScaffoldMessager.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customer mobile number is required to send direct WhatsApp message.',
                     style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                 ),
              ],
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // If no phone number, fallback to generic PDF share sheet
      try {
        final pdfBytes = await PdfInvoiceBuilder.generateInvoicePdf(sale);
        final tempDir = await getTemporaryDirectory();
        final invoiceFileName = 'Invoice_${sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : sale.id}.pdf';
        final file = File('${tempDir.path}/$invoiceFileName');
        await file.writeAsBytes(pdfBytes);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf', name: invoiceFileName)],
          subject: 'Invoice #${sale.invoiceNumber}',
        );
        return true;
      } catch (_) {
        return false;
      }
    }

    String? dynamicShopName = shopName;
    if (dynamicShopName == null || dynamicShopName.trim().isEmpty) {
      try {
        final shop = await AuthStorage().getShop();
        if (shop != null && shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
          dynamicShopName = shop['name'].toString().trim();
        }
      } catch (_) {}
    }

    final message = buildSaleWhatsAppMessage(sale, shopName: dynamicShopName);
    final encodedMessage = Uri.encodeComponent(message);

    final whatsappUri = Uri.parse('whatsapp://send?phone=' + formattedPhone + '&text=' + encodedMessage);
    final wameUri = Uri.parse('https://wa.me/' + formattedPhone + '?text=' + encodedMessage);

    try {
      bool launched = false;
      if (await canLaunchUrl(whatsappUri)) {
        launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
      if (!launched && await canLaunchUrl(wameUri)) {
        launched = await launchUrl(wameUri, mode: LaunchMode.externalApplication);
      }
      if (!launched) {
        launched = await launchUrl(wameUri, mode: LaunchMode.platformDefault);
      }
      return launched;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessager.of(content).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp: ' + e.toString()),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return false;
    }
  }
'''

updated = content[:start_idx] + new_code + content[end_idx:]
open(path, 'w', encoding='utf-8').write(updated)
print('SUCCESS_UPDATED_WHATSAPP')

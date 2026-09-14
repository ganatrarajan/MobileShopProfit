import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_invoice_builder.dart';
import 'date_helper.dart';
import '../theme/app_colors.dart';
import '../../features/sales/models/sale.dart';
import '../../features/repair/models/repair.dart';
import '../storage/auth_storage.dart';
import '../widgets/whatsapp_icon.dart';

class WhatsAppHelper {
  /// Formats phone numbers by stripping non-digit characters and adding standard country code if missing.
  static String? formatPhoneNumber(String? rawPhone) {
    if (rawPhone == null) return null;
    String clean = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return null;
    if (clean.startsWith('+')) return clean.substring(1);
    if (clean.length == 10) return '91$clean';
    return clean;
  }

  // ==========================================
  // SALE WHATSAPP METHODS
  // ==========================================

  /// Builds a formatted text summary for a Sale invoice matching the user's exact default template.
  static String buildSaleWhatsAppMessage(
    Sale sale, {
    String? shopName,
  }) {
    final customerName = sale.customerName?.trim().isNotEmpty == true
        ? sale.customerName!.trim()
        : (sale.customer?.name.trim().isNotEmpty == true ? sale.customer!.name.trim() : 'Customer');

    final effectiveShopName = shopName?.trim().isNotEmpty == true
        ? shopName!.trim()
        : 'Raju mobile';

    final invoiceNum = sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : 'INV-${sale.id}';
    final rawDate = sale.saleDate.isNotEmpty ? sale.saleDate : DateTime.now().toIso8601String();
    final dateStr = DateHelper.formatDateTime(rawDate);

    final sb = StringBuffer();
    sb.writeln('Hello $customerName 👋');
    sb.writeln('');
    sb.writeln('Thank you for shopping at *$effectiveShopName*! 🛍️');
    sb.writeln('');
    sb.writeln('🧾 INVOICE SUMMARY');
    sb.writeln('* Invoice No: #$invoiceNum');
    sb.writeln('* Date: $dateStr');
    sb.writeln('');
    sb.writeln('📦 ITEMS PURCHASED:');

    for (var i = 0; i < sale.items.length; i++) {
      final item = sale.items[i];
      final brandModel = '${item.brand ?? ''} ${item.model ?? ''}'.trim();
      final itemTitle = brandModel.isNotEmpty
          ? '${item.productName} ($brandModel)'
          : item.productName;
      sb.writeln('  ${i + 1}. $itemTitle x ${item.quantity} - ₹${item.total.toStringAsFixed(0)}');
    }

    sb.writeln('');
    sb.writeln('💳 PAYMENT BREAKDOWN:');
    sb.writeln('* Grand Total: ₹${sale.grandTotal.toStringAsFixed(2)}');
    sb.writeln('* Amount Paid: ₹${sale.amountPaid.toStringAsFixed(2)}');

    if (sale.amountDue > 0) {
      sb.writeln('* Balance Due: ₹${sale.amountDue.toStringAsFixed(2)} ⚠️');
    } else {
      sb.writeln('* Status: PAID IN FULL ✅');
    }

    if (sale.warranty != null) {
      sb.writeln('');
      sb.writeln('🛡️ WARRANTY COVERAGE:');
      sb.writeln('* Warranty No: ${sale.warranty!.warrantyNumber}');
      sb.writeln('* Duration: ${sale.warranty!.durationDays} Days');
      sb.writeln('* Valid Until: ${DateHelper.formatDate(sale.warranty!.warrantyEndDate)}');
      if (sale.warranty!.warrantyTerms != null && sale.warranty!.warrantyTerms!.isNotEmpty) {
        sb.writeln('* Terms: ${sale.warranty!.warrantyTerms}');
      }
    }

    if (sale.notes != null && sale.notes!.trim().isNotEmpty) {
      sb.writeln('');
      sb.writeln('📝 Notes: ${sale.notes!.trim()}');
    }

    sb.writeln('');
    sb.writeln('Thank you for your business! Have a wonderful day! 🤝✨');

    return sb.toString();
  }

  /// Opens a bottom sheet giving choice between Direct Chat (auto-fill phone) or Share PDF Invoice File.
  static Future<void> sendSaleWhatsAppMessage(
    BuildContext context,
    Sale sale, {
    String? shopName,
  }) async {
    final rawPhone = sale.customerMobile ?? sale.customer?.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);
    final customerName = sale.customerName ?? sale.customer?.name ?? 'Customer';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const WhatsAppIcon(size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WhatsApp Invoice',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$customerName ${formattedPhone != null ? "($formattedPhone)" : ""}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Option 1: Direct Chat (Auto-fill Number)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
                ),
                title: const Text('Direct Chat Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Opens chat directly with auto-filled phone number & text bill', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _launchDirectSaleWhatsApp(context, sale, shopName: shopName);
                },
              ),

              const SizedBox(height: 6),

              // Option 2: Share PDF Invoice File
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                ),
                title: const Text('Share PDF Invoice File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Generates & attaches the PDF Bill file to share on WhatsApp', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _shareSalePdfInvoice(context, sale, shopName: shopName);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Helper: Direct WhatsApp chat launch with auto-filled phone number & text
  static Future<bool> _launchDirectSaleWhatsApp(
    BuildContext context,
    Sale sale, {
    String? shopName,
  }) async {
    final rawPhone = sale.customerMobile ?? sale.customer?.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);

    String? dynamicShopName = shopName;
    if (dynamicShopName == null || dynamicShopName.trim().isEmpty) {
      try {
        final shop = await AuthStorage().getShop();
        if (shop != null && shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
          dynamicShopName = shop['name'].toString().trim();
        }
      } catch (_) {}
    }

    final messageText = buildSaleWhatsAppMessage(sale, shopName: dynamicShopName);

    if (formattedPhone != null) {
      final encodedMessage = Uri.encodeComponent(messageText);
      final whatsappUri = Uri.parse('whatsapp://send?phone=$formattedPhone&text=$encodedMessage');
      final wameUri = Uri.parse('https://wa.me/$formattedPhone?text=$encodedMessage');

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
        if (launched) return true;
      } catch (_) {}
    }

    if (context.mounted) {
      return await _shareSalePdfInvoice(context, sale, shopName: shopName);
    }
    return false;
  }

  /// Helper: Shares the PDF Invoice File
  static Future<bool> _shareSalePdfInvoice(
    BuildContext context,
    Sale sale, {
    String? shopName,
  }) async {
    try {
      String? dynamicShopName = shopName;
      if (dynamicShopName == null || dynamicShopName.trim().isEmpty) {
        try {
          final shop = await AuthStorage().getShop();
          if (shop != null && shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
            dynamicShopName = shop['name'].toString().trim();
          }
        } catch (_) {}
      }

      final invoiceNum = sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : '${sale.id}';
      final pdfBytes = await PdfInvoiceBuilder.generateInvoicePdf(sale);
      final tempDir = await getTemporaryDirectory();
      final invoiceFileName = 'Invoice_$invoiceNum.pdf';
      final file = File('${tempDir.path}/$invoiceFileName');
      await file.writeAsBytes(pdfBytes);

      final messageText = buildSaleWhatsAppMessage(sale, shopName: dynamicShopName);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: invoiceFileName)],
        subject: 'Invoice #$invoiceNum',
        text: messageText,
      );
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share PDF invoice: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return false;
    }
  }

  /// Prompts user after sale creation to optionally send WhatsApp bill.
  static Future<void> showWhatsAppSalePromptDialog(BuildContext context, Sale sale) async {
    await sendSaleWhatsAppMessage(context, sale);
  }

  // ==========================================
  // REPAIR WHATSAPP METHODS
  // ==========================================

  /// Builds a formatted WhatsApp text message for a Repair job.
  static String buildRepairWhatsAppMessage(
    Repair repair, {
    String? shopName,
  }) {
    final customerName = repair.customer?.name.trim().isNotEmpty == true
        ? repair.customer!.name.trim()
        : 'Customer';

    final effectiveShopName = shopName?.trim().isNotEmpty == true
        ? shopName!.trim()
        : 'Mobile Repair & Electronics Shop';

    final jobNum = repair.jobNumber.isNotEmpty ? repair.jobNumber : 'REP-${repair.id}';
    final dateStr = repair.dateReceived.isNotEmpty ? DateHelper.formatDate(repair.dateReceived) : DateHelper.formatDate(DateTime.now().toIso8601String());
    final deviceStr = '${repair.device?.brand ?? ''} ${repair.device?.model ?? ''}'.trim();

    final sb = StringBuffer();
    sb.writeln('Hello $customerName 👋');
    sb.writeln('');
    sb.writeln('Thank you for choosing *$effectiveShopName* for your device repair!');
    sb.writeln('');
    sb.writeln('🛠️ REPAIR TICKET SUMMARY');
    sb.writeln('* Job No: #$jobNum');
    sb.writeln('* Date: $dateStr');
    if (deviceStr.isNotEmpty) {
      sb.writeln('* Device: $deviceStr');
    }
    if (repair.problemDescription.isNotEmpty) {
      sb.writeln('* Problem: ${repair.problemDescription}');
    }
    sb.writeln('* Status: ${repair.repairStatus.toUpperCase()}');
    sb.writeln('');
    sb.writeln('💳 PAYMENT DETAILS');
    sb.writeln('* Total Cost: ₹${repair.netCost.toStringAsFixed(2)}');
    sb.writeln('* Advance Paid: ₹${repair.amountPaid.toStringAsFixed(2)}');
    if (repair.amountDue > 0) {
      sb.writeln('* Balance Due: ₹${repair.amountDue.toStringAsFixed(2)} ⚠️');
    } else {
      sb.writeln('* Status: PAID IN FULL ✅');
    }

    sb.writeln('');
    sb.writeln('Thank you for your trust! We will keep you updated on the repair progress. 🤝✨');

    return sb.toString();
  }

  /// Sends a direct or shareable WhatsApp message for a Repair ticket.
  static Future<bool> sendRepairWhatsAppMessage(
    BuildContext context,
    Repair repair, {
    String? shopName,
  }) async {
    final rawPhone = repair.customer?.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);

    String? dynamicShopName = shopName;
    if (dynamicShopName == null || dynamicShopName.trim().isEmpty) {
      try {
        final shop = await AuthStorage().getShop();
        if (shop != null && shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
          dynamicShopName = shop['name'].toString().trim();
        }
      } catch (_) {}
    }

    final message = buildRepairWhatsAppMessage(repair, shopName: dynamicShopName);
    final encodedMessage = Uri.encodeComponent(message);

    if (formattedPhone != null) {
      final whatsappUri = Uri.parse('whatsapp://send?phone=$formattedPhone&text=$encodedMessage');
      final wameUri = Uri.parse('https://wa.me/$formattedPhone?text=$encodedMessage');

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
        if (launched) return true;
      } catch (_) {}
    }

    // Fallback to text share
    try {
      await Share.share(message, subject: 'Repair Ticket #${repair.jobNumber}');
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send WhatsApp message: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return false;
    }
  }

  /// Sends status update message on WhatsApp for a Repair job.
  static Future<bool> sendRepairStatusWhatsAppMessage(
    BuildContext context,
    Repair repair,
    String? newStatus, {
    String? statusNotes,
  }) async {
    final statusToReport = newStatus ?? repair.repairStatus;
    final rawPhone = repair.customer?.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);

    String shopName = 'Mobile Repair & Electronics Shop';
    try {
      final shop = await AuthStorage().getShop();
      if (shop != null && shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
        shopName = shop['name'].toString().trim();
      }
    } catch (_) {}

    final customerName = repair.customer?.name.trim().isNotEmpty == true
        ? repair.customer!.name.trim()
        : 'Customer';

    final jobNum = repair.jobNumber.isNotEmpty ? repair.jobNumber : 'REP-${repair.id}';
    final deviceStr = '${repair.device?.brand ?? ''} ${repair.device?.model ?? ''}'.trim();

    final sb = StringBuffer();
    sb.writeln('Hello $customerName 👋');
    sb.writeln('');
    sb.writeln('Update from *$shopName* regarding your repair job *#$jobNum* ($deviceStr):');
    sb.writeln('');
    sb.writeln('🔔 Status Updated To: ${statusToReport.toUpperCase()}');
    if (statusNotes != null && statusNotes.trim().isNotEmpty) {
      sb.writeln('📝 Notes: ${statusNotes.trim()}');
    }
    if (statusToReport.toLowerCase() == 'completed' || statusToReport.toLowerCase() == 'ready') {
      sb.writeln('🎉 Your device is repaired and ready for pickup!');
      if (repair.amountDue > 0) {
        sb.writeln('* Remaining Balance: ₹${repair.amountDue.toStringAsFixed(2)}');
      }
    }
    sb.writeln('');
    sb.writeln('Thank you for your patience! 🤝✨');

    final message = sb.toString();
    final encodedMessage = Uri.encodeComponent(message);

    if (formattedPhone != null) {
      final whatsappUri = Uri.parse('whatsapp://send?phone=$formattedPhone&text=$encodedMessage');
      final wameUri = Uri.parse('https://wa.me/$formattedPhone?text=$encodedMessage');

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
        if (launched) return true;
      } catch (_) {}
    }

    try {
      await Share.share(message, subject: 'Repair Status Update #${repair.jobNumber}');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Prompts user after repair creation to optionally send WhatsApp notification.
  static Future<void> showWhatsAppPromptDialog(BuildContext context, Repair repair) async {
    final phone = repair.customer?.mobile;
    if (phone == null || phone.trim().isEmpty) return;

    final customerName = repair.customer?.name ?? 'Customer';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            WhatsAppIcon(size: 24),
            SizedBox(width: 10),
            Text('Send WhatsApp Update?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Would you like to send repair job details to $customerName ($phone) on WhatsApp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const WhatsAppIcon(size: 18, showBackground: false),
            label: const Text('Send WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await sendRepairWhatsAppMessage(context, repair);
    }
  }

  /// Shows a modal bottom sheet allowing user to select WhatsApp message type:
  /// 1. Status Update Message
  /// 2. Complete Ticket / Bill Summary
  
  /// Helper: Shares the Repair PDF Job Sheet / Ticket File
  static Future<bool> shareRepairPdfInvoice(
    BuildContext context,
    Repair repair, {
    String? shopName,
  }) async {
    try {
      String? dynamicShopName = shopName;
      if (dynamicShopName == null || dynamicShopName.trim().isEmpty) {
        try {
          final shop = await AuthStorage().getShop();
          if (shop != null && shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
            dynamicShopName = shop['name'].toString().trim();
          }
        } catch (_) {}
      }

      final jobNum = repair.jobNumber.isNotEmpty ? repair.jobNumber : '${repair.id}';
      final pdfBytes = await PdfInvoiceBuilder.generateRepairPdf(repair);
      final tempDir = await getTemporaryDirectory();
      final pdfFileName = 'Repair_Ticket_$jobNum.pdf';
      final file = File('${tempDir.path}/$pdfFileName');
      await file.writeAsBytes(pdfBytes);

      final messageText = buildRepairWhatsAppMessage(repair, shopName: dynamicShopName);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: pdfFileName)],
        subject: 'Repair Ticket #$jobNum',
        text: messageText,
      );
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share PDF repair ticket: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return false;
    }
  }

  /// Shows a modal bottom sheet allowing user to select WhatsApp message type:
  /// 1. Share Repair PDF Bill File
  /// 2. Status Update Text
  /// 3. Complete Ticket Text Summary
  static Future<void> showRepairWhatsAppOptions(BuildContext context, Repair repair) async {
    final rawPhone = repair.customer?.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);
    final customerName = repair.customer?.name.trim().isNotEmpty == true
        ? repair.customer!.name.trim()
        : 'Customer';
    final currentStatusLabel = repair.repairStatus.toUpperCase();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const WhatsAppIcon(size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WhatsApp Message Options',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$customerName ${rawPhone != null && rawPhone.isNotEmpty ? "($rawPhone)" : ""}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Option 1: Share PDF Bill File (WhatsApp Document)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 20),
                  ),
                  title: const Text('Share Repair PDF Bill File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Generates & attaches official PDF document on WhatsApp'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await shareRepairPdfInvoice(context, repair);
                  },
                ),
                const Divider(height: 1),

                // Option 2: Text Status Update
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.published_with_changes_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('Send Status Update Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Status: $currentStatusLabel'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await sendRepairStatusWhatsAppMessage(context, repair, repair.repairStatus);
                  },
                ),
                const Divider(height: 1),

                // Option 3: Complete Ticket Text Summary
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const WhatsAppIcon(size: 20, showBackground: false),
                  ),
                  title: const Text('Send Complete Ticket Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Send job sheet summary text & payment details'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await sendRepairWhatsAppMessage(context, repair);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

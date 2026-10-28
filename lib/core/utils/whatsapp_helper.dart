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
import '../../features/customer/models/customer.dart';
import '../../features/warranty/models/warranty.dart';
import '../storage/auth_storage.dart';
import '../storage/preferences_storage.dart';
import '../widgets/whatsapp_icon.dart';

enum WhatsAppLanguage {
  english('en', 'English', 'English', '🇬🇧'),
  hindi('hi', 'हिन्दी', 'Hindi', '🇮🇳'),
  gujarati('gu', 'ગુજરાતી', 'Gujarati', '🇮🇳');

  final String code;
  final String label;
  final String englishName;
  final String flag;

  const WhatsAppLanguage(this.code, this.label, this.englishName, this.flag);

  String get displayName => '$flag $label ($englishName)';
  String get shortName => '$flag $label';

  static WhatsAppLanguage fromCode(String? code) {
    switch (code) {
      case 'hi':
        return WhatsAppLanguage.hindi;
      case 'gu':
        return WhatsAppLanguage.gujarati;
      case 'en':
      default:
        return WhatsAppLanguage.english;
    }
  }
}

/// A compact, interactive language selector widget for WhatsApp dialogs & bottom sheets.
class WhatsAppLanguageSelector extends StatelessWidget {
  final WhatsAppLanguage selectedLanguage;
  final ValueChanged<WhatsAppLanguage> onLanguageChanged;
  final bool compact;

  const WhatsAppLanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          children: const [
            Icon(Icons.translate_rounded, size: 15, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Text(
              'Select Language / ભાષા / भाषा:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: WhatsAppLanguage.values.map((lang) {
            final isSelected = lang == selectedLanguage;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: InkWell(
                  onTap: () => onLanguageChanged(lang),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                      vertical: compact ? 7 : 9,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF25D366).withOpacity(0.12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF25D366) : Colors.grey.shade300,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lang.flag,
                          style: TextStyle(fontSize: compact ? 14 : 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang.label,
                          style: TextStyle(
                            fontSize: compact ? 11 : 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF0F5132) : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          lang.englishName,
                          style: TextStyle(
                            fontSize: compact ? 9 : 10,
                            color: isSelected ? const Color(0xFF0F5132).withOpacity(0.8) : AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

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

  /// Builds a formatted text summary for a Sale invoice in English, Hindi, or Gujarati.
  static String buildSaleWhatsAppMessage(
    Sale sale, {
    String? shopName,
    WhatsAppLanguage language = WhatsAppLanguage.english,
  }) {
    final customerName = sale.customerName?.trim().isNotEmpty == true
        ? sale.customerName!.trim()
        : (sale.customer?.name.trim().isNotEmpty == true
            ? sale.customer!.name.trim()
            : (language == WhatsAppLanguage.gujarati
                ? 'ગ્રાહક'
                : (language == WhatsAppLanguage.hindi ? 'ग्राहक' : 'Customer')));

    final effectiveShopName = shopName?.trim().isNotEmpty == true
        ? shopName!.trim()
        : 'Mobile Repair & Electronics Shop';

    final invoiceNum = sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : 'INV-${sale.id}';
    final rawDate = sale.saleDate.isNotEmpty ? sale.saleDate : DateTime.now().toIso8601String();
    final dateStr = DateHelper.formatDateTime(rawDate);

    final sb = StringBuffer();

    switch (language) {
      case WhatsAppLanguage.hindi:
        sb.writeln('नमस्ते $customerName 👋');
        sb.writeln('');
        sb.writeln('*$effectiveShopName* से खरीदारी करने के लिए आपका बहुत-बहुत धन्यवाद! 🛍️✨');
        sb.writeln('');
        sb.writeln('🧾 बिल विवरण (INVOICE SUMMARY)');
        sb.writeln('* इनवॉइस नंबर: #$invoiceNum');
        sb.writeln('* दिनांक: $dateStr');
        sb.writeln('');
        sb.writeln('📦 खरीदे गए उत्पाद (ITEMS PURCHASED):');
        for (var i = 0; i < sale.items.length; i++) {
          final item = sale.items[i];
          final brandModel = '${item.brand ?? ''} ${item.model ?? ''}'.trim();
          final itemTitle = brandModel.isNotEmpty
              ? '${item.productName} ($brandModel)'
              : item.productName;
          sb.writeln('  ${i + 1}. $itemTitle x ${item.quantity} - ₹${item.total.toStringAsFixed(0)}');
        }
        sb.writeln('');
        sb.writeln('💳 भुगतान विवरण (PAYMENT BREAKDOWN):');
        sb.writeln('* कुल बिल राशि: ₹${sale.grandTotal.toStringAsFixed(2)}');
        sb.writeln('* जमा राशि: ₹${sale.amountPaid.toStringAsFixed(2)}');
        if (sale.amountDue > 0) {
          sb.writeln('* बकाया राशि: ₹${sale.amountDue.toStringAsFixed(2)} ⚠️');
        } else {
          sb.writeln('* भुगतान स्थिति: पूरा भुगतान प्राप्त ✅ (PAID IN FULL)');
        }
        if (sale.warranty != null) {
          sb.writeln('');
          sb.writeln('🛡️ वारंटी विवरण (WARRANTY COVERAGE):');
          sb.writeln('* वारंटी नंबर: ${sale.warranty!.warrantyNumber}');
          sb.writeln('* वारंटी अवधि: ${sale.warranty!.durationDays} दिन');
          sb.writeln('* वैध तिथि: ${DateHelper.formatDate(sale.warranty!.warrantyEndDate)}');
          if (sale.warranty!.warrantyTerms != null && sale.warranty!.warrantyTerms!.isNotEmpty) {
            sb.writeln('* नियम व शर्तें: ${sale.warranty!.warrantyTerms}');
          }
        }
        if (sale.notes != null && sale.notes!.trim().isNotEmpty) {
          sb.writeln('');
          sb.writeln('📝 नोट्स: ${sale.notes!.trim()}');
        }
        sb.writeln('');
        sb.writeln('आपके विश्वास और व्यापार के लिए धन्यवाद! 🤝✨');
        break;

      case WhatsAppLanguage.gujarati:
        sb.writeln('નમસ્તે $customerName 👋');
        sb.writeln('');
        sb.writeln('*$effectiveShopName* માંથી ખરીદી કરવા બદલ આપનો ખૂબ ખૂબ આભાર! 🛍️✨');
        sb.writeln('');
        sb.writeln('🧾 બિલ વિગતો (INVOICE SUMMARY)');
        sb.writeln('* ઇનવોઇસ નંબર: #$invoiceNum');
        sb.writeln('* તારીખ: $dateStr');
        sb.writeln('');
        sb.writeln('📦 ખરીદેલ પ્રોડક્ટ્સ (ITEMS PURCHASED):');
        for (var i = 0; i < sale.items.length; i++) {
          final item = sale.items[i];
          final brandModel = '${item.brand ?? ''} ${item.model ?? ''}'.trim();
          final itemTitle = brandModel.isNotEmpty
              ? '${item.productName} ($brandModel)'
              : item.productName;
          sb.writeln('  ${i + 1}. $itemTitle x ${item.quantity} - ₹${item.total.toStringAsFixed(0)}');
        }
        sb.writeln('');
        sb.writeln('💳 પેમેન્ટ વિગતો (PAYMENT BREAKDOWN):');
        sb.writeln('* કુલ બિલ રકમ: ₹${sale.grandTotal.toStringAsFixed(2)}');
        sb.writeln('* ચૂકવેલ રકમ: ₹${sale.amountPaid.toStringAsFixed(2)}');
        if (sale.amountDue > 0) {
          sb.writeln('* બાકી રકમ: ₹${sale.amountDue.toStringAsFixed(2)} ⚠️');
        } else {
          sb.writeln('* પેમેન્ટ સ્થિતિ: પૂરેપૂરું ચૂકવાઈ ગયેલ છે ✅ (PAID IN FULL)');
        }
        if (sale.warranty != null) {
          sb.writeln('');
          sb.writeln('🛡️ વોરંટી વિગતો (WARRANTY COVERAGE):');
          sb.writeln('* વોરંટી નંબર: ${sale.warranty!.warrantyNumber}');
          sb.writeln('* વોરંટી સમયગાળો: ${sale.warranty!.durationDays} દિવસ');
          sb.writeln('* માન્ય તારીખ: ${DateHelper.formatDate(sale.warranty!.warrantyEndDate)}');
          if (sale.warranty!.warrantyTerms != null && sale.warranty!.warrantyTerms!.isNotEmpty) {
            sb.writeln('* શરતો: ${sale.warranty!.warrantyTerms}');
          }
        }
        if (sale.notes != null && sale.notes!.trim().isNotEmpty) {
          sb.writeln('');
          sb.writeln('📝 નોંધ: ${sale.notes!.trim()}');
        }
        sb.writeln('');
        sb.writeln('અમારા પર વિશ્વાસ મૂકવા બદલ આભાર! આપનો દિવસ શુભ રહે! 🤝✨');
        break;

      case WhatsAppLanguage.english:
      default:
        sb.writeln('Hello $customerName 👋');
        sb.writeln('');
        sb.writeln('Thank you for shopping at *$effectiveShopName*! 🛍️✨');
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
        break;
    }

    return sb.toString();
  }

  /// Opens a bottom sheet allowing choice of Language and Direct Chat or Share PDF Invoice File.
  static Future<void> sendSaleWhatsAppMessage(
    BuildContext context,
    Sale sale, {
    String? shopName,
    WhatsAppLanguage? language,
  }) async {
    final rawPhone = sale.customerMobile ?? sale.customer?.mobile;
    final customerName = sale.customerName ?? sale.customer?.name ?? 'Customer';

    final initialLangCode = await PreferencesStorage().getWhatsAppLanguage();
    var currentLang = language ?? WhatsAppLanguage.fromCode(initialLangCode);

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: SingleChildScrollView(
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
                                  'WhatsApp Invoice Options',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$customerName ${rawPhone != null && rawPhone.isNotEmpty ? "($rawPhone)" : ""}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                      const SizedBox(height: 12),

                      // Language Selector
                      WhatsAppLanguageSelector(
                        selectedLanguage: currentLang,
                        onLanguageChanged: (newLang) {
                          setModalState(() {
                            currentLang = newLang;
                          });
                          PreferencesStorage().saveWhatsAppLanguage(newLang.code);
                        },
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Option 1: Direct Chat (Auto-fill Number)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
                        ),
                        title: const Text('Direct Chat Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Sends full invoice text in ${currentLang.label} directly to customer', style: const TextStyle(fontSize: 12)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _launchDirectSaleWhatsApp(context, sale, shopName: shopName, language: currentLang);
                        },
                      ),

                      const Divider(height: 1),

                      // Option 2: Share PDF Invoice File
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                        ),
                        title: const Text('Share PDF Invoice File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Attaches official PDF invoice + ${currentLang.label} summary on WhatsApp', style: const TextStyle(fontSize: 12)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _shareSalePdfInvoice(context, sale, shopName: shopName, language: currentLang);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Helper: Direct WhatsApp chat launch with auto-filled phone number & text
  static Future<bool> _launchDirectSaleWhatsApp(
    BuildContext context,
    Sale sale, {
    String? shopName,
    WhatsAppLanguage? language,
  }) async {
    final rawPhone = sale.customerMobile ?? sale.customer?.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);

    final lang = language ?? WhatsAppLanguage.fromCode(await PreferencesStorage().getWhatsAppLanguage());

    String? dynamicShopName = shopName;
    if (dynamicShopName == null || dynamicShopName.trim().isEmpty) {
      try {
        final shop = await AuthStorage().getShop();
        if (shop != null && shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
          dynamicShopName = shop['name'].toString().trim();
        }
      } catch (_) {}
    }

    final messageText = buildSaleWhatsAppMessage(sale, shopName: dynamicShopName, language: lang);

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
      return await _shareSalePdfInvoice(context, sale, shopName: shopName, language: lang);
    }
    return false;
  }

  /// Helper: Shares the PDF Invoice File with localized message
  static Future<bool> _shareSalePdfInvoice(
    BuildContext context,
    Sale sale, {
    String? shopName,
    WhatsAppLanguage? language,
  }) async {
    try {
      final lang = language ?? WhatsAppLanguage.fromCode(await PreferencesStorage().getWhatsAppLanguage());

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

      final messageText = buildSaleWhatsAppMessage(sale, shopName: dynamicShopName, language: lang);

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

  /// Prompts user after sale creation to optionally send WhatsApp bill with language selector.
  static Future<void> showWhatsAppSalePromptDialog(BuildContext context, Sale sale) async {
    final rawPhone = sale.customerMobile ?? sale.customer?.mobile;
    final customerName = sale.customerName ?? sale.customer?.name ?? 'Customer';
    final initialLangCode = await PreferencesStorage().getWhatsAppLanguage();
    var selectedLang = WhatsAppLanguage.fromCode(initialLangCode);

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              WhatsAppIcon(size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text('Send WhatsApp Bill?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Would you like to send invoice #${sale.invoiceNumber} to $customerName (${rawPhone ?? "Customer"}) on WhatsApp?'),
              const SizedBox(height: 14),
              WhatsAppLanguageSelector(
                compact: true,
                selectedLanguage: selectedLang,
                onLanguageChanged: (lang) {
                  setDialogState(() {
                    selectedLang = lang;
                  });
                  PreferencesStorage().saveWhatsAppLanguage(lang.code);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip / Done', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
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
      ),
    );

    if (result == true && context.mounted) {
      await _launchDirectSaleWhatsApp(context, sale, language: selectedLang);
    }
  }
  // ==========================================
  // REPAIR WHATSAPP METHODS
  // ==========================================

  /// Returns localized status name for display in WhatsApp message
  static String getLocalizedStatus(String status, WhatsAppLanguage lang) {
    final s = status.trim().toLowerCase();
    switch (lang) {
      case WhatsAppLanguage.hindi:
        switch (s) {
          case 'pending':
            return 'लंबित (PENDING)';
          case 'in_progress':
          case 'in progress':
            return 'कार्य प्रगति पर है (IN PROGRESS)';
          case 'ready':
            return 'डिलीवरी के लिए तैयार (READY)';
          case 'completed':
            return 'रिपेयर पूर्ण (COMPLETED)';
          case 'delivered':
            return 'डिलीवर कर दिया गया (DELIVERED)';
          case 'cannot_repair':
          case 'cannot repair':
          case 'unrepairable':
            return 'रिपेयर नहीं हो सका (CANNOT REPAIR)';
          case 'cancelled':
            return 'रद्द किया गया (CANCELLED)';
          default:
            return status.toUpperCase();
        }
      case WhatsAppLanguage.gujarati:
        switch (s) {
          case 'pending':
            return 'પેન્ડિંગ / બાકી (PENDING)';
          case 'in_progress':
          case 'in progress':
            return 'કામ ચાલુ છે (IN PROGRESS)';
          case 'ready':
            return 'ડિલિવરી માટે તૈયાર છે (READY)';
          case 'completed':
            return 'રિપેરિંગ પૂર્ણ થયું (COMPLETED)';
          case 'delivered':
            return 'ડિલિવર થઈ ગયું (DELIVERED)';
          case 'cannot_repair':
          case 'cannot repair':
          case 'unrepairable':
            return 'રિપેર થઈ શક્યું નથી (CANNOT REPAIR)';
          case 'cancelled':
            return 'રદ કરેલ છે (CANCELLED)';
          default:
            return status.toUpperCase();
        }
      case WhatsAppLanguage.english:
      default:
        return status.toUpperCase();
    }
  }

  /// Builds a formatted WhatsApp text message for a Repair job in English, Hindi, or Gujarati.
  static String buildRepairWhatsAppMessage(
    Repair repair, {
    String? shopName,
    WhatsAppLanguage language = WhatsAppLanguage.english,
  }) {
    final customerName = repair.customer?.name.trim().isNotEmpty == true
        ? repair.customer!.name.trim()
        : (language == WhatsAppLanguage.gujarati
            ? 'ગ્રાહક'
            : (language == WhatsAppLanguage.hindi ? 'ग्राहक' : 'Customer'));

    final effectiveShopName = shopName?.trim().isNotEmpty == true
        ? shopName!.trim()
        : 'Mobile Repair & Electronics Shop';

    final jobNum = repair.jobNumber.isNotEmpty ? repair.jobNumber : 'REP-${repair.id}';
    final dateStr = repair.dateReceived.isNotEmpty
        ? DateHelper.formatDate(repair.dateReceived)
        : DateHelper.formatDate(DateTime.now().toIso8601String());
    final deviceStr = '${repair.device?.brand ?? ''} ${repair.device?.model ?? ''}'.trim();
    final imeiStr = (repair.device?.imei1?.isNotEmpty == true)
        ? repair.device!.imei1
        : (repair.device?.serialNumber ?? '');
    final localizedStatus = getLocalizedStatus(repair.repairStatus, language);

    final sb = StringBuffer();

    switch (language) {
      case WhatsAppLanguage.hindi:
        sb.writeln('नमस्ते $customerName 👋');
        sb.writeln('');
        sb.writeln('अपने डिवाइस रिपेयर के लिए *$effectiveShopName* को चुनने के लिए धन्यवाद!');
        sb.writeln('');
        sb.writeln('🛠️ रिपेयर टिकट विवरण (REPAIR TICKET SUMMARY)');
        sb.writeln('* जॉब नंबर: #$jobNum');
        sb.writeln('* प्राप्ति दिनांक: $dateStr');
        if (repair.expectedDeliveryDate != null && repair.expectedDeliveryDate!.isNotEmpty) {
          sb.writeln('* संभावित डिलीवरी: ${DateHelper.formatDate(repair.expectedDeliveryDate!)}');
        }
        if (deviceStr.isNotEmpty) {
          sb.writeln('* डिवाइस: $deviceStr');
        }
        if (imeiStr != null && imeiStr.isNotEmpty) {
          sb.writeln('* IMEI / सीरियल: $imeiStr');
        }
        if (repair.pinPasscode != null && repair.pinPasscode!.isNotEmpty) {
          sb.writeln('* पासकोड / पिन: ${repair.pinPasscode}');
        }

        sb.writeln('* वर्तमान स्थिति: *$localizedStatus*');

        if (repair.problemDescription.isNotEmpty) {
          sb.writeln('');
          sb.writeln('📋 दर्ज कराई गई समस्याएं (REPORTED ISSUES):');
          sb.writeln('• ${repair.problemDescription}');
        }

        if (repair.deviceCondition.isNotEmpty || (repair.conditionNotes != null && repair.conditionNotes!.isNotEmpty)) {
          sb.writeln('');
          sb.writeln('📱 डिवाइस की स्थिति (DEVICE CONDITION):');
          if (repair.deviceCondition.isNotEmpty) {
            sb.writeln('• स्थिति: ${repair.deviceCondition.join(', ')}');
          }
          if (repair.conditionNotes != null && repair.conditionNotes!.isNotEmpty) {
            sb.writeln('• नोट्स: ${repair.conditionNotes}');
          }
        }

        if (repair.accessoriesReceived.isNotEmpty || (repair.accessoriesNotes != null && repair.accessoriesNotes!.isNotEmpty)) {
          sb.writeln('');
          sb.writeln('🔌 साथ में प्राप्त एक्सेसरीज (ACCESSORIES):');
          if (repair.accessoriesReceived.isNotEmpty) {
            sb.writeln('• एक्सेसरीज: ${repair.accessoriesReceived.join(', ')}');
          }
          if (repair.accessoriesNotes != null && repair.accessoriesNotes!.isNotEmpty) {
            sb.writeln('• नोट्स: ${repair.accessoriesNotes}');
          }
        }

        if (repair.technicianName != null && repair.technicianName!.isNotEmpty) {
          sb.writeln('');
          sb.writeln('👨‍🔧 नियुक्त तकनीशियन (TECHNICIAN):');
          sb.writeln('• ${repair.technicianName}');
        }

        if (repair.parts.isNotEmpty) {
          sb.writeln('');
          sb.writeln('⚙️ बदले गए पार्ट्स (PARTS & REPLACEMENTS):');
          for (var i = 0; i < repair.parts.length; i++) {
            final p = repair.parts[i];
            sb.writeln('  ${i + 1}. ${p.partName} x ${p.quantity} - ₹${(p.quantity * p.sellingPrice).toStringAsFixed(2)}');
          }
        }

        if (repair.customerNotes != null && repair.customerNotes!.trim().isNotEmpty) {
          sb.writeln('');
          sb.writeln('💬 ग्राहक नोट्स: ${repair.customerNotes!.trim()}');
        }
        if (repair.internalNotes != null && repair.internalNotes!.trim().isNotEmpty) {
          sb.writeln('');
          sb.writeln('📝 स्टेटस नोट्स: ${repair.internalNotes!.trim()}');
        }

        sb.writeln('');
        sb.writeln('💳 भुगतान विवरण (PAYMENT BREAKDOWN)');
        if (repair.estimatedCost > 0) {
          sb.writeln('* अनुमानित लागत: ₹${repair.estimatedCost.toStringAsFixed(2)}');
        }
        sb.writeln('* कुल बिल राशि: ₹${repair.netCost.toStringAsFixed(2)}');
        sb.writeln('* जमा राशि / एडवांस: ₹${repair.amountPaid.toStringAsFixed(2)}');
        if (repair.amountDue > 0) {
          sb.writeln('* बकाया राशि: ₹${repair.amountDue.toStringAsFixed(2)} ⚠️');
        } else {
          sb.writeln('* भुगतान स्थिति: पूरा भुगतान प्राप्त ✅ (PAID IN FULL)');
        }

        if (repair.warranty != null) {
          sb.writeln('');
          sb.writeln('🛡️ वारंटी विवरण (WARRANTY COVERAGE):');
          sb.writeln('* वारंटी नंबर: ${repair.warranty!.warrantyNumber}');
          sb.writeln('* वैध तिथि: ${DateHelper.formatDate(repair.warranty!.warrantyEndDate)} (${repair.warranty!.daysRemaining} दिन)');
        }

        sb.writeln('');
        sb.writeln('आपके विश्वास के लिए धन्यवाद! हम आपको काम की प्रगति से अवगत कराते रहेंगे। 🤝✨');
        break;

      case WhatsAppLanguage.gujarati:
        sb.writeln('નમસ્તે $customerName 👋');
        sb.writeln('');
        sb.writeln('તમારા ડિવાઇસ રિપેરિંગ માટે *$effectiveShopName* પસંદ કરવા બદલ આભાર!');
        sb.writeln('');
        sb.writeln('🛠️ રિપેરિંગ ટિકિટ વિગતો (REPAIR TICKET SUMMARY)');
        sb.writeln('* જોબ નંબર: #$jobNum');
        sb.writeln('* સ્વીકાર તારીખ: $dateStr');
        if (repair.expectedDeliveryDate != null && repair.expectedDeliveryDate!.isNotEmpty) {
          sb.writeln('* અપેક્ષિત ડિલિવરી: ${DateHelper.formatDate(repair.expectedDeliveryDate!)}');
        }
        if (deviceStr.isNotEmpty) {
          sb.writeln('* ડિવાઇસ: $deviceStr');
        }
        if (imeiStr != null && imeiStr.isNotEmpty) {
          sb.writeln('* IMEI / સિરિયલ: $imeiStr');
        }
        if (repair.pinPasscode != null && repair.pinPasscode!.isNotEmpty) {
          sb.writeln('* પાસકોડ / PIN: ${repair.pinPasscode}');
        }

        sb.writeln('* વર્તમાન સ્થિતિ: *$localizedStatus*');

        if (repair.problemDescription.isNotEmpty) {
          sb.writeln('');
          sb.writeln('📋 નોંધાયેલ સમસ્યાઓ / ખામીઓ (REPORTED ISSUES):');
          sb.writeln('• ${repair.problemDescription}');
        }

        if (repair.deviceCondition.isNotEmpty || (repair.conditionNotes != null && repair.conditionNotes!.isNotEmpty)) {
          sb.writeln('');
          sb.writeln('📱 ડિવાઇસની હાલત (DEVICE CONDITION):');
          if (repair.deviceCondition.isNotEmpty) {
            sb.writeln('• સ્થિતિ: ${repair.deviceCondition.join(', ')}');
          }
          if (repair.conditionNotes != null && repair.conditionNotes!.isNotEmpty) {
            sb.writeln('• નોંધ: ${repair.conditionNotes}');
          }
        }

        if (repair.accessoriesReceived.isNotEmpty || (repair.accessoriesNotes != null && repair.accessoriesNotes!.isNotEmpty)) {
          sb.writeln('');
          sb.writeln('🔌 સાથે મળેલ સાધનો (ACCESSORIES):');
          if (repair.accessoriesReceived.isNotEmpty) {
            sb.writeln('• સાધનો: ${repair.accessoriesReceived.join(', ')}');
          }
          if (repair.accessoriesNotes != null && repair.accessoriesNotes!.isNotEmpty) {
            sb.writeln('• નોંધ: ${repair.accessoriesNotes}');
          }
        }

        if (repair.technicianName != null && repair.technicianName!.isNotEmpty) {
          sb.writeln('');
          sb.writeln('👨‍🔧 ફાળવેલ ટેકનિશિયન (TECHNICIAN):');
          sb.writeln('• ${repair.technicianName}');
        }

        if (repair.parts.isNotEmpty) {
          sb.writeln('');
          sb.writeln('⚙️ પાર્ટ્સ અને સર્વિસ (PARTS & REPLACEMENTS):');
          for (var i = 0; i < repair.parts.length; i++) {
            final p = repair.parts[i];
            sb.writeln('  ${i + 1}. ${p.partName} x ${p.quantity} - ₹${(p.quantity * p.sellingPrice).toStringAsFixed(2)}');
          }
        }

        if (repair.customerNotes != null && repair.customerNotes!.trim().isNotEmpty) {
          sb.writeln('');
          sb.writeln('💬 ગ્રાહકની નોંધ: ${repair.customerNotes!.trim()}');
        }
        if (repair.internalNotes != null && repair.internalNotes!.trim().isNotEmpty) {
          sb.writeln('');
          sb.writeln('📝 સ્ટેટસ નોંધ: ${repair.internalNotes!.trim()}');
        }

        sb.writeln('');
        sb.writeln('💳 પેમેન્ટ વિગતો (PAYMENT BREAKDOWN)');
        if (repair.estimatedCost > 0) {
          sb.writeln('* અંદાજિત રકમ: ₹${repair.estimatedCost.toStringAsFixed(2)}');
        }
        sb.writeln('* કુલ ચોખ્ખી રકમ: ₹${repair.netCost.toStringAsFixed(2)}');
        sb.writeln('* એડવાન્સ / જમા રકમ: ₹${repair.amountPaid.toStringAsFixed(2)}');
        if (repair.amountDue > 0) {
          sb.writeln('* બાકી રકમ: ₹${repair.amountDue.toStringAsFixed(2)} ⚠️');
        } else {
          sb.writeln('* પેમેન્ટ સ્થિતિ: પૂરેપૂરું ચૂકવાઈ ગયેલ છે ✅ (PAID IN FULL)');
        }

        if (repair.warranty != null) {
          sb.writeln('');
          sb.writeln('🛡️ વોરંટી વિગતો (WARRANTY COVERAGE):');
          sb.writeln('* વોરંટી નંબર: ${repair.warranty!.warrantyNumber}');
          sb.writeln('* માન્ય તારીખ: ${DateHelper.formatDate(repair.warranty!.warrantyEndDate)} (${repair.warranty!.daysRemaining} દિવસ)');
        }

        sb.writeln('');
        sb.writeln('તમારા વિશ્વાસ બદલ ખૂબ ખૂબ આભાર! અમે તમને કામની પ્રગતિ જણાવતા રહીશું. 🤝✨');
        break;

      case WhatsAppLanguage.english:
      default:
        sb.writeln('Hello $customerName 👋');
        sb.writeln('');
        sb.writeln('Thank you for choosing *$effectiveShopName* for your device repair!');
        sb.writeln('');
        sb.writeln('🛠️ REPAIR TICKET SUMMARY');
        sb.writeln('* Job No: #$jobNum');
        sb.writeln('* Date Received: $dateStr');
        if (repair.expectedDeliveryDate != null && repair.expectedDeliveryDate!.isNotEmpty) {
          sb.writeln('* Expected Delivery: ${DateHelper.formatDate(repair.expectedDeliveryDate!)}');
        }
        if (deviceStr.isNotEmpty) {
          sb.writeln('* Device: $deviceStr');
        }
        if (imeiStr != null && imeiStr.isNotEmpty) {
          sb.writeln('* IMEI / Serial: $imeiStr');
        }
        if (repair.pinPasscode != null && repair.pinPasscode!.isNotEmpty) {
          sb.writeln('* Passcode / PIN: ${repair.pinPasscode}');
        }

        sb.writeln('* Current Status: *${repair.repairStatus.toUpperCase()}*');

        if (repair.problemDescription.isNotEmpty) {
          sb.writeln('');
          sb.writeln('📋 REPORTED ISSUES / PROBLEMS:');
          sb.writeln('• ${repair.problemDescription}');
        }

        if (repair.deviceCondition.isNotEmpty || (repair.conditionNotes != null && repair.conditionNotes!.isNotEmpty)) {
          sb.writeln('');
          sb.writeln('📱 DEVICE CONDITION:');
          if (repair.deviceCondition.isNotEmpty) {
            sb.writeln('• Condition: ${repair.deviceCondition.join(', ')}');
          }
          if (repair.conditionNotes != null && repair.conditionNotes!.isNotEmpty) {
            sb.writeln('• Notes: ${repair.conditionNotes}');
          }
        }

        if (repair.accessoriesReceived.isNotEmpty || (repair.accessoriesNotes != null && repair.accessoriesNotes!.isNotEmpty)) {
          sb.writeln('');
          sb.writeln('🔌 ACCESSORIES RECEIVED:');
          if (repair.accessoriesReceived.isNotEmpty) {
            sb.writeln('• Accessories: ${repair.accessoriesReceived.join(', ')}');
          }
          if (repair.accessoriesNotes != null && repair.accessoriesNotes!.isNotEmpty) {
            sb.writeln('• Notes: ${repair.accessoriesNotes}');
          }
        }

        if (repair.technicianName != null && repair.technicianName!.isNotEmpty) {
          sb.writeln('');
          sb.writeln('👨‍🔧 ASSIGNED TECHNICIAN:');
          sb.writeln('• ${repair.technicianName}');
        }

        if (repair.parts.isNotEmpty) {
          sb.writeln('');
          sb.writeln('⚙️ PARTS & REPLACEMENTS:');
          for (var i = 0; i < repair.parts.length; i++) {
            final p = repair.parts[i];
            sb.writeln('  ${i + 1}. ${p.partName} x ${p.quantity} - ₹${(p.quantity * p.sellingPrice).toStringAsFixed(2)}');
          }
        }

        if (repair.customerNotes != null && repair.customerNotes!.trim().isNotEmpty) {
          sb.writeln('');
          sb.writeln('💬 Customer Notes: ${repair.customerNotes!.trim()}');
        }
        if (repair.internalNotes != null && repair.internalNotes!.trim().isNotEmpty) {
          sb.writeln('');
          sb.writeln('📝 Internal / Status Notes: ${repair.internalNotes!.trim()}');
        }

        sb.writeln('');
        sb.writeln('💳 PAYMENT BREAKDOWN');
        if (repair.estimatedCost > 0) {
          sb.writeln('* Estimated Cost: ₹${repair.estimatedCost.toStringAsFixed(2)}');
        }
        sb.writeln('* Total Net Cost: ₹${repair.netCost.toStringAsFixed(2)}');
        sb.writeln('* Advance / Amount Paid: ₹${repair.amountPaid.toStringAsFixed(2)}');
        if (repair.amountDue > 0) {
          sb.writeln('* Balance Due: ₹${repair.amountDue.toStringAsFixed(2)} ⚠️');
        } else {
          sb.writeln('* Status: PAID IN FULL ✅');
        }

        if (repair.warranty != null) {
          sb.writeln('');
          sb.writeln('🛡️ WARRANTY COVERAGE:');
          sb.writeln('* Warranty No: ${repair.warranty!.warrantyNumber}');
          sb.writeln('* Valid Until: ${DateHelper.formatDate(repair.warranty!.warrantyEndDate)} (${repair.warranty!.daysRemaining} Days)');
        }

        sb.writeln('');
        sb.writeln('Thank you for your trust! We will keep you updated on the repair progress. 🤝✨');
        break;
    }

    return sb.toString();
  }

  /// Sends a direct or shareable WhatsApp message for a Repair ticket.
  static Future<bool> sendRepairWhatsAppMessage(
    BuildContext context,
    Repair repair, {
    String? shopName,
    WhatsAppLanguage? language,
  }) async {
    final rawPhone = repair.customer?.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);

    final lang = language ?? WhatsAppLanguage.fromCode(await PreferencesStorage().getWhatsAppLanguage());

    String? dynamicShopName = shopName;
    if (dynamicShopName == null || dynamicShopName.trim().isEmpty) {
      try {
        final shop = await AuthStorage().getShop();
        if (shop != null && shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
          dynamicShopName = shop['name'].toString().trim();
        }
      } catch (_) {}
    }

    final message = buildRepairWhatsAppMessage(repair, shopName: dynamicShopName, language: lang);
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

  /// Builds a formatted WhatsApp status update message in English, Hindi, or Gujarati.
  static String buildRepairStatusWhatsAppMessage(
    Repair repair,
    String? newStatus, {
    String? statusNotes,
    String? shopName,
    WhatsAppLanguage language = WhatsAppLanguage.english,
  }) {
    final statusToReport = newStatus ?? repair.repairStatus;
    final customerName = repair.customer?.name.trim().isNotEmpty == true
        ? repair.customer!.name.trim()
        : (language == WhatsAppLanguage.gujarati
            ? 'ગ્રાહક'
            : (language == WhatsAppLanguage.hindi ? 'ग्राहक' : 'Customer'));

    final effectiveShopName = shopName?.trim().isNotEmpty == true
        ? shopName!.trim()
        : 'Mobile Repair & Electronics Shop';

    final jobNum = repair.jobNumber.isNotEmpty ? repair.jobNumber : 'REP-${repair.id}';
    final deviceStr = '${repair.device?.brand ?? ''} ${repair.device?.model ?? ''}'.trim();
    final localizedStatus = getLocalizedStatus(statusToReport, language);
    final isReadyOrCompleted = statusToReport.toLowerCase() == 'completed' || statusToReport.toLowerCase() == 'ready';

    final sb = StringBuffer();

    switch (language) {
      case WhatsAppLanguage.hindi:
        sb.writeln('नमस्ते $customerName 👋');
        sb.writeln('');
        sb.writeln('*$effectiveShopName* की ओर से आपके रिपेयर जॉब *#$jobNum* ($deviceStr) का स्टेटस अपडेट:');
        sb.writeln('');
        sb.writeln('🔔 नई स्थिति: *$localizedStatus*');
        if (statusNotes != null && statusNotes.trim().isNotEmpty) {
          sb.writeln('📝 विवरण / नोट्स: ${statusNotes.trim()}');
        }
        if (isReadyOrCompleted) {
          sb.writeln('🎉 आपका डिवाइस रिपेयर हो चुका है और डिलीवरी के लिए तैयार है!');
          if (repair.amountDue > 0) {
            sb.writeln('* बकाया राशि: ₹${repair.amountDue.toStringAsFixed(2)}');
          }
        }
        sb.writeln('');
        sb.writeln('आपके धैर्य और सहयोग के लिए धन्यवाद! 🤝✨');
        break;

      case WhatsAppLanguage.gujarati:
        sb.writeln('નમસ્તે $customerName 👋');
        sb.writeln('');
        sb.writeln('*$effectiveShopName* તરફથી તમારા રિપેર જોબ *#$jobNum* ($deviceStr) અંગેનું સ્ટેટસ અપડેટ:');
        sb.writeln('');
        sb.writeln('🔔 નવી સ્થિતિ: *$localizedStatus*');
        if (statusNotes != null && statusNotes.trim().isNotEmpty) {
          sb.writeln('📝 વિગતો / નોંધ: ${statusNotes.trim()}');
        }
        if (isReadyOrCompleted) {
          sb.writeln('🎉 તમારું ડિવાઇસ રિપેર થઈ ગયું છે અને મેળવવા માટે તૈયાર છે!');
          if (repair.amountDue > 0) {
            sb.writeln('* બાકી ચૂકવવાપાત્ર રકમ: ₹${repair.amountDue.toStringAsFixed(2)}');
          }
        }
        sb.writeln('');
        sb.writeln('તમારી ધીરજ અને સાથ સહકાર બદલ આભાર! 🤝✨');
        break;

      case WhatsAppLanguage.english:
      default:
        sb.writeln('Hello $customerName 👋');
        sb.writeln('');
        sb.writeln('Update from *$effectiveShopName* regarding your repair job *#$jobNum* ($deviceStr):');
        sb.writeln('');
        sb.writeln('🔔 Status Updated To: *${statusToReport.toUpperCase()}*');
        if (statusNotes != null && statusNotes.trim().isNotEmpty) {
          sb.writeln('📝 Notes: ${statusNotes.trim()}');
        }
        if (isReadyOrCompleted) {
          sb.writeln('🎉 Your device is repaired and ready for pickup!');
          if (repair.amountDue > 0) {
            sb.writeln('* Remaining Balance: ₹${repair.amountDue.toStringAsFixed(2)}');
          }
        }
        sb.writeln('');
        sb.writeln('Thank you for your patience! 🤝✨');
        break;
    }

    return sb.toString();
  }

  /// Sends status update message on WhatsApp for a Repair job.
  static Future<bool> sendRepairStatusWhatsAppMessage(
    BuildContext context,
    Repair repair,
    String? newStatus, {
    String? statusNotes,
    WhatsAppLanguage? language,
  }) async {
    final lang = language ?? WhatsAppLanguage.fromCode(await PreferencesStorage().getWhatsAppLanguage());
    final rawPhone = repair.customer?.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);

    String shopName = 'Mobile Repair & Electronics Shop';
    try {
      final shop = await AuthStorage().getShop();
      if (shop != null && shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
        shopName = shop['name'].toString().trim();
      }
    } catch (_) {}

    final message = buildRepairStatusWhatsAppMessage(
      repair,
      newStatus,
      statusNotes: statusNotes,
      shopName: shopName,
      language: lang,
    );
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

  /// Prompts user after repair creation to optionally send WhatsApp notification with language selector.
  static Future<void> showWhatsAppPromptDialog(BuildContext context, Repair repair) async {
    final phone = repair.customer?.mobile;
    if (phone == null || phone.trim().isEmpty) return;

    final customerName = repair.customer?.name ?? 'Customer';
    final initialLangCode = await PreferencesStorage().getWhatsAppLanguage();
    var selectedLang = WhatsAppLanguage.fromCode(initialLangCode);

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              WhatsAppIcon(size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text('Send WhatsApp Update?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Would you like to send repair job details to $customerName ($phone) on WhatsApp?'),
              const SizedBox(height: 14),
              WhatsAppLanguageSelector(
                compact: true,
                selectedLanguage: selectedLang,
                onLanguageChanged: (lang) {
                  setDialogState(() {
                    selectedLang = lang;
                  });
                  PreferencesStorage().saveWhatsAppLanguage(lang.code);
                },
              ),
            ],
          ),
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
      ),
    );

    if (result == true && context.mounted) {
      await sendRepairWhatsAppMessage(context, repair, language: selectedLang);
    }
  }

  /// Helper: Shares the Repair PDF Job Sheet / Ticket File with localized summary text
  static Future<bool> shareRepairPdfInvoice(
    BuildContext context,
    Repair repair, {
    String? shopName,
    WhatsAppLanguage? language,
  }) async {
    try {
      final lang = language ?? WhatsAppLanguage.fromCode(await PreferencesStorage().getWhatsAppLanguage());

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

      final messageText = buildRepairWhatsAppMessage(repair, shopName: dynamicShopName, language: lang);

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

  /// Shows a modal bottom sheet allowing user to select WhatsApp message type & language:
  /// 1. Language selector (English, Hindi, Gujarati)
  /// 2. Share Repair PDF Bill File
  /// 3. Status Update Text
  /// 4. Complete Ticket Text Summary
  static Future<void> showRepairWhatsAppOptions(BuildContext context, Repair repair) async {
    final rawPhone = repair.customer?.mobile;
    final customerName = repair.customer?.name.trim().isNotEmpty == true
        ? repair.customer!.name.trim()
        : 'Customer';

    final initialLangCode = await PreferencesStorage().getWhatsAppLanguage();
    var currentLang = WhatsAppLanguage.fromCode(initialLangCode);

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final localizedStatus = getLocalizedStatus(repair.repairStatus, currentLang);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: SingleChildScrollView(
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
                      const SizedBox(height: 12),

                      // Language Selector
                      WhatsAppLanguageSelector(
                        selectedLanguage: currentLang,
                        onLanguageChanged: (newLang) {
                          setModalState(() {
                            currentLang = newLang;
                          });
                          PreferencesStorage().saveWhatsAppLanguage(newLang.code);
                        },
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

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
                        subtitle: Text('Attaches PDF + ${currentLang.label} summary on WhatsApp'),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await shareRepairPdfInvoice(context, repair, language: currentLang);
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
                        subtitle: Text('Status: $localizedStatus (${currentLang.label})'),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await sendRepairStatusWhatsAppMessage(
                            context,
                            repair,
                            repair.repairStatus,
                            language: currentLang,
                          );
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
                        subtitle: Text('Send full ticket summary in ${currentLang.label}'),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await sendRepairWhatsAppMessage(context, repair, language: currentLang);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // WARRANTY WHATSAPP METHODS
  // ==========================================

  static String getWarrantyStatusText(String status, WhatsAppLanguage lang) {
    final s = status.trim().toLowerCase();
    switch (lang) {
      case WhatsAppLanguage.hindi:
        switch (s) {
          case 'active':
            return 'सक्रिय (ACTIVE)';
          case 'expiring_soon':
            return 'जल्द समाप्त होने वाली (EXPIRING SOON)';
          case 'expired':
            return 'समाप्त (EXPIRED)';
          case 'voided':
            return 'अमान्य / रद्द (VOIDED)';
          default:
            return status.toUpperCase();
        }
      case WhatsAppLanguage.gujarati:
        switch (s) {
          case 'active':
            return 'સક્રિય છે (ACTIVE)';
          case 'expiring_soon':
            return 'ટૂંક સમયમાં સમાપ્ત (EXPIRING SOON)';
          case 'expired':
            return 'મુદ્દત પૂરી થઈ ગઈ (EXPIRED)';
          case 'voided':
            return 'રદ કરેલ (VOIDED)';
          default:
            return status.toUpperCase();
        }
      case WhatsAppLanguage.english:
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Builds a formatted WhatsApp text message for Warranty in English, Hindi, or Gujarati.
  static String buildWarrantyWhatsAppMessage(
    Warranty warranty, {
    String? shopName,
    WhatsAppLanguage language = WhatsAppLanguage.english,
  }) {
    final customerName = warranty.customer?.name.trim().isNotEmpty == true
        ? warranty.customer!.name.trim()
        : (language == WhatsAppLanguage.gujarati
            ? 'ગ્રાહક'
            : (language == WhatsAppLanguage.hindi ? 'ग्राहक' : 'Customer'));

    final effectiveShopName = shopName?.trim().isNotEmpty == true
        ? shopName!.trim()
        : 'Mobile Repair & Electronics Shop';

    final deviceStr = warranty.device != null
        ? '${warranty.device!.brand} ${warranty.device!.model}'.trim()
        : '';
    final imeiStr = (warranty.device?.imei1?.isNotEmpty == true)
        ? warranty.device!.imei1
        : (warranty.device?.serialNumber ?? '');
    final startStr = DateHelper.formatDate(warranty.warrantyStartDate);
    final endStr = DateHelper.formatDate(warranty.warrantyEndDate);
    final statusStr = getWarrantyStatusText(warranty.status, language);

    final sb = StringBuffer();

    switch (language) {
      case WhatsAppLanguage.hindi:
        sb.writeln('नमस्ते $customerName 👋');
        sb.writeln('');
        sb.writeln('*$effectiveShopName* पर भरोसा करने के लिए धन्यवाद! 🛡️✨');
        sb.writeln('');
        sb.writeln('🛡️ वारंटी विवरण (WARRANTY CERTIFICATE)');
        sb.writeln('* वारंटी नंबर: #${warranty.warrantyNumber}');
        sb.writeln('* प्रकार: ${warranty.warrantyType == 'sale' ? 'उत्पाद बिक्री वारंटी (SALE)' : 'रिपेयर सेवा वारंटी (REPAIR)'}');
        if (deviceStr.isNotEmpty) {
          sb.writeln('* डिवाइस: $deviceStr');
        }
        if (imeiStr != null && imeiStr.isNotEmpty) {
          sb.writeln('* IMEI / सीरियल: $imeiStr');
        }
        sb.writeln('* वारंटी अवधि: $startStr से $endStr (${warranty.durationDays} दिन)');
        sb.writeln('* वर्तमान स्थिति: *$statusStr*');
        sb.writeln('* शेष दिन: ${warranty.daysRemaining} दिन');

        if (warranty.warrantyTerms != null && warranty.warrantyTerms!.trim().isNotEmpty) {
          sb.writeln('');
          sb.writeln('📋 वारंटी नियम व शर्तें (TERMS & CONDITIONS):');
          sb.writeln('• ${warranty.warrantyTerms!.trim()}');
        }

        sb.writeln('');
        sb.writeln('किसी भी सहायता या क्लेम के लिए, कृपया इस वारंटी नंबर के साथ हमसे संपर्क करें। 🤝✨');
        break;

      case WhatsAppLanguage.gujarati:
        sb.writeln('નમસ્તે $customerName 👋');
        sb.writeln('');
        sb.writeln('*$effectiveShopName* પર વિશ્વાસ મૂકવા બદલ આપનો આભાર! 🛡️✨');
        sb.writeln('');
        sb.writeln('🛡️ વોરંટી વિગતો (WARRANTY CERTIFICATE)');
        sb.writeln('* વોરંટી નંબર: #${warranty.warrantyNumber}');
        sb.writeln('* પ્રકાર: ${warranty.warrantyType == 'sale' ? 'વેચાણ વોરંટી (SALE)' : 'રિપેરિંગ સર્વિસ વોરંટી (REPAIR)'}');
        if (deviceStr.isNotEmpty) {
          sb.writeln('* ડિવાઇસ: $deviceStr');
        }
        if (imeiStr != null && imeiStr.isNotEmpty) {
          sb.writeln('* IMEI / સિરિયલ: $imeiStr');
        }
        sb.writeln('* વોરંટી સમયગાળો: $startStr થી $endStr (${warranty.durationDays} દિવસ)');
        sb.writeln('* વર્તમાન સ્થિતિ: *$statusStr*');
        sb.writeln('* બાકી દિવસો: ${warranty.daysRemaining} દિવસ');

        if (warranty.warrantyTerms != null && warranty.warrantyTerms!.trim().isNotEmpty) {
          sb.writeln('');
          sb.writeln('📋 વોરંટી શરતો અને નિયમો:');
          sb.writeln('• ${warranty.warrantyTerms!.trim()}');
        }

        sb.writeln('');
        sb.writeln('કોઈપણ ક્લેઇમ અથવા સહાય માટે, કૃપા કરીને વોરંટી નંબર સાથે અમારો સંપર્ક કરો. 🤝✨');
        break;

      case WhatsAppLanguage.english:
      default:
        sb.writeln('Hello $customerName 👋');
        sb.writeln('');
        sb.writeln('Thank you for trusting *$effectiveShopName*! 🛡️✨');
        sb.writeln('');
        sb.writeln('🛡️ WARRANTY CERTIFICATE DETAILS');
        sb.writeln('* Warranty No: #${warranty.warrantyNumber}');
        sb.writeln('* Warranty Type: ${warranty.warrantyType.toUpperCase()}');
        if (deviceStr.isNotEmpty) {
          sb.writeln('* Device: $deviceStr');
        }
        if (imeiStr != null && imeiStr.isNotEmpty) {
          sb.writeln('* IMEI / Serial: $imeiStr');
        }
        sb.writeln('* Period: $startStr to $endStr (${warranty.durationDays} Days)');
        sb.writeln('* Current Status: *$statusStr*');
        sb.writeln('* Days Remaining: ${warranty.daysRemaining} Days');

        if (warranty.warrantyTerms != null && warranty.warrantyTerms!.trim().isNotEmpty) {
          sb.writeln('');
          sb.writeln('📋 WARRANTY TERMS & CONDITIONS:');
          sb.writeln('• ${warranty.warrantyTerms!.trim()}');
        }

        sb.writeln('');
        sb.writeln('For any claims or questions, feel free to reach out to us with your Warranty Number! 🤝✨');
        break;
    }

    return sb.toString();
  }

  /// Sends Warranty Certificate WhatsApp message with language support.
  static Future<bool> sendWarrantyWhatsAppMessage(
    BuildContext context,
    Warranty warranty, {
    String? shopName,
    WhatsAppLanguage? language,
  }) async {
    final rawPhone = warranty.customer?.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);

    final lang = language ?? WhatsAppLanguage.fromCode(await PreferencesStorage().getWhatsAppLanguage());

    String? dynamicShopName = shopName;
    if (dynamicShopName == null || dynamicShopName.trim().isEmpty) {
      try {
        final shop = await AuthStorage().getShop();
        if (shop != null && shop['name'] != null && shop['name'].toString().trim().isNotEmpty) {
          dynamicShopName = shop['name'].toString().trim();
        }
      } catch (_) {}
    }

    final message = buildWarrantyWhatsAppMessage(warranty, shopName: dynamicShopName, language: lang);
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
      await Share.share(message, subject: 'Warranty Certificate #${warranty.warrantyNumber}');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Shows modal bottom sheet for Warranty WhatsApp options with language selection.
  static Future<void> showWarrantyWhatsAppOptions(BuildContext context, Warranty warranty) async {
    final rawPhone = warranty.customer?.mobile;
    final customerName = warranty.customer?.name.trim().isNotEmpty == true
        ? warranty.customer!.name.trim()
        : 'Customer';

    final initialLangCode = await PreferencesStorage().getWhatsAppLanguage();
    var currentLang = WhatsAppLanguage.fromCode(initialLangCode);

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: SingleChildScrollView(
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
                                  'Warranty WhatsApp Options',
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
                      const SizedBox(height: 12),

                      // Language Selector
                      WhatsAppLanguageSelector(
                        selectedLanguage: currentLang,
                        onLanguageChanged: (newLang) {
                          setModalState(() {
                            currentLang = newLang;
                          });
                          PreferencesStorage().saveWhatsAppLanguage(newLang.code);
                        },
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

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
                        title: const Text('Send Warranty Certificate Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Send warranty coverage details in ${currentLang.label}'),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await sendWarrantyWhatsAppMessage(context, warranty, language: currentLang);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // CUSTOMER GREETING / CONTACT WHATSAPP METHODS
  // ==========================================

  static String buildCustomerGreetingWhatsAppMessage(
    Customer customer, {
    String? shopName,
    WhatsAppLanguage language = WhatsAppLanguage.english,
  }) {
    final effectiveShopName = shopName?.trim().isNotEmpty == true
        ? shopName!.trim()
        : 'Mobile Repair & Electronics Shop';

    switch (language) {
      case WhatsAppLanguage.hindi:
        return 'नमस्ते ${customer.name} 👋\n\n*$effectiveShopName* की ओर से सादर नमस्कार! 🤝✨\nहमारे सम्मानित ग्राहक होने के लिए धन्यवाद। यदि आपको मोबाइल रिपेयर, बिक्री, नए एक्सेसरीज या वारंटी सेवाओं के संबंध में किसी भी सहायता की आवश्यकता हो, तो बेझिझक हमें यहाँ मैसेज करें!\n\nआपका दिन शुभ हो! 🌟';
      case WhatsAppLanguage.gujarati:
        return 'નમસ્તે ${customer.name} 👋\n\n*$effectiveShopName* તરફથી નમસ્કાર! 🤝✨\nઅમારા ગ્રાહક બનવા બદલ ખૂબ ખૂબ આભાર. જો આપને મોબાઇલ રિપેરિંગ, વેચાણ, એક્સેસરીઝ કે વોરંટી સેવાઓ અંગે કોઈ પણ જરૂર હોય, તો આપ અમને અહીં ગમે ત્યારે સંપર્ક કરી શકો છો!\n\nઆપનો દિવસ શુભ રહે! 🌟';
      case WhatsAppLanguage.english:
      default:
        return 'Hello ${customer.name} 👋\n\nGreetings from *$effectiveShopName*! 🤝✨\nThank you for being our valued customer. If you need any assistance with mobile phone repairs, sales, accessories, or warranty services, feel free to message us here anytime!\n\nHave a wonderful day! 🌟';
    }
  }

  static Future<void> showCustomerWhatsAppOptions(BuildContext context, Customer customer) async {
    final rawPhone = customer.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);

    final initialLangCode = await PreferencesStorage().getWhatsAppLanguage();
    var currentLang = WhatsAppLanguage.fromCode(initialLangCode);

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: SingleChildScrollView(
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
                                  'Customer WhatsApp Chat',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${customer.name} ($rawPhone)',
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
                      const SizedBox(height: 12),

                      // Language Selector
                      WhatsAppLanguageSelector(
                        selectedLanguage: currentLang,
                        onLanguageChanged: (newLang) {
                          setModalState(() {
                            currentLang = newLang;
                          });
                          PreferencesStorage().saveWhatsAppLanguage(newLang.code);
                        },
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

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
                        title: const Text('Send Greeting / Welcome Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Send personalized greeting in ${currentLang.label}'),
                        onTap: () async {
                          Navigator.pop(ctx);
                          String? shopName;
                          try {
                            final shop = await AuthStorage().getShop();
                            if (shop != null && shop['name'] != null) {
                              shopName = shop['name'].toString().trim();
                            }
                          } catch (_) {}

                          final msg = buildCustomerGreetingWhatsAppMessage(customer, shopName: shopName, language: currentLang);
                          if (formattedPhone != null) {
                            final encoded = Uri.encodeComponent(msg);
                            final uri = Uri.parse('whatsapp://send?phone=$formattedPhone&text=$encoded');
                            final wameUri = Uri.parse('https://wa.me/$formattedPhone?text=$encoded');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else if (await canLaunchUrl(wameUri)) {
                              await launchUrl(wameUri, mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

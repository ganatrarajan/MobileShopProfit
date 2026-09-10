import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/repair/models/repair.dart';
import '../storage/auth_storage.dart';
import '../widgets/whatsapp_icon.dart';

class WhatsAppHelper {
  static const Map<String, String> _statusLabels = {
    'received': 'Received',
    'diagnosing': 'Diagnosing / In Inspection',
    'waiting_customer': 'Waiting Customer Approval',
    'waiting_parts': 'Waiting for Parts',
    'repairing': 'Under Repair',
    'ready': 'Ready for Pickup',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  /// Formats raw phone number for WhatsApp wa.me link.
  /// Handles Indian numbers (10 digits -> prepends 91, 11 digits starting with 0 -> strips 0 and prepends 91).
  /// Strips all non-digit characters (+, -, spaces, brackets).
  static String? formatPhoneNumber(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return null;
    String digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.length == 10) return '91$digits';
    if (digits.length == 11 && digits.startsWith('0')) return '91${digits.substring(1)}';
    if (digits.length == 12 && digits.startsWith('91')) return digits;
    if (digits.length >= 10) return digits;
    return null;
  }

  /// Premium professional registration message template.
  static String buildRepairCreatedMessage(Repair repair, {String? shopName}) {
    final customerName = repair.customer?.name.trim().isNotEmpty == true
        ? repair.customer!.name.trim()
        : 'Customer';

    final effectiveShopName = shopName?.trim().isNotEmpty == true
        ? shopName!.trim()
        : 'Mobile Repair Shop';

    final jobCardNumber = repair.jobNumber.isNotEmpty ? repair.jobNumber : 'JOB-${repair.id}';

    String deviceName = 'Device';
    if (repair.device != null) {
      final brand = repair.device!.brand.trim();
      final model = repair.device!.model.trim();
      if (brand.isNotEmpty || model.isNotEmpty) {
        deviceName = '$brand $model'.trim();
      }
    }

    final amountVal = repair.netCost > 0 ? repair.netCost : repair.estimatedCost;
    final amountFormatted = amountVal % 1 == 0
        ? amountVal.toInt().toString()
        : amountVal.toStringAsFixed(2);

    return 'Hello $customerName 👋\n\n'
        'Thank you for choosing *$effectiveShopName*! 📍\n\n'
        '📋 *Job Card:* #$jobCardNumber\n'
        '📱 *Device:* $deviceName\n'
        '💰 *Est. Amount:* \u20B9$amountFormatted\n\n'
        '🔧 Your repair is registered. We will notify you as work progresses.\n\n'
        'Thank you for your trust! 🤝';
  }

  /// Premium professional status update message template.
  static String buildRepairStatusMessage(
    Repair repair,
    String statusKey, {
    String? statusNotes,
    String? shopName,
  }) {
    final customerName = repair.customer?.name.trim().isNotEmpty == true
        ? repair.customer!.name.trim()
        : 'Customer';

    final effectiveShopName = shopName?.trim().isNotEmpty == true
        ? shopName!.trim()
        : 'Mobile Repair Shop';

    final jobCardNumber = repair.jobNumber.isNotEmpty ? repair.jobNumber : 'JOB-${repair.id}';

    String deviceName = 'Device';
    if (repair.device != null) {
      final brand = repair.device!.brand.trim();
      final model = repair.device!.model.trim();
      if (brand.isNotEmpty || model.isNotEmpty) {
        deviceName = '$brand $model'.trim();
      }
    }

    final dueVal = repair.amountDue > 0 ? repair.amountDue : (repair.netCost > 0 ? repair.netCost : repair.estimatedCost);
    final dueFormatted = dueVal % 1 == 0
        ? dueVal.toInt().toString()
        : dueVal.toStringAsFixed(2);

    final statusLabel = _statusLabels[statusKey] ?? statusKey.toUpperCase();

    if (statusKey == 'ready') {
      return 'Hello $customerName 👋\n\n'
          'Great news from *$effectiveShopName*! 🎉\n\n'
          '📱 *Device:* $deviceName\n'
          '📋 *Job Card:* #$jobCardNumber\n'
          '✅ *Status:* READY FOR PICKUP\n'
          '💰 *Amount Payable:* \u20B9$dueFormatted\n\n'
          '📍 Please visit our shop to collect your device. Thank you! 🤝';
    } else if (statusKey == 'repairing' || statusKey == 'diagnosing') {
      return 'Hello $customerName 👋\n\n'
          'Repair update from *$effectiveShopName*:\n\n'
          '📱 *Device:* $deviceName\n'
          '📋 *Job Card:* #$jobCardNumber\n'
          '🔧 *Status:* $statusLabel\n\n'
          'We are working on your device and will notify you once ready! 📱✨';
    } else if (statusKey == 'delivered') {
      return 'Hello $customerName 👋\n\n'
          'Your device *$deviceName* (Job Card: #$jobCardNumber) has been delivered successfully! ✅\n\n'
          'Thank you for choosing *$effectiveShopName*. Have a great day! 🤝✨';
    } else if (statusKey == 'cancelled') {
      final notesText = statusNotes != null && statusNotes.trim().isNotEmpty ? ' (${statusNotes.trim()})' : '';
      return 'Hello $customerName 👋\n\n'
          'Job Card update from *$effectiveShopName*:\n\n'
          '📱 *Device:* $deviceName\n'
          '📋 *Job Card:* #$jobCardNumber\n'
          '⚠️ *Status:* Cancelled$notesText\n\n'
          'Please contact us or visit shop for details. Thank you! 🤝';
    } else {
      final notesText = statusNotes != null && statusNotes.trim().isNotEmpty ? ' (${statusNotes.trim()})' : '';
      return 'Hello $customerName 👋\n\n'
          'Job Card update from *$effectiveShopName*:\n\n'
          '📱 *Device:* $deviceName\n'
          '📋 *Job Card:* #$jobCardNumber\n'
          '🔧 *Status:* $statusLabel$notesText\n\n'
          'Thank you for your patience! 🤝';
    }
  }

  /// Opens WhatsApp with menu choice (Job Card Receipt vs Status Update) if repair status > received.
  static Future<bool> sendRepairWhatsAppMessage(
    BuildContext context,
    Repair repair, {
    String? shopName,
  }) async {
    if (repair.repairStatus != 'received') {
      final statusLabel = _statusLabels[repair.repairStatus] ?? repair.repairStatus.toUpperCase();
      
      final choice = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  WhatsAppIcon(size: 24),
                  SizedBox(width: 8),
                  Text('Send WhatsApp Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded, color: Colors.blue),
                title: const Text('Job Card Receipt Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Send initial registration details & job card #', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, 'created'),
              ),
              ListTile(
                leading: const Icon(Icons.published_with_changes_rounded, color: Color(0xFF25D366)),
                title: Text('Status Update Message ($statusLabel)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Notify customer that repair is $statusLabel', style: const TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, 'status'),
              ),
            ],
          ),
        ),
      );

      if (choice == 'status') {
        return sendRepairStatusWhatsAppMessage(context, repair, repair.repairStatus, shopName: shopName);
      } else if (choice != 'created') {
        return false;
      }
    }

    return _launchWhatsApp(
      context: context,
      repair: repair,
      messageBuilder: (sName) => buildRepairCreatedMessage(repair, shopName: sName),
      shopName: shopName,
    );
  }

  /// Opens WhatsApp with status update message.
  static Future<bool> sendRepairStatusWhatsAppMessage(
    BuildContext context,
    Repair repair,
    String statusKey, {
    String? statusNotes,
    String? shopName,
  }) async {
    return _launchWhatsApp(
      context: context,
      repair: repair,
      messageBuilder: (sName) => buildRepairStatusMessage(
        repair,
        statusKey,
        statusNotes: statusNotes,
        shopName: sName,
      ),
      shopName: shopName,
    );
  }

  static Future<bool> _launchWhatsApp({
    required BuildContext context,
    required Repair repair,
    required String Function(String? sName) messageBuilder,
    String? shopName,
  }) async {
    final rawPhone = repair.customer?.mobile;
    final formattedPhone = formatPhoneNumber(rawPhone);

    if (formattedPhone == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customer mobile number is required to send WhatsApp message.',
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
      return false;
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

    final message = messageBuilder(dynamicShopName);
    final encodedMessage = Uri.encodeComponent(message);
    final urlString = 'https://wa.me/$formattedPhone?text=$encodedMessage';
    final uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return false;
    }
  }
}
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ContactSupportDialog extends StatelessWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? shop;

  const ContactSupportDialog({super.key, this.user, this.shop});

  static const String supportEmail = 'support@mobileprofits.com';
  static const String supportPhone = '+91 98765 43210';
  static const String supportHours = 'Mon - Sat: 9:00 AM - 8:00 PM IST';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.headset_mic_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Text('Contact Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our Mobile Profits support team is available to assist you with any questions or technical help.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildContactTile(
              icon: Icons.email_rounded,
              title: 'Official Support Email',
              value: supportEmail,
            ),
            const SizedBox(height: 10),
            _buildContactTile(
              icon: Icons.phone_rounded,
              title: 'Support Helpline',
              value: supportPhone,
            ),
            const SizedBox(height: 10),
            _buildContactTile(
              icon: Icons.access_time_rounded,
              title: 'Working Hours',
              value: supportHours,
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(100, 40),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

class ContactSupportDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? shop;

  const ContactSupportDialog({super.key, this.user, this.shop});

  @override
  State<ContactSupportDialog> createState() => _ContactSupportDialogState();
}

class _ContactSupportDialogState extends State<ContactSupportDialog> {
  String _supportEmail = 'support@mobileprofits.com';
  String _supportPhone = '+91 98765 43210';
  String _supportHours = 'Mon - Sat: 9:00 AM - 8:00 PM IST';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContactInfo();
  }

  Future<void> _fetchContactInfo() async {
    try {
      final res = await ApiClient().get(ApiEndpoints.supportContactInfo);
      if (mounted && res.success && res.data != null) {
        final dynamic raw = res.data;
        final Map<String, dynamic> data = (raw is Map && raw.containsKey('data'))
            ? Map<String, dynamic>.from(raw['data'])
            : (raw is Map ? Map<String, dynamic>.from(raw) : {});

        setState(() {
          if (data['support_email'] != null && data['support_email'].toString().isNotEmpty) {
            _supportEmail = data['support_email'].toString();
          }
          if (data['support_phone'] != null && data['support_phone'].toString().isNotEmpty) {
            _supportPhone = data['support_phone'].toString();
          }
          if (data['support_hours'] != null && data['support_hours'].toString().isNotEmpty) {
            _supportHours = data['support_hours'].toString();
          }
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
              )
            else ...[
              _buildContactTile(
                icon: Icons.email_rounded,
                title: 'Official Support Email',
                value: _supportEmail,
              ),
              const SizedBox(height: 10),
              _buildContactTile(
                icon: Icons.phone_rounded,
                title: 'Support Helpline',
                value: _supportPhone,
              ),
              const SizedBox(height: 10),
              _buildContactTile(
                icon: Icons.access_time_rounded,
                title: 'Working Hours',
                value: _supportHours,
              ),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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

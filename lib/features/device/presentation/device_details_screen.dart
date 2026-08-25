import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/device_repository.dart';
import '../models/device.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final Device device;
  const DeviceDetailsScreen({super.key, required this.device});

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  late Device _currentDevice;
  final DeviceRepository _repository = DeviceRepository();

  @override
  void initState() {
    super.initState();
    _currentDevice = widget.device;
  }

  Future<void> _deleteDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete ${_currentDevice.brand} ${_currentDevice.model}?\n\nNote: Future repair & sales history linked to this device will be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _repository.deleteDevice(_currentDevice.id);
      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Device ${_currentDevice.brand} ${_currentDevice.model} deleted')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    }
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'laptop':
        return Icons.laptop_rounded;
      case 'tablet':
        return Icons.tablet_android_rounded;
      case 'mobile':
      default:
        return Icons.phone_iphone_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${_currentDevice.brand} ${_currentDevice.model}'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Device',
            onPressed: () async {
              final updated = await Navigator.pushNamed(
                context,
                AppRoutes.editDevice,
                arguments: _currentDevice,
              );
              if (updated is Device) {
                setState(() {
                  _currentDevice = updated;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Device',
            onPressed: _deleteDevice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Header Banner
            CustomCard(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accent,
                    child: Icon(_getDeviceIcon(_currentDevice.deviceType), size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_currentDevice.brand} ${_currentDevice.model}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (_currentDevice.variant != null && _currentDevice.variant!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _currentDevice.variant!,
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: _currentDevice.deviceType,
                    backgroundColor: AppColors.accentLight,
                    textColor: AppColors.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Specifications Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Device Specifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 14),
                  _buildDetailRow(Icons.branding_watermark_rounded, 'Brand', _currentDevice.brand),
                  _buildDetailRow(Icons.devices_rounded, 'Model', _currentDevice.model),
                  if (_currentDevice.variant != null && _currentDevice.variant!.isNotEmpty)
                    _buildDetailRow(Icons.memory_rounded, 'Variant', _currentDevice.variant!),
                  if (_currentDevice.color != null && _currentDevice.color!.isNotEmpty)
                    _buildDetailRow(Icons.color_lens_outlined, 'Color', _currentDevice.color!),
                  if (_currentDevice.imei1 != null && _currentDevice.imei1!.isNotEmpty)
                    _buildDetailRow(Icons.qr_code_2_rounded, 'IMEI 1', _currentDevice.imei1!),
                  if (_currentDevice.imei2 != null && _currentDevice.imei2!.isNotEmpty)
                    _buildDetailRow(Icons.qr_code_2_rounded, 'IMEI 2 (Dual SIM)', _currentDevice.imei2!),
                  if (_currentDevice.serialNumber != null && _currentDevice.serialNumber!.isNotEmpty)
                    _buildDetailRow(Icons.tag_rounded, 'Serial Number', _currentDevice.serialNumber!),
                  if (_currentDevice.purchaseDate != null && _currentDevice.purchaseDate!.isNotEmpty)
                    _buildDetailRow(Icons.calendar_today_rounded, 'Purchase Date', _currentDevice.purchaseDate!),
                  if (_currentDevice.notes != null && _currentDevice.notes!.isNotEmpty)
                    _buildDetailRow(Icons.note_alt_outlined, 'Notes', _currentDevice.notes!),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Customer Info Card
            if (_currentDevice.customer != null) ...[
              CustomCard(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customer', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            _currentDevice.customer!.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            '📱 ${_currentDevice.customer!.mobile}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text('Device History & Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            // Future Module Placeholders
            _buildPlaceholderSection('Repair History', Icons.build_circle_rounded, 'No repair records yet.'),
            const SizedBox(height: 10),
            _buildPlaceholderSection('Sales & Invoices', Icons.receipt_long_rounded, 'No sales records yet.'),
            const SizedBox(height: 10),
            _buildPlaceholderSection('Warranty Status', Icons.verified_user_rounded, 'No warranty claims yet.'),
            const SizedBox(height: 10),
            _buildPlaceholderSection('Payment Records', Icons.account_balance_wallet_rounded, 'No payment records yet.'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderSection(String title, IconData icon, String subtitle) {
    return CustomCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
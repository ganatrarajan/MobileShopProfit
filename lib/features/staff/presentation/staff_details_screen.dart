import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../data/staff_repository.dart';
import '../models/staff.dart';
import 'add_edit_staff_bottom_sheet.dart';

class StaffDetailsScreen extends StatefulWidget {
  final Staff staff;

  const StaffDetailsScreen({super.key, required this.staff});

  @override
  State<StaffDetailsScreen> createState() => _StaffDetailsScreenState();
}

class _StaffDetailsScreenState extends State<StaffDetailsScreen> {
  late Staff _staff;
  final _staffRepo = StaffRepository();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _staff = widget.staff;
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    setState(() => _isLoading = true);
    final res = await _staffRepo.getStaffDetails(_staff.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.data != null) {
          _staff = res.data!;
        }
      });
    }
  }

  Future<void> _shareOnWhatsApp() async {
    final shop = await AuthStorage().getShop();
    final shopName = shop?['name']?.toString() ?? 'Our Mobile Shop';

    final activeModules = <String>[];
    if (_staff.permissions['sales'] == true) activeModules.add('🛒 Sales & Billing');
    if (_staff.permissions['repairs'] == true) activeModules.add('🔧 Repairs');
    if (_staff.permissions['purchases'] == true) activeModules.add('📦 Stock & Purchases');
    if (_staff.permissions['expenses'] == true) activeModules.add('💰 Expenses');
    if (_staff.permissions['used_mobiles'] == true) activeModules.add('📱 Used Mobiles');

    final msg = StringBuffer();
    msg.writeln('👋 Hello *${_staff.name}*,');
    msg.writeln('Your staff account (*${_staff.designation ?? 'Staff'}*) for *$shopName* is active on the *Mobile Shop Profit* app!\n');
    msg.writeln('🔑 *Your Login Credentials:*');
    msg.writeln('📱 *Mobile / Username:* ${_staff.mobile}');
    if (_staff.loginPassword != null && _staff.loginPassword!.isNotEmpty) {
      msg.writeln('🔒 *Password:* ${_staff.loginPassword}');
    }
    if (activeModules.isNotEmpty) {
      msg.writeln('\n🛡️ *Permitted Modules:*');
      for (final m in activeModules) {
        msg.writeln(' • $m');
      }
    }
    msg.writeln('\nPlease open the app and login to continue.');

    final shareText = msg.toString();
    final cleanPhone = _staff.mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final formattedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final url = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(shareText)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Clipboard.setData(ClipboardData(text: shareText));
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          title: 'Copied',
          message: 'Credentials copied to clipboard!',
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await StaffDeleteConfirmationBottomSheet.show(context, staff: _staff);

    if (confirm == true) {
      setState(() => _isLoading = true);
      final res = await _staffRepo.deleteStaff(_staff.id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (res.success) {
          AppFeedback.showSuccess(
            context,
            title: '🗑️ Staff Deleted',
            message: '${_staff.name} has been deleted successfully.',
          );
          Navigator.pop(context, true);
        } else {
          AppFeedback.showError(
            context,
            title: '❌ Delete Failed',
            error: res.message.isNotEmpty ? res.message : 'Failed to delete staff',
          );
        }
      }
    }
  }

  Future<void> _handleEdit() async {
    final updated = await AddEditStaffBottomSheet.show(context, staff: _staff);
    if (updated == true && mounted) {
      AppFeedback.showSuccess(
        context,
        title: '⚡ Staff Updated',
        message: '${_staff.name} updated successfully.',
      );
      _refreshDetails();
    }
  }

  Future<void> _handleToggleStatus() async {
    final willActivate = !_staff.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: willActivate
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                willActivate ? Icons.check_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                color: willActivate ? const Color(0xFF059669) : const Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                willActivate ? 'Activate Staff Login?' : 'Deactivate Staff Login?',
                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              willActivate
                  ? 'Are you sure you want to activate app login for ${_staff.name}?'
                  : 'Are you sure you want to deactivate app login for ${_staff.name}?',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: willActivate ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: willActivate ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    willActivate ? Icons.info_outline_rounded : Icons.warning_amber_rounded,
                    size: 16,
                    color: willActivate ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      willActivate
                          ? 'Staff will be able to sign in. Uses 1 active login slot.'
                          : 'Staff cannot sign in. Frees up 1 active login slot.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: willActivate ? const Color(0xFF166534) : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willActivate ? const Color(0xFF059669) : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(willActivate ? 'Yes, Activate' : 'Yes, Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final res = await _staffRepo.toggleStaffStatus(_staff.id);
    if (!mounted) return;

    if (res.success) {
      AppFeedback.showSuccess(
        context,
        title: willActivate ? '⚡ Login Activated' : '⏸️ Login Deactivated',
        message: res.message.isNotEmpty
            ? res.message
            : '${_staff.name}\'s login has been ${willActivate ? 'activated' : 'deactivated'}.',
      );
      _refreshDetails();
    } else {
      if (res.message.toLowerCase().contains('quota') ||
          res.message.toLowerCase().contains('limit') ||
          res.message.toLowerCase().contains('maximum')) {
        StaffQuotaBottomSheet.show(context, message: res.message);
      } else {
        AppFeedback.showError(
          context,
          title: '❌ Status Change Failed',
          error: res.message,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_staff.name),
        actions: [
          IconButton(
            icon: Icon(
              _staff.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
              color: _staff.isActive ? Colors.amber.shade300 : Colors.greenAccent,
            ),
            tooltip: _staff.isActive ? 'Deactivate Login' : 'Activate Login',
            onPressed: _handleToggleStatus,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Staff',
            onPressed: _handleEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete Staff',
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDetails,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Header Card
                  CustomCard(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.accent,
                          child: Text(
                            _staff.name.isNotEmpty ? _staff.name[0].toUpperCase() : 'S',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _staff.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _handleToggleStatus,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _staff.isActive ? const Color(0xFF10B981) : Colors.red.shade400,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _staff.isActive ? 'Active' : 'Inactive',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          const SizedBox(width: 3),
                                          const Icon(Icons.sync_rounded, size: 12, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _staff.designation ?? 'Staff Member',
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '📱 ${_staff.mobile}',
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Login Credentials Card
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'App Login Credentials',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ),
                            InkWell(
                              onTap: _shareOnWhatsApp,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF25D366), width: 1.2),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    WhatsAppIcon(size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'WhatsApp',
                                      style: TextStyle(
                                        color: Color(0xFF128C7E),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Mobile (Login ID):', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Row(
                              children: [
                                Text(_staff.mobile, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                                  padding: const EdgeInsets.only(left: 6),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _staff.mobile));
                                    AppFeedback.showSuccess(
                                      context,
                                      title: 'Copied',
                                      message: 'Mobile number copied!',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Password:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Row(
                              children: [
                                Text(
                                  _showPassword
                                      ? (_staff.loginPassword ?? '••••••')
                                      : '••••••••',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                ),
                                IconButton(
                                  icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.textSecondary),
                                  padding: const EdgeInsets.only(left: 6),
                                  constraints: const BoxConstraints(),
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                ),
                                if (_staff.loginPassword != null)
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                                    padding: const EdgeInsets.only(left: 6),
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: _staff.loginPassword!));
                                      AppFeedback.showSuccess(
                                        context,
                                        title: 'Copied',
                                        message: 'Password copied!',
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Permitted Modules
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.security_rounded, color: Color(0xFF6366F1), size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text('Module Permissions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPermBadge('Sales & Invoicing', _staff.canAccess('sales'), Icons.shopping_cart_outlined),
                            _buildPermBadge('Repair Jobs', _staff.canAccess('repairs'), Icons.build_outlined),
                            _buildPermBadge('Purchases & Stock', _staff.canAccess('purchases'), Icons.inventory_2_outlined),
                            _buildPermBadge('Daily Expenses', _staff.canAccess('expenses'), Icons.receipt_long_outlined),
                            _buildPermBadge('Used Mobiles', _staff.canAccess('used_mobiles'), Icons.phone_android_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // General Information
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.person_outline_rounded, color: Color(0xFF0284C7), size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text('Personal & Job Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_staff.email != null && _staff.email!.isNotEmpty)
                          _buildInfoRow('Email Address', _staff.email!, Icons.email_outlined),
                        if (_staff.joiningDate != null && _staff.joiningDate!.isNotEmpty)
                          _buildInfoRow('Joining Date', _staff.joiningDate!, Icons.calendar_today_outlined),
                        if (_staff.address != null && _staff.address!.isNotEmpty)
                          _buildInfoRow('Address', _staff.address!, Icons.location_on_outlined),
                        if (_staff.notes != null && _staff.notes!.isNotEmpty)
                          _buildInfoRow('Notes', _staff.notes!, Icons.notes_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermBadge(String title, bool isAllowed, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAllowed ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isAllowed ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isAllowed ? Colors.green.shade700 : Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAllowed ? Colors.green.shade800 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isAllowed ? Icons.check_circle : Icons.cancel_outlined,
            size: 13,
            color: isAllowed ? Colors.green.shade700 : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

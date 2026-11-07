import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/storage/preferences_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/custom_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../settings/presentation/widgets/app_lock_dialog.dart';
import '../../settings/presentation/widgets/change_password_dialog.dart';
import '../../technician/presentation/technician_my_work_screen.dart';

class StaffAccountScreen extends StatefulWidget {
  const StaffAccountScreen({super.key});

  @override
  State<StaffAccountScreen> createState() => _StaffAccountScreenState();
}

class _StaffAccountScreenState extends State<StaffAccountScreen> {
  final AuthStorage _authStorage = AuthStorage();
  final AuthRepository _authRepository = AuthRepository();
  final PreferencesStorage _prefsStorage = PreferencesStorage();

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _shop;
  bool _isLoading = true;
  bool _isAppLockEnabled = false;
  String _whatsappLangCode = 'en';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authStorage.getUser();
    final shop = await _authStorage.getShop();
    final isLock = await _prefsStorage.isAppLockEnabled();
    final waLang = await _prefsStorage.getWhatsAppLanguage();

    if (mounted) {
      setState(() {
        _user = user;
        _shop = shop;
        _isAppLockEnabled = isLock;
        _whatsappLangCode = waLang;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out from your staff account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authRepository.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    }
  }

  Future<void> _showWhatsAppLanguageDialog() async {
    final selected = await showDialog<WhatsAppLanguage>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select WhatsApp Language'),
        children: WhatsAppLanguage.values.map((lang) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, lang),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(lang.displayName, style: const TextStyle(fontSize: 15)),
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      await _prefsStorage.saveWhatsAppLanguage(selected.code);
      setState(() => _whatsappLangCode = selected.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final name = _user?['name']?.toString() ?? 'Staff Member';
    final mobile = _user?['mobile']?.toString() ?? '';
    final shopName = _shop?['name']?.toString() ?? 'Shop';

    final permsRaw = _user?['permissions'];
    final perms = permsRaw is Map ? permsRaw : {};

    final hasRepairs = perms['repairs'] == true || perms['repairs'] == 1 || perms['repairs'].toString() == 'true';
    final hasSales = perms['sales'] == true || perms['sales'] == 1 || perms['sales'].toString() == 'true';
    final hasPurchases = perms['purchases'] == true || perms['purchases'] == 1 || perms['purchases'].toString() == 'true';
    final hasUsed = perms['used_mobiles'] == true || perms['used_mobiles'] == 1 || perms['used_mobiles'].toString() == 'true';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Staff Profile Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: const Icon(Icons.person_rounded, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '📞 $mobile',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Text(
                            '🏪 $shopName',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. My Work & Profit Banner Card
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TechnicianMyWorkScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x254F46E5),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Work & Profit Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'View monthly earnings, repair jobs & payout balance',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Active Permissions Card
            const Text(
              'Your Assigned Permissions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            CustomCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildPermStatusRow(
                    icon: Icons.build_circle_rounded,
                    title: 'Repairs & Job Cards',
                    isActive: hasRepairs,
                    activeColor: Colors.blue,
                  ),
                  const Divider(height: 16),
                  _buildPermStatusRow(
                    icon: Icons.receipt_long_rounded,
                    title: 'Sales & Invoicing',
                    isActive: hasSales,
                    activeColor: Colors.green,
                  ),
                  const Divider(height: 16),
                  _buildPermStatusRow(
                    icon: Icons.inventory_2_rounded,
                    title: 'Stock & Purchases',
                    isActive: hasPurchases,
                    activeColor: Colors.teal,
                  ),
                  const Divider(height: 16),
                  _buildPermStatusRow(
                    icon: Icons.phone_android_rounded,
                    title: 'Used Mobiles',
                    isActive: hasUsed,
                    activeColor: Colors.purple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Security & App Settings
            const Text(
              'Security & Preferences',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            CustomCard(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                    title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Update your login password', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => const ChangePasswordDialog(),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security_rounded, color: AppColors.primary),
                    title: const Text('App Lock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(_isAppLockEnabled ? '4-Digit PIN Lock Enabled' : 'Disabled', style: const TextStyle(fontSize: 12)),
                    trailing: Switch(
                      value: _isAppLockEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (val) async {
                        final res = await showDialog<bool>(
                          context: context,
                          builder: (_) => AppLockDialog(isCurrentlyEnabled: _isAppLockEnabled),
                        );
                        if (res != null) _loadData();
                      },
                    ),
                    onTap: () async {
                      final res = await showDialog<bool>(
                        context: context,
                        builder: (_) => AppLockDialog(isCurrentlyEnabled: _isAppLockEnabled),
                      );
                      if (res != null) _loadData();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.chat_rounded, color: AppColors.primary),
                    title: const Text('WhatsApp Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(WhatsAppLanguage.fromCode(_whatsappLangCode).displayName, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: _showWhatsAppLanguageDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are signed in as a staff member of $shopName. Contact your shop owner if you need access to other modules.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPermStatusRow({
    required IconData icon,
    required String title,
    required bool isActive,
    required Color activeColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isActive ? activeColor : Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.textPrimary : Colors.grey,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? Colors.green.shade300 : Colors.grey.shade300),
          ),
          child: Text(
            isActive ? 'Allowed' : 'No Access',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

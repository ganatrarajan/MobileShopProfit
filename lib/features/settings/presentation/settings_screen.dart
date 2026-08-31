import 'package:flutter/material.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/storage/preferences_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../auth/data/auth_repository.dart';
import 'widgets/app_lock_dialog.dart';
import 'widgets/change_password_dialog.dart';
import 'widgets/contact_support_dialog.dart';
import 'widgets/feedback_dialog.dart';
import 'widgets/report_problem_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthStorage _authStorage = AuthStorage();
  final AuthRepository _authRepository = AuthRepository();
  final PreferencesStorage _prefsStorage = PreferencesStorage();

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _shop;
  bool _isLoading = true;
  bool _isAppLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = await _authStorage.getUser();
    final shop = await _authStorage.getShop();
    final isLock = await _prefsStorage.isAppLockEnabled();

    if (mounted) {
      setState(() {
        _user = user;
        _shop = shop;
        _isAppLockEnabled = isLock;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your Mobile Profits account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 38),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authRepository.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preferences Section
                  _buildSectionHeader('Preferences'),
                  const SizedBox(height: 8),
                  CustomCard(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.language_rounded,
                          title: 'Language',
                          subtitle: 'English',
                          trailingText: 'English',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Language set to English (Architecture ready for future locales)')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingTile(
                          icon: Icons.currency_rupee_rounded,
                          title: 'Currency',
                          subtitle: 'Primary operating currency',
                          trailingText: '? INR',
                          onTap: null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Account Section
                  _buildSectionHeader('Account'),
                  const SizedBox(height: 8),
                  CustomCard(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.lock_reset_rounded,
                          title: 'Change Password',
                          subtitle: 'Update account password',
                          onTap: () async {
                            await showDialog(
                              context: context,
                              builder: (_) => const ChangePasswordDialog(),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingTile(
                          icon: Icons.security_rounded,
                          title: 'App Lock',
                          subtitle: _isAppLockEnabled ? '4-Digit PIN Lock Enabled' : 'Disabled',
                          trailingWidget: Switch(
                            value: _isAppLockEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (val) async {
                              final res = await showDialog<bool>(
                                context: context,
                                builder: (_) => AppLockDialog(isCurrentlyEnabled: _isAppLockEnabled),
                              );
                              if (res != null) {
                                _loadInitialData();
                              }
                            },
                          ),
                          onTap: () async {
                            final res = await showDialog<bool>(
                              context: context,
                              builder: (_) => AppLockDialog(isCurrentlyEnabled: _isAppLockEnabled),
                            );
                            if (res != null) {
                              _loadInitialData();
                            }
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingTile(
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.error,
                          title: 'Logout',
                          subtitle: 'Sign out of your shop account',
                          titleColor: AppColors.error,
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Help Section
                  _buildSectionHeader('Help'),
                  const SizedBox(height: 8),
                  CustomCard(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.support_agent_rounded,
                          title: 'Contact Support',
                          subtitle: 'Get in touch with support team',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => ContactSupportDialog(user: _user, shop: _shop),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingTile(
                          icon: Icons.report_problem_outlined,
                          title: 'Report a Problem',
                          subtitle: 'Submit an issue with diagnostic details',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => ReportProblemDialog(user: _user, shop: _shop),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingTile(
                          icon: Icons.rate_review_outlined,
                          title: 'Send Feedback',
                          subtitle: 'Share your thoughts and rating',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => const FeedbackDialog(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // App Version Footer
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'Mobile Profits v1.0.0+1',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'App Preferences � Security � Support',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    Color? titleColor,
    required String subtitle,
    String? trailingText,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: trailingWidget ??
          (trailingText != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trailingText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    if (onTap != null) const SizedBox(width: 4),
                    if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                  ],
                )
              : (onTap != null ? const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted) : null)),
      onTap: onTap,
    );
  }
}


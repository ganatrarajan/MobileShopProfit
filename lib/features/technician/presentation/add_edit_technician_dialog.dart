import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_error_mapper.dart';
import '../../../core/utils/app_feedback.dart';
import '../../subscription/utils/subscription_guard.dart';
import '../data/technician_repository.dart';
import '../models/technician.dart';

class AddEditTechnicianDialog extends StatefulWidget {
  final Technician? technician;
  const AddEditTechnicianDialog({super.key, this.technician});

  static Future<bool?> show(BuildContext context, {Technician? technician}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditTechnicianDialog(technician: technician),
    );
  }

  @override
  State<AddEditTechnicianDialog> createState() => _AddEditTechnicianDialogState();
}

class _AddEditTechnicianDialogState extends State<AddEditTechnicianDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _specializationController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isActive = true;
  bool _enableLogin = false;
  bool _obscurePassword = true;
  bool _isSaving = false;
  String? _errorMessage;

  Map<String, bool> _permissions = {
    'repairs': true,
    'sales': false,
    'purchases': false,
    'used_mobiles': false,
  };

  final TechnicianRepository _repository = TechnicianRepository();

  @override
  void initState() {
    super.initState();
    if (widget.technician != null) {
      final t = widget.technician!;
      _nameController.text = t.name;
      _mobileController.text = t.mobile ?? '';
      _specializationController.text = t.specialization ?? '';
      _isActive = t.isActive;
      _enableLogin = t.hasLogin;
      if (t.permissions.isNotEmpty) {
        _permissions = {
          'repairs': t.permissions['repairs'] ?? false,
          'sales': t.permissions['sales'] ?? false,
          'purchases': t.permissions['purchases'] ?? false,
          'used_mobiles': t.permissions['used_mobiles'] ?? false,
        };
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _specializationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'repairs_only':
          _permissions = {'repairs': true, 'sales': false, 'purchases': false, 'used_mobiles': false};
          break;
        case 'sales_purchases':
          _permissions = {'repairs': false, 'sales': true, 'purchases': true, 'used_mobiles': false};
          break;
        case 'used_only':
          _permissions = {'repairs': false, 'sales': false, 'purchases': false, 'used_mobiles': true};
          break;
        case 'all_access':
          _permissions = {'repairs': true, 'sales': true, 'purchases': true, 'used_mobiles': true};
          break;
      }
    });
  }

  bool _isLimitError(dynamic response) {
    final code = response.rawJson?['code']?.toString() ?? '';
    final errorCode = response.rawJson?['error_code']?.toString() ?? '';
    final msg = (response.message ?? '').toString().toLowerCase();
    return code == 'STAFF_LIMIT_REACHED' ||
        errorCode == 'STAFF_LIMIT_REACHED' ||
        (msg.contains('staff') && (msg.contains('limit') || msg.contains('upgrade') || msg.contains('not included')));
  }

  Future<void> _showCredentialsShareDialog({
    required String name,
    required String mobile,
    required String password,
    required Map<String, bool> permissions,
  }) async {
    final shop = await AuthStorage().getShop();
    final shopName = shop?['name']?.toString() ?? 'Our Mobile Shop';

    final activeModules = <String>[];
    if (permissions['repairs'] == true) activeModules.add('🔧 Repairs');
    if (permissions['sales'] == true) activeModules.add('🛒 Sales & Billing');
    if (permissions['purchases'] == true) activeModules.add('📦 Stock & Purchases');
    if (permissions['used_mobiles'] == true) activeModules.add('📱 Used Mobiles');

    final msg = StringBuffer();
    msg.writeln('👋 Hello *$name*,');
    msg.writeln('Your staff account for *$shopName* is now active on the *Mobile Shop Profit* app!\n');
    msg.writeln('🔑 *Your Login Credentials:*');
    msg.writeln('📱 *Mobile:* $mobile');
    msg.writeln('🔒 *Password:* $password');
    if (activeModules.isNotEmpty) {
      msg.writeln('🛡️ *Permitted Modules:* ${activeModules.join(', ')}');
    }
    msg.writeln('\nPlease open the app and login with your mobile and password to start managing your daily work.');

    final shareText = msg.toString();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 26),
            SizedBox(width: 8),
            Text('Staff Account Ready', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff login for $name has been created/updated successfully.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mobile: $mobile', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Password: $password', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text('Access: ${activeModules.join(', ')}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Share these credentials with your staff member so they can login directly on their own phone.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Credentials copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final cleanPhone = mobile.replaceAll(RegExp(r'[^0-9]'), '');
              final formattedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
              final url = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(shareText)}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.chat_bubble_rounded, size: 16),
            label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _handleErrorResponse(dynamic response) {
    setState(() => _isSaving = false);
    if (_isLimitError(response)) {
      setState(() => _errorMessage = null);
      SubscriptionGuard.showStaffLimitDialog(
        context,
        message: response.message,
        planName: response.rawJson?['plan_name']?.toString(),
      );
    } else {
      setState(() {
        _errorMessage = AppErrorMapper.mapMessage(response.message);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final specialization = _specializationController.text.trim();
    final password = _passwordController.text.trim();

    if (_enableLogin) {
      if (mobile.isEmpty) {
        setState(() => _errorMessage = 'Mobile number is required to enable staff login.');
        return;
      }
      if (widget.technician == null && password.isEmpty) {
        setState(() => _errorMessage = 'Password is required to create a new staff login.');
        return;
      }
      final hasAnyModule = _permissions.values.any((v) => v == true);
      if (!hasAnyModule) {
        setState(() => _errorMessage = 'Please enable at least one module permission for this staff.');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (widget.technician == null) {
        final response = await _repository.createTechnician(
          name: name,
          mobile: mobile,
          specialization: specialization,
          isActive: _isActive,
          enableLogin: _enableLogin,
          password: password.isNotEmpty ? password : null,
          permissions: _enableLogin ? _permissions : null,
        );

        if (mounted) {
          if (response.success && response.data != null) {
            AppFeedback.showSuccess(
              context,
              title: 'Technician Added',
              message: '${response.data!.name} has been added successfully.',
            );

            if (_enableLogin && password.isNotEmpty) {
              await _showCredentialsShareDialog(
                name: name,
                mobile: mobile,
                password: password,
                permissions: _permissions,
              );
            }

            if (mounted) Navigator.pop(context, true);
          } else {
            _handleErrorResponse(response);
          }
        }
      } else {
        final response = await _repository.updateTechnician(
          id: widget.technician!.id,
          name: name,
          mobile: mobile,
          specialization: specialization,
          isActive: _isActive,
          enableLogin: _enableLogin,
          password: password.isNotEmpty ? password : null,
          permissions: _enableLogin ? _permissions : null,
        );

        if (mounted) {
          if (response.success && response.data != null) {
            AppFeedback.showSuccess(
              context,
              title: 'Technician Updated',
              message: '${response.data!.name} details updated.',
            );

            if (_enableLogin && password.isNotEmpty) {
              await _showCredentialsShareDialog(
                name: name,
                mobile: mobile,
                password: password,
                permissions: _permissions,
              );
            }

            if (mounted) Navigator.pop(context, true);
          } else {
            _handleErrorResponse(response);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final errStr = e.toString();
        if (errStr.contains('STAFF_LIMIT_REACHED') ||
            (errStr.toLowerCase().contains('staff') &&
                (errStr.toLowerCase().contains('limit') ||
                    errStr.toLowerCase().contains('upgrade') ||
                    errStr.toLowerCase().contains('not included')))) {
          setState(() => _errorMessage = null);
          SubscriptionGuard.showStaffLimitDialog(context);
        } else {
          setState(() {
            _errorMessage = AppErrorMapper.mapMessage(errStr);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.technician != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.90;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEditing ? Icons.manage_accounts_rounded : Icons.person_add_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Technician & Staff' : 'Add Technician & Staff',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'Update details, permissions & login access'
                                : 'Create technician & setup app login permissions',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Staff / Technician Name *',
                            hintText: 'e.g. Rahul Sharma',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Mobile Number
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: InputDecoration(
                            labelText: _enableLogin ? 'Mobile Number (Staff Login ID) *' : 'Mobile Number (Optional)',
                            hintText: '10-digit mobile number',
                            counterText: '',
                            prefixIcon: const Icon(Icons.phone_rounded),
                          ),
                          validator: (val) {
                            if (_enableLogin) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Mobile number is required for login';
                              }
                              if (val.trim().length != 10 || int.tryParse(val.trim()) == null) {
                                return 'Enter a valid 10-digit mobile number';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Specialization
                        TextFormField(
                          controller: _specializationController,
                          decoration: const InputDecoration(
                            labelText: 'Role / Specialization',
                            hintText: 'e.g. Hardware Technician, Counter Sales',
                            prefixIcon: Icon(Icons.build_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Active Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            _isActive ? 'Active (can assign jobs & allow login)' : 'Inactive (deactivated / hidden)',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: _isActive,
                          onChanged: (val) => setState(() => _isActive = val),
                          activeColor: AppColors.primary,
                        ),
                        const Divider(height: 24),

                        // ================= APP LOGIN & ROLE PERMISSIONS =================
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _enableLogin ? AppColors.primary.withOpacity(0.04) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _enableLogin ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade300,
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.key_rounded,
                                    color: _enableLogin ? AppColors.primary : Colors.grey,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Allow App Login for this Staff',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          _enableLogin
                                              ? 'Staff logs in using phone & password'
                                              : 'Turn on to let staff manage jobs on their phone',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _enableLogin,
                                    onChanged: (val) => setState(() => _enableLogin = val),
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),

                              if (_enableLogin) ...[
                                const SizedBox(height: 14),
                                const Divider(height: 1),
                                const SizedBox(height: 14),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: isEditing && widget.technician?.hasLogin == true
                                        ? 'New Password (leave blank to keep current)'
                                        : 'Staff Login Password *',
                                    hintText: 'Minimum 6 characters',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (_enableLogin) {
                                      if (widget.technician == null || widget.technician?.hasLogin != true) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Password is required for app login';
                                        }
                                        if (val.trim().length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                      } else if (val != null && val.isNotEmpty && val.trim().length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                if (isEditing && widget.technician?.loginPassword != null && widget.technician!.loginPassword!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Current password: ${_obscurePassword ? '••••••••' : widget.technician!.loginPassword}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                          child: Text(
                                            _obscurePassword ? 'Show' : 'Hide',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),

                                // Quick Role Preset Chips
                                const Text(
                                  'Quick Role Preset:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    ActionChip(
                                      avatar: const Icon(Icons.build_rounded, size: 14, color: AppColors.primary),
                                      label: const Text('Repairs Only', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: Colors.grey.shade300),
                                      onPressed: () => _applyPreset('repairs_only'),
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.point_of_sale_rounded, size: 14, color: Colors.green),
                                      label: const Text('Sales & Purchases', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: Colors.grey.shade300),
                                      onPressed: () => _applyPreset('sales_purchases'),
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.phone_android_rounded, size: 14, color: Colors.deepPurple),
                                      label: const Text('Used Mobiles Only', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: Colors.grey.shade300),
                                      onPressed: () => _applyPreset('used_only'),
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.verified_user_rounded, size: 14, color: Colors.indigo),
                                      label: const Text('All Modules', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: Colors.grey.shade300),
                                      onPressed: () => _applyPreset('all_access'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Permissions Checkboxes
                                const Text(
                                  'Module Permissions:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 6),

                                _buildPermissionTile(
                                  title: '🔧 Repair Jobs & Service Sheet',
                                  subtitle: 'Can view, create & update repair job cards',
                                  key: 'repairs',
                                ),
                                _buildPermissionTile(
                                  title: '🛒 Counter Sales & Billing',
                                  subtitle: 'Can make sales bills & view invoices',
                                  key: 'sales',
                                ),
                                _buildPermissionTile(
                                  title: '📦 Stock & Vendor Purchases',
                                  subtitle: 'Can manage stock and add vendor purchase entries',
                                  key: 'purchases',
                                ),
                                _buildPermissionTile(
                                  title: '📱 Used Mobiles Buy & Sell',
                                  subtitle: 'Can create used mobile agreements & sale records',
                                  key: 'used_mobiles',
                                ),

                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.shield_rounded, size: 16, color: Colors.amber.shade900),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Financial Privacy: Staff cannot see net profit, purchase costs, margins, shop earnings, or delete records.',
                                          style: TextStyle(fontSize: 11, color: Colors.amber.shade900, height: 1.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Pinned Bottom Button Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 6,
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEditing ? 'Update Technician & Staff' : 'Save Technician & Staff',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required String key,
  }) {
    final isChecked = _permissions[key] == true;
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      value: isChecked,
      activeColor: AppColors.primary,
      onChanged: (val) {
        setState(() {
          _permissions[key] = val ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

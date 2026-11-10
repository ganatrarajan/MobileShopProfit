import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../../subscription/presentation/subscription_screen.dart';
import '../data/staff_repository.dart';
import '../models/staff.dart';

class AddEditStaffBottomSheet extends StatefulWidget {
  final Staff? staff;

  const AddEditStaffBottomSheet({super.key, this.staff});

  /// Static helper method to display this sheet easily from anywhere
  static Future<bool?> show(BuildContext context, {Staff? staff}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => AddEditStaffBottomSheet(staff: staff),
    );
  }

  @override
  State<AddEditStaffBottomSheet> createState() => _AddEditStaffBottomSheetState();
}

class _AddEditStaffBottomSheetState extends State<AddEditStaffBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _staffRepo = StaffRepository();

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _designationController;
  late TextEditingController _salaryController;
  late TextEditingController _addressController;

  DateTime? _joiningDate;
  bool _isActive = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showAdditionalFields = false;

  final List<Map<String, dynamic>> _rolePresets = [
    {
      'title': 'Manager',
      'icon': Icons.admin_panel_settings_outlined,
      'perms': {'sales': true, 'repairs': true, 'purchases': true, 'expenses': true, 'used_mobiles': true, 'customers': true},
    },
    {
      'title': 'Sales & Billing',
      'icon': Icons.point_of_sale_rounded,
      'perms': {'sales': true, 'repairs': false, 'purchases': false, 'expenses': false, 'used_mobiles': true, 'customers': true},
    },
    {
      'title': 'Cashier',
      'icon': Icons.payments_outlined,
      'perms': {'sales': true, 'repairs': false, 'purchases': false, 'expenses': true, 'used_mobiles': false, 'customers': true},
    },
    {
      'title': 'Service Advisor',
      'icon': Icons.support_agent_rounded,
      'perms': {'sales': true, 'repairs': true, 'purchases': false, 'expenses': false, 'used_mobiles': false, 'customers': true},
    },
    {
      'title': 'Custom / Other',
      'icon': Icons.edit_note_rounded,
      'perms': null,
    },
  ];

  Map<String, bool> _permissions = {
    'sales': true,
    'repairs': true,
    'purchases': false,
    'expenses': false,
    'used_mobiles': false,
    'customers': true,
  };

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    _nameController = TextEditingController(text: s?.name ?? '');
    _mobileController = TextEditingController(text: s?.mobile ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _passwordController = TextEditingController(text: s?.loginPassword ?? '');
    _designationController = TextEditingController(text: s?.designation ?? 'Sales & Billing');
    _salaryController = TextEditingController(text: s?.salary != null ? s!.salary!.toStringAsFixed(0) : '');
    _addressController = TextEditingController(text: s?.address ?? '');

    if (s?.email != null && s!.email!.isNotEmpty) {
      _showAdditionalFields = true;
    }
    if (s?.address != null && s!.address!.isNotEmpty) {
      _showAdditionalFields = true;
    }

    if (s?.joiningDate != null) {
      try {
        _joiningDate = DateTime.parse(s!.joiningDate!);
      } catch (_) {}
    }

    _isActive = s?.isActive ?? true;

    if (s != null && s.permissions.isNotEmpty) {
      _permissions = Map<String, bool>.from(s.permissions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _designationController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _applyRolePreset(String role, Map<String, bool>? perms) {
    setState(() {
      if (perms == null || role == 'Custom / Other') {
        final isPresetName = _rolePresets.where((p) => p['perms'] != null).any((p) => p['title'].toLowerCase() == _designationController.text.trim().toLowerCase());
        if (isPresetName) {
          _designationController.clear();
        }
      } else {
        _designationController.text = role;
        _permissions = Map<String, bool>.from(perms);
      }
    });
  }

  void _selectAllPermissions(bool enable) {
    setState(() {
      _permissions.updateAll((key, value) => enable);
    });
  }

  Future<void> _pickJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _joiningDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.staff != null;
    if (!isEdit && _passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Password is required to create a staff app login.');
      AppFeedback.showError(context, error: _errorMessage!);
      return;
    }

    final hasAtLeastOnePerm = _permissions.values.any((p) => p == true);
    if (!hasAtLeastOnePerm) {
      setState(() => _errorMessage = 'Please enable at least one permission module for this staff.');
      AppFeedback.showError(context, error: _errorMessage!);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();
    final designation = _designationController.text.trim();
    final email = _emailController.text.trim();
    final salary = _salaryController.text.trim().isNotEmpty
        ? double.tryParse(_salaryController.text.trim())
        : widget.staff?.salary;
    final address = _addressController.text.trim();
    final joiningDateStr = _joiningDate != null
        ? "${_joiningDate!.year}-${_joiningDate!.month.toString().padLeft(2, '0')}-${_joiningDate!.day.toString().padLeft(2, '0')}"
        : null;

    if (isEdit) {
      final res = await _staffRepo.updateStaff(
        id: widget.staff!.id,
        name: name,
        mobile: mobile,
        email: email.isNotEmpty ? email : null,
        designation: designation.isNotEmpty ? designation : 'Staff',
        salary: salary,
        address: address.isNotEmpty ? address : null,
        joiningDate: joiningDateStr,
        isActive: _isActive,
        permissions: _permissions,
        password: password.isNotEmpty ? password : null,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (res.success) {
          AppFeedback.showSuccess(
            context,
            title: 'Staff Updated',
            message: '$name has been updated successfully.',
          );
          Navigator.pop(context, true);
        } else {
          final err = res.message.isNotEmpty ? res.message : 'Failed to update staff';
          setState(() => _errorMessage = err);
          AppFeedback.showError(context, error: err);
        }
      }
    } else {
      final res = await _staffRepo.createStaff(
        name: name,
        mobile: mobile,
        password: password,
        email: email.isNotEmpty ? email : null,
        designation: designation.isNotEmpty ? designation : 'Staff',
        salary: salary,
        address: address.isNotEmpty ? address : null,
        joiningDate: joiningDateStr,
        isActive: _isActive,
        permissions: _permissions,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (res.success && res.data != null) {
          AppFeedback.showSuccess(
            context,
            title: 'Staff Added',
            message: '$name has been created successfully.',
          );
          Navigator.pop(context, true);
          // Show credentials bottom sheet to easily copy & share on WhatsApp
          StaffCredentialsBottomSheet.show(
            context,
            name: name,
            mobile: mobile,
            password: password,
            designation: designation,
            permissions: _permissions,
          );
        } else {
          if (res.message.toLowerCase().contains('quota') ||
              res.message.toLowerCase().contains('limit') ||
              res.message.toLowerCase().contains('maximum')) {
            StaffQuotaBottomSheet.show(context, message: res.message);
          } else {
            final err = res.message.isNotEmpty ? res.message : 'Failed to create staff';
            setState(() => _errorMessage = err);
            AppFeedback.showError(context, error: err);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.staff != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Grab Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.badge_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Staff Member' : 'Add Staff Member',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEdit ? 'Update staff profile & app permissions' : 'Create app login & configure permissions',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Scrollable Form Body
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error Banner
                      if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.red.shade800, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 1. LOGIN & ACCOUNT DETAILS CARD
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.lock_person_rounded,
                        iconColor: const Color(0xFF4F46E5),
                        title: 'App Login Credentials',
                        badgeText: 'Staff Login',
                        badgeColor: const Color(0xFFEEF2FF),
                        badgeTextColor: const Color(0xFF4338CA),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Staff will use their Mobile Number & Password to sign into the mobile app.',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 14),

                            // Full Name
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration(
                                isDark: isDark,
                                label: 'Full Name *',
                                hint: 'e.g. Ramesh Kumar',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Please enter staff name';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Mobile (Login ID)
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: _inputDecoration(
                                isDark: isDark,
                                label: 'Mobile Number (Login ID) *',
                                hint: '10-digit mobile number',
                                icon: Icons.phone_android_rounded,
                                prefixText: '+91 ',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Mobile number is required for login';
                                final clean = v.replaceAll(RegExp(r'\D'), '');
                                if (clean.length != 10) return 'Please enter a valid 10-digit mobile number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: _inputDecoration(
                                isDark: isDark,
                                label: isEdit ? 'New Password (Optional)' : 'Login Password *',
                                hint: isEdit ? 'Leave blank to keep existing password' : 'Min 4 characters',
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (!isEdit && (v == null || v.trim().length < 4)) {
                                  return 'Password must be at least 4 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. ROLE & DESIGNATION CARD
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.work_outline_rounded,
                        iconColor: const Color(0xFF0284C7),
                        title: 'Role & Designation',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tap a preset to configure designation and recommended permissions automatically:',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 10),

                            // Role Presets Chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _rolePresets.map((preset) {
                                final currentText = _designationController.text.trim().toLowerCase();
                                final isStandardPreset = _rolePresets
                                    .where((p) => p['perms'] != null)
                                    .any((p) => (p['title'] as String).toLowerCase() == currentText);

                                final isSelected = preset['perms'] != null
                                    ? currentText == (preset['title'] as String).toLowerCase()
                                    : (!isStandardPreset && currentText.isNotEmpty);

                                return InkWell(
                                  onTap: () => _applyRolePreset(preset['title'], preset['perms'] != null ? Map<String, bool>.from(preset['perms']) : null),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF0284C7)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF0284C7) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          preset['icon'] as IconData,
                                          size: 15,
                                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          preset['title'] as String,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF334155)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // Custom Designation TextField
                            TextFormField(
                              controller: _designationController,
                              textCapitalization: TextCapitalization.words,
                              onChanged: (_) => setState(() {}),
                              decoration: _inputDecoration(
                                isDark: isDark,
                                label: 'Designation / Job Title (Optional)',
                                hint: 'e.g. Sales Executive, Cashier, Helper',
                                icon: Icons.badge_outlined,
                              ).copyWith(
                                helperText: 'Choose a preset above or type any custom role here',
                                helperStyle: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. EMPLOYMENT DETAILS
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.calendar_month_rounded,
                        iconColor: const Color(0xFF16A34A),
                        title: 'Employment Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: _pickJoiningDate,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: _inputDecoration(
                                  isDark: isDark,
                                  label: 'Joining Date (Optional)',
                                  hint: 'Select Date',
                                  icon: Icons.calendar_today_rounded,
                                ),
                                child: Text(
                                  _joiningDate != null
                                      ? "${_joiningDate!.day.toString().padLeft(2, '0')}/${_joiningDate!.month.toString().padLeft(2, '0')}/${_joiningDate!.year}"
                                      : 'Tap to pick joining date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _joiningDate != null
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : (isDark ? Colors.white38 : Colors.grey.shade500),
                                  ),
                                ),
                              ),
                            ),

                            // Toggle additional fields (Email & Address)
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => setState(() => _showAdditionalFields = !_showAdditionalFields),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      _showAdditionalFields ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                                      color: const Color(0xFF4F46E5),
                                      size: 22,
                                    ),
                                    Text(
                                      _showAdditionalFields ? 'Hide Additional Details' : 'Add Email & Address (Optional)',
                                      style: const TextStyle(
                                        color: Color(0xFF4F46E5),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_showAdditionalFields) ...[
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                  isDark: isDark,
                                  label: 'Email Address (Optional)',
                                  hint: 'staff@example.com',
                                  icon: Icons.email_outlined,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _addressController,
                                maxLines: 2,
                                decoration: _inputDecoration(
                                  isDark: isDark,
                                  label: 'Residential Address (Optional)',
                                  hint: 'Street, city, pincode',
                                  icon: Icons.location_on_outlined,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. MODULE PERMISSIONS
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.security_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        title: 'Module Access Permissions',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _selectAllPermissions(true),
                              child: const Text('All', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const Text(' | ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            GestureDetector(
                              onTap: () => _selectAllPermissions(false),
                              child: const Text('None', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose which modules this staff member is authorized to view and use:',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),

                            // Permission cards
                            _buildModernPermTile(
                              isDark: isDark,
                              keyName: 'sales',
                              title: 'Sales & Invoicing',
                              subtitle: 'Create sales bills, manage orders & print invoices',
                              icon: Icons.shopping_cart_rounded,
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(height: 8),
                            _buildModernPermTile(
                              isDark: isDark,
                              keyName: 'repairs',
                              title: 'Repair Tickets',
                              subtitle: 'Create repair jobs, update status & track repairs',
                              icon: Icons.build_circle_rounded,
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(height: 8),
                            _buildModernPermTile(
                              isDark: isDark,
                              keyName: 'purchases',
                              title: 'Stock & Purchases',
                              subtitle: 'Add supplier bills, manage stock & view inventory',
                              icon: Icons.inventory_2_rounded,
                              color: const Color(0xFF8B5CF6),
                            ),
                            const SizedBox(height: 8),
                            _buildModernPermTile(
                              isDark: isDark,
                              keyName: 'expenses',
                              title: 'Daily Expenses',
                              subtitle: 'Record shop expenses & view daily cash outflows',
                              icon: Icons.receipt_long_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(height: 8),
                            _buildModernPermTile(
                              isDark: isDark,
                              keyName: 'used_mobiles',
                              title: 'Used Mobiles',
                              subtitle: 'Buy second-hand phones, inspect & create resale deals',
                              icon: Icons.phone_android_rounded,
                              color: const Color(0xFF14B8A6),
                            ),
                            const SizedBox(height: 8),
                            _buildModernPermTile(
                              isDark: isDark,
                              keyName: 'customers',
                              title: 'Customer Directory',
                              subtitle: 'View customer directory, contacts & service history',
                              icon: Icons.people_alt_rounded,
                              color: const Color(0xFFEC4899),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. ACCOUNT STATUS
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.toggle_on_rounded,
                        iconColor: _isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        title: 'Account Status',
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isActive ? 'Login Enabled (Active)' : 'Login Disabled (Inactive)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: _isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isActive
                                        ? 'Staff can sign in and access permitted modules'
                                        : 'Staff login is blocked. Cannot sign into app',
                                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isActive,
                              activeColor: const Color(0xFF16A34A),
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(isEdit ? Icons.check_circle_outline_rounded : Icons.person_add_rounded, size: 18, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEdit ? 'Save Changes' : 'Create Staff Member',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeTextColor ?? const Color(0xFF4338CA),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildModernPermTile({
    required bool isDark,
    required String keyName,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isChecked = _permissions[keyName] == true;

    return InkWell(
      onTap: () {
        setState(() {
          _permissions[keyName] = !isChecked;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isChecked
              ? (isDark ? color.withOpacity(0.12) : color.withOpacity(0.06))
              : (isDark ? Colors.transparent : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isChecked
                ? color.withOpacity(0.4)
                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isChecked,
              activeColor: color,
              onChanged: (val) {
                setState(() {
                  _permissions[keyName] = val;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
      labelStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF475569)),
      hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey.shade400),
    );
  }
}

/// Bottom Sheet for sharing newly generated staff login credentials
class StaffCredentialsBottomSheet extends StatelessWidget {
  final String name;
  final String mobile;
  final String password;
  final String designation;
  final Map<String, bool> permissions;

  const StaffCredentialsBottomSheet({
    super.key,
    required this.name,
    required this.mobile,
    required this.password,
    required this.designation,
    required this.permissions,
  });

  static Future<void> show(
    BuildContext context, {
    required String name,
    required String mobile,
    required String password,
    required String designation,
    required Map<String, bool> permissions,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StaffCredentialsBottomSheet(
        name: name,
        mobile: mobile,
        password: password,
        designation: designation,
        permissions: permissions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeModules = <String>[];
    if (permissions['sales'] == true) activeModules.add('🛒 Sales & Billing');
    if (permissions['repairs'] == true) activeModules.add('🔧 Repairs');
    if (permissions['purchases'] == true) activeModules.add('📦 Stock');
    if (permissions['expenses'] == true) activeModules.add('💸 Expenses');
    if (permissions['used_mobiles'] == true) activeModules.add('📱 Used Mobiles');
    if (permissions['customers'] == true) activeModules.add('👥 Customers');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),

            // Success Circle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 32),
            ),
            const SizedBox(height: 12),

            Text(
              'Staff Account Created!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share these login details so $name can sign in on their phone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // Credentials Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _credentialRow(isDark, 'Staff Name', name, Icons.person_outline_rounded),
                  const Divider(height: 14),
                  _credentialRow(isDark, 'Role / Title', designation, Icons.work_outline_rounded),
                  const Divider(height: 14),
                  _credentialRow(isDark, 'Mobile (Login ID)', mobile, Icons.phone_android_rounded, isHighlight: true),
                  const Divider(height: 14),
                  _credentialRow(isDark, 'Login Password', password, Icons.lock_outline_rounded, isPassword: true),
                  if (activeModules.isNotEmpty) ...[
                    const Divider(height: 14),
                    _credentialRow(isDark, 'Modules', activeModules.join(', '), Icons.shield_outlined),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const WhatsAppIcon(size: 18),
                    label: const Text('Send via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final shop = await AuthStorage().getShop();
                      final shopName = shop?['name']?.toString() ?? 'Our Mobile Shop';
                      final msg = StringBuffer();
                      msg.writeln('👋 Hello *$name*,');
                      msg.writeln('Your staff account (*$designation*) for *$shopName* is now active on the *Mobile Shop Profit* app!\n');
                      msg.writeln('🔑 *Your Login Credentials:*');
                      msg.writeln('📱 *Mobile / Username:* $mobile');
                      msg.writeln('🔒 *Password:* $password');
                      if (activeModules.isNotEmpty) {
                        msg.writeln('\n🛡️ *Assigned Modules:*');
                        for (final m in activeModules) {
                          msg.writeln(' • $m');
                        }
                      }
                      msg.writeln('\nPlease login to start work.');

                      final cleanPhone = mobile.replaceAll(RegExp(r'[^0-9]'), '');
                      final formattedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
                      final url = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(msg.toString())}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                  onPressed: () {
                    final text = 'Staff Login\nMobile: $mobile\nPassword: $password\nRole: $designation';
                    Clipboard.setData(ClipboardData(text: text));
                    AppFeedback.showSuccess(
                      context,
                      title: 'Copied',
                      message: 'Credentials copied to clipboard!',
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _credentialRow(bool isDark, String label, String value, IconData icon, {bool isHighlight = false, bool isPassword = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white60 : Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isPassword
                ? const Color(0xFF4F46E5)
                : (isHighlight ? const Color(0xFF0F172A) : (isDark ? Colors.white : Colors.black87)),
            fontFamily: (isHighlight || isPassword) ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

/// Bottom Sheet for Staff Delete Confirmation
class StaffDeleteConfirmationBottomSheet extends StatelessWidget {
  final Staff staff;

  const StaffDeleteConfirmationBottomSheet({super.key, required this.staff});

  static Future<bool?> show(BuildContext context, {required Staff staff}) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StaffDeleteConfirmationBottomSheet(staff: staff),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              'Remove Staff Member?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to remove "${staff.name}" (${staff.mobile})? Their app login will be immediately revoked.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Yes, Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom Sheet for Quota Limit Reached (Staff logins add-on ₹2/day)
class StaffQuotaBottomSheet extends StatelessWidget {
  final String message;

  const StaffQuotaBottomSheet({super.key, required this.message});

  static Future<void> show(BuildContext context, {required String message}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StaffQuotaBottomSheet(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_add_rounded, color: Color(0xFF4F46E5), size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              'Staff Logins Limit Reached',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFF4F46E5), size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Staff logins are available at ₹2 / day for your remaining subscription days.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3730A3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('Add Staff Logins', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

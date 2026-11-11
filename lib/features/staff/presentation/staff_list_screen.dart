import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../../subscription/presentation/subscription_screen.dart';
import '../data/staff_repository.dart';
import '../models/staff.dart';
import 'add_edit_staff_bottom_sheet.dart';
import 'staff_details_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final _staffRepo = StaffRepository();
  final _searchController = TextEditingController();

  List<Staff> _staffList = [];
  StaffSummary? _summary;
  bool _isLoading = true;
  String _selectedStatus = 'all';
  final Map<int, bool> _revealedPasswords = {};

  final Map<String, String> _statusOptions = {
    'all': 'All Staff',
    'active': 'Active',
    'inactive': 'Inactive',
  };

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    final res = await _staffRepo.getStaffList(
      search: _searchController.text.trim(),
      status: _selectedStatus,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.data != null) {
          _staffList = res.data!.staff;
          _summary = res.data!.summary;
        } else {
          AppFeedback.showError(
            context,
            title: '❌ Failed',
            error: res.message.isNotEmpty ? res.message : 'Failed to load staff list',
          );
        }
      });
    }
  }

  Future<void> _openAddStaffDialog() async {
    final used = _summary?.staffAccountsUsed ?? 0;
    final maxAllowed = _summary?.maxStaffAllowed ?? 0;
    final isLimitReached = used >= maxAllowed && maxAllowed > 0;
    final added = await AddEditStaffBottomSheet.show(context, isLimitReached: isLimitReached);
    if (added == true && mounted) {
      AppFeedback.showSuccess(
        context,
        title: '⚡ Staff Added',
        message: 'Staff member created successfully.',
      );
      _loadStaff();
    }
  }

  Future<void> _openEditStaffDialog(Staff staff) async {
    final used = _summary?.staffAccountsUsed ?? 0;
    final maxAllowed = _summary?.maxStaffAllowed ?? 0;
    final isLimitReached = used >= maxAllowed && maxAllowed > 0;
    final updated = await AddEditStaffBottomSheet.show(context, staff: staff, isLimitReached: isLimitReached);
    if (updated == true && mounted) {
      AppFeedback.showSuccess(
        context,
        title: '⚡ Staff Updated',
        message: '${staff.name} updated successfully.',
      );
      _loadStaff();
    }
  }

  Future<void> _handleDeleteStaff(Staff staff) async {
    final confirm = await StaffDeleteConfirmationBottomSheet.show(context, staff: staff);

    if (confirm == true) {
      final res = await _staffRepo.deleteStaff(staff.id);
      if (mounted) {
        if (res.success) {
          AppFeedback.showSuccess(
            context,
            title: '🗑️ Staff Deleted',
            message: '${staff.name} has been deleted successfully.',
          );
          _loadStaff();
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

  Future<void> _handleToggleStatus(Staff staff) async {
    final willActivate = !staff.isActive;

    if (willActivate) {
      final used = _summary?.staffAccountsUsed ?? 0;
      final maxAllowed = _summary?.maxStaffAllowed ?? 0;
      if (used >= maxAllowed && maxAllowed > 0) {
        StaffQuotaBottomSheet.show(
          context,
          message:
              'Active staff login limit reached ($used / $maxAllowed active). Please deactivate another staff member\'s login or add more staff logins (@ ₹2/day) to activate login for ${staff.name}.',
        );
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
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
                    ? 'Are you sure you want to activate app login for ${staff.name}?'
                    : 'Are you sure you want to deactivate app login for ${staff.name}?',
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
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final res = await _staffRepo.toggleStaffStatus(staff.id);
    if (!mounted) return;

    if (res.success) {
      AppFeedback.showSuccess(
        context,
        title: willActivate ? '⚡ Login Activated' : '⏸️ Login Deactivated',
        message: res.message.isNotEmpty
            ? res.message
            : '${staff.name}\'s login has been ${willActivate ? 'activated' : 'deactivated'}.',
      );
      _loadStaff();
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

  Future<void> _shareOnWhatsApp(Staff staff) async {
    final shop = await AuthStorage().getShop();
    final shopName = shop?['name']?.toString() ?? 'Our Mobile Shop';

    final activeModules = <String>[];
    if (staff.permissions['sales'] == true) activeModules.add('🛒 Sales');
    if (staff.permissions['repairs'] == true) activeModules.add('🔧 Repairs');
    if (staff.permissions['purchases'] == true) activeModules.add('📦 Stock');
    if (staff.permissions['expenses'] == true) activeModules.add('💰 Expenses');
    if (staff.permissions['used_mobiles'] == true) activeModules.add('📱 Used Mobiles');

    final msg = StringBuffer();
    msg.writeln('👋 Hello *${staff.name}*,');
    msg.writeln('Your staff login for *$shopName* is active on the *Mobile Shop Profit* app!\n');
    msg.writeln('🔑 *Your Login Credentials:*');
    msg.writeln('📱 *Mobile:* ${staff.mobile}');
    if (staff.loginPassword != null && staff.loginPassword!.isNotEmpty) {
      msg.writeln('🔒 *Password:* ${staff.loginPassword}');
    }
    if (activeModules.isNotEmpty) {
      msg.writeln('🛡️ *Modules:* ${activeModules.join(', ')}');
    }
    msg.writeln('\nPlease login to start work.');

    final shareText = msg.toString();
    final cleanPhone = staff.mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final formattedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final url = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(shareText)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Clipboard.setData(ClipboardData(text: shareText));
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          title: '📋 Copied',
          message: 'Credentials copied to clipboard!',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStaff,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_add_staff',
        onPressed: _openAddStaffDialog,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // 1. Purple Header Bar with Summary Metrics & Search
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                // Summary Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        title: 'Total Staff',
                        value: '${_staffList.length}',
                        icon: Icons.badge_rounded,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryMetric(
                        title: 'Active',
                        value: '${_summary?.activeStaff ?? _staffList.where((s) => s.isActive).length}',
                        icon: Icons.check_circle_rounded,
                        color: Colors.lightGreenAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryMetric(
                        title: 'Logins Used',
                        value: _summary != null
                            ? '${_summary!.staffAccountsUsed} / ${_summary!.maxStaffAllowed}'
                            : '0 / 0',
                        icon: Icons.lock_person_rounded,
                        color: Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryMetric(
                        title: 'Days Left',
                        value: _summary != null ? '${_summary!.staffDaysRemaining}d' : '0d',
                        icon: Icons.schedule_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Field
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadStaff(),
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by name, mobile, role...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _loadStaff();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Status Filter Tabs & Plan Status
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusOptions.entries.map((entry) {
                        final isSelected = _selectedStatus == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(entry.value),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedStatus = entry.key);
                                _loadStaff();
                              }
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            checkmarkColor: Colors.white,
                            showCheckmark: isSelected,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.grey.shade300,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Text(
                  '${_staffList.length} staff',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // 3. Plan / Quota Notice Banner (if any)
          if (_summary != null) _buildSubscriptionBanner(),

          // 4. Staff Cards List / Loading / Empty
          Expanded(
            child: _isLoading
                ? AppShimmer.listLoading()
                : _staffList.isEmpty
                    ? AppEmptyState(
                        icon: Icons.badge_outlined,
                        title: 'No staff members found',
                        message: 'Add your shop employees so they can login and manage sales, repairs, or inventory.',
                        actionLabel: 'Add Staff Member',
                        onAction: _openAddStaffDialog,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStaff,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: _staffList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            return _buildStaffCard(_staffList[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBanner() {
    final used = _summary!.staffAccountsUsed;
    final maxAllowed = _summary!.maxStaffAllowed;
    final isLimitReached = used >= maxAllowed && maxAllowed > 0;
    final isExpired = _summary!.isStaffExpired;
    final daysRemaining = _summary!.staffDaysRemaining;

    Color bg = const Color(0xFFF0FDF4); // Soft Green
    Color border = const Color(0xFFBBF7D0);
    Color textColor = const Color(0xFF166534);
    IconData icon = Icons.lock_person_rounded;

    if (isExpired || maxAllowed == 0) {
      bg = Colors.amber.shade50;
      border = Colors.amber.shade300;
      textColor = Colors.amber.shade900;
      icon = Icons.info_outline;
    } else if (isLimitReached) {
      bg = Colors.orange.shade50;
      border = Colors.orange.shade300;
      textColor = Colors.orange.shade900;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Logins: $used / $maxAllowed Active',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                ),
                Text(
                  maxAllowed == 0
                      ? 'No staff login active on current plan.'
                      : (daysRemaining > 0 ? '$daysRemaining days remaining on staff access' : 'Staff access active'),
                  style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ).then((_) => _loadStaff());
            },
            child: const Text('Add Logins', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Staff staff) {
    final activeModules = <String>[];
    if (staff.permissions['sales'] == true) activeModules.add('Sales');
    if (staff.permissions['repairs'] == true) activeModules.add('Repairs');
    if (staff.permissions['purchases'] == true) activeModules.add('Stock');
    if (staff.permissions['expenses'] == true) activeModules.add('Expenses');
    if (staff.permissions['used_mobiles'] == true) activeModules.add('Used');

    final isPasswordRevealed = _revealedPasswords[staff.id] == true;

    return CustomCard(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StaffDetailsScreen(staff: staff)),
        );
        if (result == true) _loadStaff();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row: Avatar, Full Name & Designation, Status Badge, Popup Menu
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: staff.isActive
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.grey.shade200,
                child: Icon(
                  Icons.badge_rounded,
                  color: staff.isActive ? AppColors.primary : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staff.designation ?? 'Staff Member',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _handleToggleStatus(staff),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: staff.isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: staff.isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: staff.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        staff.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: staff.isActive ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 13,
                        color: staff.isActive ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                onSelected: (val) {
                  if (val == 'toggle_status') {
                    _handleToggleStatus(staff);
                  } else if (val == 'edit') {
                    _openEditStaffDialog(staff);
                  } else if (val == 'delete') {
                    _handleDeleteStaff(staff);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          staff.isActive ? Icons.pause_circle_outline_rounded : Icons.check_circle_outline_rounded,
                          size: 16,
                          color: staff.isActive ? Colors.orange.shade800 : const Color(0xFF059669),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          staff.isActive ? 'Deactivate Login' : 'Activate Login',
                          style: TextStyle(
                            color: staff.isActive ? Colors.orange.shade900 : const Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Edit Staff'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete Staff', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // 2. Credentials Details Row: Mobile & Password
          Row(
            children: [
              // Mobile Number
              Expanded(
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: staff.mobile));
                    AppFeedback.showSuccess(
                      context,
                      title: '📋 Copied',
                      message: 'Mobile number copied!',
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        staff.mobile,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, size: 12, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),

              // Password
              if (staff.loginPassword != null && staff.loginPassword!.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      isPasswordRevealed ? staff.loginPassword! : '••••••••',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isPasswordRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      padding: const EdgeInsets.only(left: 4),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _revealedPasswords[staff.id] = !isPasswordRevealed;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 13, color: AppColors.textMuted),
                      padding: const EdgeInsets.only(left: 6),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: staff.loginPassword!));
                        AppFeedback.showSuccess(
                          context,
                          title: '📋 Copied',
                          message: 'Password copied!',
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. Permissions & WhatsApp Share Row
          Row(
            children: [
              // Module chips
              Expanded(
                child: activeModules.isNotEmpty
                    ? Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: activeModules.map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Text(
                              m,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : const Text(
                        'No modules assigned',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
              ),

              // WhatsApp Share Pill
              InkWell(
                onTap: () => _shareOnWhatsApp(staff),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF25D366), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WhatsAppIcon(size: 15),
                      SizedBox(width: 5),
                      Text(
                        'Share Login',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF128C7E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

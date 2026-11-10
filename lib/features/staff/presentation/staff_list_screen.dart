import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
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
          AppFeedback.showError(context, error: res.message.isNotEmpty ? res.message : 'Failed to load staff list');
        }
      });
    }
  }

  Future<void> _openAddStaffDialog() async {
    final added = await AddEditStaffBottomSheet.show(context);
    if (added == true) {
      _loadStaff();
    }
  }

  Future<void> _openEditStaffDialog(Staff staff) async {
    final updated = await AddEditStaffBottomSheet.show(context, staff: staff);
    if (updated == true) {
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
            title: 'Staff Deleted',
            message: '${staff.name} has been deleted successfully.',
          );
          _loadStaff();
        } else {
          AppFeedback.showError(context, error: res.message.isNotEmpty ? res.message : 'Failed to delete staff');
        }
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
    if (staff.permissions['customers'] == true) activeModules.add('👥 Customers');

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
          title: 'Copied',
          message: 'Credentials copied to clipboard!',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStaff,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddStaffDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Staff Subscription Status Card
          if (_summary != null) _buildSubscriptionBanner(),

          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone, role...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadStaff();
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onSubmitted: (_) => _loadStaff(),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  initialValue: _selectedStatus,
                  onSelected: (val) {
                    setState(() => _selectedStatus = val);
                    _loadStaff();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'all', child: Text('All Staff')),
                    const PopupMenuItem(value: 'active', child: Text('Active Only')),
                    const PopupMenuItem(value: 'inactive', child: Text('Inactive Only')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _selectedStatus == 'all' ? 'Filter' : _selectedStatus[0].toUpperCase() + _selectedStatus.substring(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Staff List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _staffList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadStaff,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _staffList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
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

  Widget _buildSubscriptionBanner() {
    final used = _summary!.staffAccountsUsed;
    final maxAllowed = _summary!.maxStaffAllowed;
    final isLimitReached = used >= maxAllowed && maxAllowed > 0;
    final isExpired = _summary!.isStaffExpired;
    final daysRemaining = _summary!.staffDaysRemaining;

    Color bg = Colors.blue.shade50;
    Color border = Colors.blue.shade200;
    Color textColor = Colors.blue.shade900;
    IconData icon = Icons.badge_rounded;

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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Logins: $used / $maxAllowed Active',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    if (staff.permissions['customers'] == true) activeModules.add('Customers');

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StaffDetailsScreen(staff: staff)),
          ).then((_) => _loadStaff());
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                staff.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: staff.isActive ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                staff.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: staff.isActive ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          staff.designation ?? 'Staff Member',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _shareOnWhatsApp(staff),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF25D366), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WhatsAppIcon(size: 15),
                          SizedBox(width: 4),
                          Text(
                            'Share',
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
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        _openEditStaffDialog(staff);
                      } else if (val == 'delete') {
                        _handleDeleteStaff(staff);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                    ],
                  ),
                ],
              ),

              const Divider(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(staff.mobile, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 13, color: AppColors.primary),
                        padding: const EdgeInsets.only(left: 4),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: staff.mobile));
                          AppFeedback.showSuccess(
                            context,
                            title: 'Copied',
                            message: 'Mobile number copied!',
                          );
                        },
                      ),
                    ],
                  ),
                  if (staff.loginPassword != null && staff.loginPassword!.isNotEmpty)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _revealedPasswords[staff.id] = !(_revealedPasswords[staff.id] ?? false);
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              _revealedPasswords[staff.id] == true ? staff.loginPassword! : '••••••••',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _revealedPasswords[staff.id] == true ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              if (activeModules.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: activeModules.map((m) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(m, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Staff Members Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your shop employees so they can login and manage sales, repairs, or inventory.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openAddStaffDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add First Staff Member'),
            ),
          ],
        ),
      ),
    );
  }
}

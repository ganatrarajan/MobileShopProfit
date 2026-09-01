import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/warranty_repository.dart';
import '../../subscription/utils/subscription_guard.dart';
import '../models/warranty.dart';

class WarrantyListScreen extends StatefulWidget {
  final bool isTab;
  const WarrantyListScreen({super.key, this.isTab = false});

  @override
  State<WarrantyListScreen> createState() => _WarrantyListScreenState();
}

class _WarrantyListScreenState extends State<WarrantyListScreen> {
  final WarrantyRepository _warrantyRepository = WarrantyRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Warranty> _warranties = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all'; // active, expiring_soon, expired, voided, all
  String _selectedType = 'all'; // sale, repair, all

  int _activeCount = 0;
  int _expiringSoonCount = 0;
  int _expiredCount = 0;
  int _totalClaimsCount = 0;

  final Map<String, String> _statusLabels = {
    'all': 'All Warranties',
    'active': 'Active',
    'expiring_soon': 'Expiring Soon',
    'expired': 'Expired',
    'voided': 'Voided',
  };

  final Map<String, Color> _statusColors = {
    'active': Colors.green.shade700,
    'expiring_soon': Colors.amber.shade900,
    'expired': Colors.red.shade700,
    'voided': Colors.grey.shade700,
  };

  @override
  void initState() {
    super.initState();
    _fetchWarranties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWarranties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _warrantyRepository.getWarranties(
        search: _searchController.text.trim(),
        status: _selectedStatus,
        warrantyType: _selectedType,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final list = response.data!;
          int active = 0;
          int expiring = 0;
          int expired = 0;
          int claimsSum = 0;

          for (final w in list) {
            if (w.status == 'active') active++;
            if (w.status == 'expiring_soon') expiring++;
            if (w.status == 'expired') expired++;
            claimsSum += w.claimsCount;
          }

          setState(() {
            _warranties = list;
            _activeCount = active;
            _expiringSoonCount = expiring;
            _expiredCount = expired;
            _totalClaimsCount = claimsSum;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteWarranty(Warranty warranty) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text('Delete Warranty'),
            ],
          ),
          content: Text('Are you sure you want to delete warranty ${warranty.warrantyNumber}? All associated claims will also be deleted.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final res = await _warrantyRepository.deleteWarranty(warranty.id);
      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Warranty ${warranty.warrantyNumber} deleted.'), backgroundColor: Colors.green.shade700),
          );
          _fetchWarranties();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Summary Header Cards & Search Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.primary,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Active',
                      value: '$_activeCount',
                      icon: Icons.verified_user_rounded,
                      color: Colors.greenAccent.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Expiring Soon',
                      value: '$_expiringSoonCount',
                      icon: Icons.access_time_filled_rounded,
                      color: Colors.amberAccent.shade200,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Expired',
                      value: '$_expiredCount',
                      icon: Icons.error_outline_rounded,
                      color: Colors.redAccent.shade100,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.warrantyClaims),
                      child: _buildSummaryMetric(
                        title: 'Claims',
                        value: '$_totalClaimsCount',
                        icon: Icons.assignment_late_rounded,
                        color: Colors.lightBlueAccent.shade100,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search Box & Warranty Type Dropdown
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _fetchWarranties(),
                      decoration: InputDecoration(
                        hintText: 'Search Warranty #, Customer, IMEI, Model...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchWarranties();
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
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter Chips Row
        Container(
          height: 48,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              ..._statusLabels.entries.map((entry) {
                return _buildFilterChip(entry.value, entry.key);
              }),
              const VerticalDivider(width: 16, indent: 8, endIndent: 8),
              _buildTypeChip('All Types', 'all'),
              _buildTypeChip('Sale Warranty', 'sale'),
              _buildTypeChip('Repair Warranty', 'repair'),
            ],
          ),
        ),
        const Divider(height: 1),

        // Warranty Card List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _fetchWarranties, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : _warranties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.verified_outlined, size: 60, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text('No warranty records found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              SizedBox(height: 4),
                              Text('Tap Create Warranty (+) to issue a new warranty', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchWarranties,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _warranties.length,
                            itemBuilder: (context, index) {
                              final warranty = _warranties[index];
                              final statusColor = _statusColors[warranty.status] ?? AppColors.primary;
                              final customerName = warranty.customer?.name ?? 'Customer';
                              final customerMobile = warranty.customer?.mobile ?? '';
                              final deviceName = warranty.device != null
                                  ? '${warranty.device!.brand} ${warranty.device!.model}'
                                  : 'Device';

                              String remainingText = '';
                              if (warranty.status == 'expired') {
                                remainingText = 'Expired ${warranty.daysRemaining.abs()} days ago';
                              } else {
                                remainingText = 'Expires in ${warranty.daysRemaining} days';
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: CustomCard(
                                  onTap: () async {
                                    final refreshed = await Navigator.pushNamed(
                                      context,
                                      AppRoutes.warrantyDetails,
                                      arguments: warranty,
                                    );
                                    if (refreshed == true) _fetchWarranties();
                                  },
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  warranty.warrantyNumber,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: warranty.warrantyType == 'sale' ? Colors.purple.shade50 : Colors.indigo.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  warranty.warrantyType == 'sale' ? 'SALE' : 'REPAIR',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: warranty.warrantyType == 'sale' ? Colors.purple.shade800 : Colors.indigo.shade800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              StatusBadge(
                                                label: warranty.status.replaceAll('_', ' ').toUpperCase(),
                                                backgroundColor: statusColor.withOpacity(0.12),
                                                textColor: statusColor,
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () => _confirmDeleteWarranty(warranty),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey.shade400),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(text: customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                                                  if (customerMobile.isNotEmpty)
                                                    TextSpan(text: ' ($customerMobile)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                                ],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_android_rounded, size: 16, color: AppColors.accent),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(text: deviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                                  if (warranty.device?.imei1 != null)
                                                    TextSpan(text: ' (IMEI: ${warranty.device!.imei1})', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                                ],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Icon(Icons.event_available_rounded, size: 14, color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${warranty.warrantyStartDate} - ${warranty.warrantyEndDate}',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            children: [
                                              Text(
                                                remainingText,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: statusColor,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Warranty & Claims'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_late_outlined),
            tooltip: 'All Claims',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.warrantyClaims),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'issue warranties');
              if (!ok) return;
              final result = await Navigator.pushNamed(context, AppRoutes.createWarranty);
              if (result == true) _fetchWarranties();
            },
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_warranty_list',
        onPressed: () async {
          final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'issue warranties');
          if (!ok) return;
          final result = await Navigator.pushNamed(context, AppRoutes.createWarranty);
          if (result == true) _fetchWarranties();
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.verified_rounded, color: Colors.white),
        label: const Text('Issue Warranty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String statusKey) {
    final isSelected = _selectedStatus == statusKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedStatus = statusKey);
            _fetchWarranties();
          }
        },
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }

  Widget _buildTypeChip(String label, String typeKey) {
    final isSelected = _selectedType == typeKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedType = typeKey);
            _fetchWarranties();
          }
        },
        selectedColor: AppColors.accent,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/repair_repository.dart';
import '../models/repair.dart';

class RepairListScreen extends StatefulWidget {
  final bool isTab;
  const RepairListScreen({super.key, this.isTab = false});

  @override
  State<RepairListScreen> createState() => RepairListScreenState();
}

class RepairListScreenState extends State<RepairListScreen> {
  void fetchRepairs() => _fetchRepairs();
  final RepairRepository _repairRepository = RepairRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Repair> _repairs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';

  // Date Filtering state
  String _datePreset = 'all_time'; // 'today', 'yesterday', 'this_month', 'all_time', 'custom'
  DateTimeRange? _customDateRange;

  double _totalRepairVolume = 0.0;
  double _totalPaidSum = 0.0;
  double _totalDueSum = 0.0;

  final Map<String, String> _statusLabels = {
    'all': 'All Repairs',
    'received': 'Received',
    'diagnosing': 'Diagnosing',
    'waiting_customer': 'Waiting Customer',
    'waiting_parts': 'Waiting Parts',
    'repairing': 'Repairing',
    'ready': 'Ready',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  final Map<String, Color> _statusColors = {
    'received': Colors.blue.shade700,
    'diagnosing': Colors.purple.shade700,
    'waiting_customer': Colors.orange.shade800,
    'waiting_parts': Colors.amber.shade900,
    'repairing': Colors.indigo.shade700,
    'ready': Colors.teal.shade700,
    'delivered': Colors.green.shade800,
    'cancelled': Colors.red.shade700,
  };

  @override
  void initState() {
    super.initState();
    _fetchRepairs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? get _dateFrom {
    final now = DateTime.now();
    if (_datePreset == 'today') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'yesterday') {
      final y = now.subtract(const Duration(days: 1));
      return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'this_month') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    } else if (_datePreset == 'custom' && _customDateRange != null) {
      final s = _customDateRange!.start;
      return '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
    }
    return null; // all_time
  }

  String? get _dateTo {
    final now = DateTime.now();
    if (_datePreset == 'today') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'yesterday') {
      final y = now.subtract(const Duration(days: 1));
      return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'this_month') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'custom' && _customDateRange != null) {
      final e = _customDateRange!.end;
      return '${e.year}-${e.month.toString().padLeft(2, '0')}-${e.day.toString().padLeft(2, '0')}';
    }
    return null; // all_time
  }

  String get _dateFilterLabel {
    switch (_datePreset) {
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'this_month':
        return 'This Month';
      case 'custom':
        if (_customDateRange != null) {
          final s = _customDateRange!.start;
          final e = _customDateRange!.end;
          return '${s.day}/${s.month} - ${e.day}/${e.month}';
        }
        return 'Custom';
      case 'all_time':
      default:
        return 'All Time';
    }
  }

  Future<void> _fetchRepairs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repairRepository.getRepairs(
        search: _searchController.text.trim(),
        repairStatus: _selectedStatus,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final list = response.data!;
          double volSum = 0.0;
          double paidSum = 0.0;
          double dueSum = 0.0;

          for (final r in list) {
            volSum += r.netCost;
            paidSum += r.amountPaid;
            dueSum += r.amountDue;
          }

          setState(() {
            _repairs = list;
            _totalRepairVolume = volSum;
            _totalPaidSum = paidSum;
            _totalDueSum = dueSum;
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

  void _showDateFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Select Date Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.all_inclusive_rounded),
                  title: const Text('All Time'),
                  trailing: _datePreset == 'all_time' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'all_time');
                    _fetchRepairs();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.today_rounded),
                  title: const Text('Today'),
                  trailing: _datePreset == 'today' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'today');
                    _fetchRepairs();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('Yesterday'),
                  trailing: _datePreset == 'yesterday' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'yesterday');
                    _fetchRepairs();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_view_month_rounded),
                  title: const Text('This Month'),
                  trailing: _datePreset == 'this_month' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'this_month');
                    _fetchRepairs();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.date_range_rounded),
                  title: const Text('Custom Date Range...'),
                  trailing: _datePreset == 'custom' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: _customDateRange ?? DateTimeRange(
                        start: DateTime.now().subtract(const Duration(days: 7)),
                        end: DateTime.now(),
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _datePreset = 'custom';
                        _customDateRange = picked;
                      });
                      _fetchRepairs();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteRepair(Repair repair) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text('Delete Job Card'),
            ],
          ),
          content: Text('Are you sure you want to delete job card ${repair.jobNumber}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
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
      final res = await _repairRepository.deleteRepair(repair.id);
      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job Card ${repair.jobNumber} deleted successfully.'),
              backgroundColor: Colors.green.shade700,
            ),
          );
          _fetchRepairs();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Summary Header Cards & Search
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.primary,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Total Value',
                      value: '₹ ${_totalRepairVolume.toStringAsFixed(0)}',
                      icon: Icons.build_circle_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Advance/Paid',
                      value: '₹ ${_totalPaidSum.toStringAsFixed(0)}',
                      icon: Icons.check_circle_rounded,
                      color: Colors.greenAccent.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Total Due',
                      value: '₹ ${_totalDueSum.toStringAsFixed(0)}',
                      icon: Icons.pending_actions_rounded,
                      color: Colors.amberAccent.shade200,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search Field & Date Filter Chip
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _fetchRepairs(),
                      decoration: InputDecoration(
                        hintText: 'Search Job #, Customer, IMEI, Model...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchRepairs();
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
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showDateFilterBottomSheet,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            _dateFilterLabel,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Status Filter Bar
        Container(
          height: 48,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: _statusLabels.entries.map((entry) {
              return _buildFilterChip(entry.value, entry.key);
            }).toList(),
          ),
        ),
        const Divider(height: 1),

        // Repair Cards List
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
                          ElevatedButton(
                            onPressed: _fetchRepairs,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _repairs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.build_circle_outlined, size: 60, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No repair job cards found for $_dateFilterLabel',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              const Text('Tap Create Repair (+) to log a new job card', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchRepairs,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _repairs.length,
                            itemBuilder: (context, index) {
                              final repair = _repairs[index];
                              final statusColor = _statusColors[repair.repairStatus] ?? AppColors.primary;
                              final statusLabel = _statusLabels[repair.repairStatus] ?? repair.repairStatus.toUpperCase();
                              final customerName = repair.customer?.name ?? 'Customer';
                              final customerMobile = repair.customer?.mobile ?? '';
                              final deviceName = repair.device != null
                                  ? '${repair.device!.brand} ${repair.device!.model}'
                                  : 'Device';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: CustomCard(
                                  onTap: () async {
                                    final refreshed = await Navigator.pushNamed(
                                      context,
                                      AppRoutes.repairDetails,
                                      arguments: repair,
                                    );
                                    if (refreshed == true) {
                                      _fetchRepairs();
                                    }
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
                                                  repair.jobNumber,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                repair.dateReceived,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              StatusBadge(
                                                label: statusLabel,
                                                backgroundColor: statusColor.withOpacity(0.12),
                                                textColor: statusColor,
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () => _confirmDeleteRepair(repair),
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
                                                  if (repair.device?.imei1 != null)
                                                    TextSpan(text: ' (IMEI: ${repair.device!.imei1})', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                                ],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                                                            const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.engineering_rounded,
                                            size: 15,
                                            color: repair.technicianName != null && repair.technicianName!.isNotEmpty
                                                ? AppColors.primary
                                                : Colors.orange.shade800,
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: repair.technicianName != null && repair.technicianName!.isNotEmpty
                                                  ? Colors.blue.shade50
                                                  : Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: repair.technicianName != null && repair.technicianName!.isNotEmpty
                                                    ? Colors.blue.shade200
                                                    : Colors.orange.shade200,
                                              ),
                                            ),
                                            child: Text(
                                              repair.technicianName != null && repair.technicianName!.isNotEmpty
                                                  ? 'Tech: ${repair.technicianName}'
                                                  : 'Tech: Unassigned',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: repair.technicianName != null && repair.technicianName!.isNotEmpty
                                                    ? Colors.blue.shade900
                                                    : Colors.orange.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Problem: ${repair.problemDescription}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                repair.finalCost > 0 ? 'Final Cost' : 'Estimated Cost',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                              ),
                                              Text(
                                                '₹ ${repair.netCost.toStringAsFixed(2)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    repair.amountDue > 0 ? 'Due Amount' : 'Paid',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: repair.amountDue > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    repair.amountDue > 0
                                                        ? '₹ ${repair.amountDue.toStringAsFixed(2)}'
                                                        : '₹ ${repair.amountPaid.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: repair.amountDue > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 8),
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
        title: const Text('Repair & Job Cards'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, AppRoutes.createRepair);
              if (result == true) {
                _fetchRepairs();
              }
            },
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_repair_list',
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.createRepair);
          if (result == true) {
            _fetchRepairs();
          }
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.build_circle_rounded, color: Colors.white),
        label: const Text('Create Repair', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
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
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String statusKey) {
    final isSelected = _selectedStatus == statusKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedStatus = statusKey;
            });
            _fetchRepairs();
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}

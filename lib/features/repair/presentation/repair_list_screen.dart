import '../../../core/widgets/app_shimmer.dart';
import 'repair_invoice_pdf_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/date_range_empty_state.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../../subscription/utils/subscription_guard.dart';
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
  String _datePreset = 'this_month'; // 'today', 'yesterday', 'this_month', 'all_time', 'custom'
  DateTimeRange? _customDateRange;

  double _totalRepairVolume = 0.0;
  double _totalPaidSum = 0.0;
  double _totalDueSum = 0.0;
  double _totalPartsCost = 0.0;
  double _totalTechCost = 0.0;
  double _totalNetProfit = 0.0;

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


  bool _hasParsedArgs = false;

  void applyDateFilter(String period, DateTimeRange? customRange) {
    if (_datePreset != period || _customDateRange != customRange) {
      setState(() {
        _datePreset = period;
        _customDateRange = customRange;
      });
      _fetchRepairs();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasParsedArgs) {
      _hasParsedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        if (args is Map) {
          if (args.containsKey('period')) {
            _datePreset = args['period'].toString();
          }
          if (args.containsKey('customRange') && args['customRange'] is DateTimeRange) {
            _customDateRange = args['customRange'] as DateTimeRange;
          }
        } else {
          final strArgs = args.toString().toLowerCase();
          if (strArgs.contains('ready')) {
            _selectedStatus = 'ready';
            _datePreset = 'all_time';
          } else if (_statusLabels.containsKey(strArgs)) {
            _selectedStatus = strArgs;
            _datePreset = 'all_time';
          }
        }
      }
      _fetchRepairs();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? get _dateFrom => DateHelper.getDateRangeForPreset(_datePreset, customRange: _customDateRange).dateFrom;
  String? get _dateTo => DateHelper.getDateRangeForPreset(_datePreset, customRange: _customDateRange).dateTo;

  String get _dateFilterLabel {
    switch (_datePreset) {
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      case 'last_month':
        return 'Last Month';
      case 'this_year':
        return 'This Year';
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
          double partsCostSum = 0.0;
          double techCostSum = 0.0;
          double netProfitSum = 0.0;

          for (final r in list) {
            volSum += r.netCost;
            paidSum += r.amountPaid;
            dueSum += r.amountDue;
            partsCostSum += r.partsCostTotal;
            techCostSum += r.technicianCost;
            netProfitSum += r.netProfit;
          }

          setState(() {
            _repairs = list;
            _totalRepairVolume = volSum;
            _totalPaidSum = paidSum;
            _totalDueSum = dueSum;
            _totalPartsCost = partsCostSum;
            _totalTechCost = techCostSum;
            _totalNetProfit = netProfitSum;
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

  void _showStatusFilterBottomSheet() {
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.filter_list_rounded, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Filter by Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (_selectedStatus != 'all')
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() => _selectedStatus = 'all');
                          _fetchRepairs();
                        },
                        child: const Text('Reset', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _statusLabels.entries.map((entry) {
                      final key = entry.key;
                      final label = entry.value;
                      final isSelected = _selectedStatus == key;
                      final color = _statusColors[key] ?? AppColors.primary;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 10,
                          backgroundColor: key == 'all' ? Colors.grey.shade400 : color,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => _selectedStatus = key);
                          _fetchRepairs();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                const Row(
                  children: [
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
    final confirm = await AppDialogs.showConfirmation(
      context,
      title: 'Delete Job Card',
      message: 'Are you sure you want to delete job card ${repair.jobNumber}? This action cannot be undone.',
      confirmLabel: 'Delete Job Card',
      isDanger: true,
    );

    if (confirm == true) {
      final res = await _repairRepository.deleteRepair(repair.id);
      if (mounted) {
        if (res.success) {
          AppFeedback.showSuccess(
            context,
            title: 'Job Card Deleted',
            message: 'Job Card ${repair.jobNumber} deleted successfully.',
          );
          _fetchRepairs();
        } else {
          AppFeedback.showError(
            context,
            error: res.message,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Summary Header & Integrated Compact Search/Filters
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          color: AppColors.primary,
          child: Column(
            children: [
              // Row 1: Compact 3-metric strip
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Total Bill',
                      value: '\u20B9 ${_totalRepairVolume.toStringAsFixed(0)}',
                      icon: Icons.receipt_long_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Amount Paid',
                      value: '\u20B9 ${_totalPaidSum.toStringAsFixed(0)}',
                      icon: Icons.check_circle_rounded,
                      color: Colors.greenAccent.shade400,
                      borderColor: Colors.greenAccent.withOpacity(0.4),
                      bgColor: Colors.greenAccent.withOpacity(0.15),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Total Due',
                      value: '\u20B9 ${_totalDueSum.toStringAsFixed(0)}',
                      icon: Icons.pending_actions_rounded,
                      color: _totalDueSum > 0 ? Colors.amberAccent.shade200 : Colors.white70,
                      borderColor: _totalDueSum > 0 ? Colors.amberAccent.withOpacity(0.5) : null,
                      bgColor: _totalDueSum > 0 ? Colors.amber.withOpacity(0.15) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Row 2: Ultra-compact Net Profit & Cost breakdown strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_rupee_rounded, size: 12, color: Colors.greenAccent),
                        Text('Net Profit: ', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                        Text('+\u20B9${_totalNetProfit.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                      ],
                    ),
                    const Text('|', style: TextStyle(color: Colors.white24, fontSize: 11)),
                    Text('Parts: \u20B9${_totalPartsCost.toStringAsFixed(0)}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10.5, fontWeight: FontWeight.bold)),
                    const Text('|', style: TextStyle(color: Colors.white24, fontSize: 11)),
                    Text('Tech: \u20B9${_totalTechCost.toStringAsFixed(0)}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Row 3: Compact Search & 2 Dropdowns (Status + Date)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _fetchRepairs(),
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11.5),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 16),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchRepairs();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Compact Status Dropdown button
                  InkWell(
                    onTap: _showStatusFilterBottomSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: _selectedStatus == 'all' ? Colors.white.withOpacity(0.2) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedStatus == 'all' ? Icons.filter_list_rounded : Icons.circle,
                            size: _selectedStatus == 'all' ? 14 : 9,
                            color: _selectedStatus == 'all' ? Colors.white : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedStatus == 'all' ? 'Status' : (_statusLabels[_selectedStatus] ?? 'Status'),
                            style: TextStyle(
                              color: _selectedStatus == 'all' ? Colors.white : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Compact Date Dropdown button
                  InkWell(
                    onTap: _showDateFilterBottomSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            _dateFilterLabel,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Repair Cards List
        Expanded(
          child: _isLoading
              ? AppShimmer.listLoading()
              : _errorMessage != null
                  ? AppEmptyState(
                      icon: Icons.error_outline,
                      title: 'Unable to Load Repairs',
                      description: _errorMessage!,
                      actionLabel: 'Retry',
                      onActionPressed: _fetchRepairs,
                    )
                  : _repairs.isEmpty
                      ? DateRangeEmptyState(
                          icon: Icons.build_circle_outlined,
                          entityName: 'Repairs',
                          datePreset: _datePreset,
                          dateFilterLabel: _dateFilterLabel,
                          hasActiveSearchOrFilter: _searchController.text.isNotEmpty || _selectedStatus != 'all',
                          onResetFilters: () {
                            setState(() {
                              _searchController.clear();
                              _selectedStatus = 'all';
                              _datePreset = 'all_time';
                            });
                            _fetchRepairs();
                          },
                          onSelectDatePreset: (preset) {
                            setState(() {
                              _datePreset = preset;
                              _customDateRange = null;
                            });
                            _fetchRepairs();
                          },
                          createActionLabel: '+ Create Repair',
                          onCreateAction: () {
                            SubscriptionGuard.checkLimit(context, LimitType.repair, () {
                              Navigator.pushNamed(context, AppRoutes.createRepair).then((_) => _fetchRepairs());
                            });
                          },
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    repair.jobNumber,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      color: AppColors.primary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(DateHelper.formatDate(repair.dateReceived),
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              StatusBadge(
                                                label: statusLabel,
                                                backgroundColor: statusColor,
                                                textColor: Colors.white,
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () => WhatsAppHelper.showRepairWhatsAppOptions(context, repair),
                                                borderRadius: BorderRadius.circular(16),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4.0),
                                                  child: WhatsAppIcon(size: 22),
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              InkWell(
                                                onTap: () => RepairInvoicePdfScreen.show(context, repair),
                                                borderRadius: BorderRadius.circular(16),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4.0),
                                                  child: Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.redAccent),
                                                ),
                                              ),
                                              const SizedBox(width: 2),
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
                                      if (!(repair.repairStatus == 'delivered' && (repair.technicianName == null || repair.technicianName!.trim().isEmpty))) ...[
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
                                      ],
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                                      const SizedBox(height: 7),
                                      _buildVyaparFinancialBox(repair),
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
              final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'create repair tickets');
              if (!ok || !context.mounted) return;
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
          final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'create repair tickets');
          if (!ok || !context.mounted) return;
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
    Color? borderColor,
    Color? bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : null,
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
                  style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVyaparFinancialBox(Repair repair) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;

    final double billed = repair.netCost;
    final double received = repair.amountPaid;
    final double due = repair.amountDue;
    final double partsCost = repair.partsCostTotal;
    final double techCost = repair.technicianCost;
    final double realizedProfit = repair.netProfit; // Strictly based on amountPaid!
    final double margin = repair.profitMarginPercent;
    final bool hasDue = due > 0;
    final bool isUnpaid = received <= 0 && hasDue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: hasDue
            ? (isDark ? const Color(0xFF2A1C16) : const Color(0xFFFFFDF7))
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasDue
              ? (isDark ? Colors.amber.shade900 : const Color(0xFFFDE68A))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Line 1: Bill, Paid, and Due / Full Paid
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 56, // card width minus inner paddings
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bill: ',
                        style: TextStyle(fontSize: 11.5, color: textMutedColor, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '\u20B9${billed.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: received > 0 ? const Color(0xFF059669) : textMutedColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Paid: ',
                        style: TextStyle(fontSize: 11.5, color: textMutedColor, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '\u20B9${received.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: received > 0 ? const Color(0xFF059669) : textColor,
                        ),
                      ),
                    ],
                  ),
                  if (hasDue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pending_actions_rounded, size: 11, color: Color(0xFFDC2626)),
                          const SizedBox(width: 3),
                          Text(
                            'Due: \u20B9${due.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Text(
                        'Full Paid',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Divider(
            height: 1,
            thickness: 0.6,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 5),
          // Line 2: Parts, Tech, and Realized Net Profit
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 12, color: textMutedColor),
                      const SizedBox(width: 2),
                      Text(
                        'Parts: ',
                        style: TextStyle(fontSize: 11, color: textMutedColor),
                      ),
                      Text(
                        '\u20B9${partsCost.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.engineering_outlined, size: 12, color: textMutedColor),
                      const SizedBox(width: 2),
                      Text(
                        'Tech: ',
                        style: TextStyle(fontSize: 11, color: textMutedColor),
                      ),
                      Text(
                        '\u20B9${techCost.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textColor),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Profit: ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isUnpaid ? AppColors.textMuted : const Color(0xFF047857),
                        ),
                      ),
                      Text(
                        isUnpaid
                            ? '\u20B90'
                            : '+\u20B9${realizedProfit.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isUnpaid ? AppColors.textSecondary : const Color(0xFF047857),
                        ),
                      ),
                      if (!isUnpaid && margin > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${margin.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

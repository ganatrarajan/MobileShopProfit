import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../repair/data/repair_repository.dart';
import '../../repair/presentation/repair_details_screen.dart';
import '../data/technician_repository.dart';

class TechnicianMyWorkScreen extends StatefulWidget {
  final int? technicianId;

  const TechnicianMyWorkScreen({super.key, this.technicianId});

  @override
  State<TechnicianMyWorkScreen> createState() => _TechnicianMyWorkScreenState();
}

class _TechnicianMyWorkScreenState extends State<TechnicianMyWorkScreen> {
  final TechnicianRepository _repository = TechnicianRepository();

  bool _isLoading = true;
  String? _errorMessage;
  TechnicianWorkSummaryData? _data;

  String _selectedMonth = 'this_month';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _repository.getMyWorkSummary(
        month: _selectedMonth,
        status: _selectedStatus,
      );

      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _data = res.data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = res.message;
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

  void _onMonthChanged(String newMonth) {
    if (_selectedMonth == newMonth) return;
    setState(() => _selectedMonth = newMonth);
    _loadData();
  }

  void _onStatusChanged(String newStatus) {
    if (_selectedStatus == newStatus) return;
    setState(() => _selectedStatus = newStatus);
    _loadData();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    String label = status.replaceAll('_', ' ').toUpperCase();

    if (['received', 'diagnosing', 'waiting_customer', 'waiting_parts', 'pending_approval'].contains(status)) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade900;
    } else if (['repairing', 'in_progress'].contains(status)) {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade900;
    } else if (['ready', 'delivered', 'completed'].contains(status)) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade900;
    } else if (['cancelled', 'unrepairable', 'cannot_repair'].contains(status)) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  String _getSelectedMonthLabel() {
    if (_selectedMonth == 'all') return 'All Time';
    if (_selectedMonth == 'this_month') return 'Current Month';
    final found = _data?.availableMonths.firstWhere(
      (m) => m.key == _selectedMonth,
      orElse: () => TechnicianMonthOption(key: _selectedMonth, label: _selectedMonth),
    );
    return found?.label ?? _selectedMonth;
  }

  Future<void> _showMonthPickerSheet() async {
    final months = _data?.availableMonths ?? [];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Select Work Period',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded, color: AppColors.primary),
                title: const Text('All Time', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: _selectedMonth == 'all' ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _onMonthChanged('all');
                },
              ),
              ListTile(
                leading: const Icon(Icons.today_rounded, color: AppColors.accent),
                title: const Text('Current Month', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: _selectedMonth == 'this_month' ? const Icon(Icons.check_circle_rounded, color: AppColors.accent) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _onMonthChanged('this_month');
                },
              ),
              if (months.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Past Months', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: months.length,
                    itemBuilder: (c, idx) {
                      final m = months[idx];
                      final isSelected = _selectedMonth == m.key;
                      return ListTile(
                        leading: const Icon(Icons.calendar_today_outlined, size: 20),
                        title: Text(m.label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          _onMonthChanged(m.key);
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Work & Profit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContentView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 54, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Failed to load technician work details',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              onPressed: _loadData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView() {
    final metrics = _data?.metrics ?? TechnicianWorkMetrics();
    final repairs = _data?.repairs ?? [];

    final filteredRepairs = _searchQuery.isEmpty
        ? repairs
        : repairs.where((r) {
            final query = _searchQuery.toLowerCase();
            return r.jobNumber.toLowerCase().contains(query) ||
                r.deviceName.toLowerCase().contains(query) ||
                r.customerName.toLowerCase().contains(query) ||
                r.problemDescription.toLowerCase().contains(query);
          }).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. Technician Profile Banner & Month Selector
          _buildTopBanner(),
          const SizedBox(height: 14),

          // 2. Financial Metrics Cards Grid
          _buildMetricsSection(metrics),
          const SizedBox(height: 16),

          // 3. Search & Status Filter Chips
          _buildSearchAndFilters(metrics),
          const SizedBox(height: 12),

          // 4. Jobs Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assigned Repair Jobs (${filteredRepairs.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                _getSelectedMonthLabel(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 5. Jobs List
          if (filteredRepairs.isEmpty)
            _buildEmptyState()
          else
            ...filteredRepairs.map((job) => _buildJobCard(job)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    final techName = _data?.technicianName ?? 'Technician';
    final spec = _data?.specialization;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x204F46E5),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(Icons.handyman_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      techName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    if (spec != null && spec.isNotEmpty)
                      Text(
                        '🔧 $spec',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                  ],
                ),
              ),
              // Month Selector Pill
              InkWell(
                onTap: _showMonthPickerSheet,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _getSelectedMonthLabel(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
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

  Widget _buildMetricsSection(TechnicianWorkMetrics metrics) {
    return Column(
      children: [
        // Top 2 Big Cards: My Profit & Balance Due
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'My Profit (Period)',
                value: '\u{20B9}${metrics.periodEarnings.toStringAsFixed(2)}',
                subtitle: 'Earnings from repairs',
                icon: Icons.payments_rounded,
                accentColor: AppColors.accent,
                bgLight: AppColors.accentLight.withOpacity(0.4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Pending Balance',
                value: '\u{20B9}${metrics.balanceDue.toStringAsFixed(2)}',
                subtitle: metrics.balanceDue > 0 ? 'Due from shop owner' : 'All accounts settled',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: metrics.balanceDue > 0 ? Colors.orange.shade800 : Colors.teal,
                bgLight: metrics.balanceDue > 0 ? Colors.orange.shade50 : Colors.teal.shade50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Bottom 2 Secondary Cards: Total Received & Workload
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Received',
                value: '\u{20B9}${metrics.allTimePaid.toStringAsFixed(2)}',
                subtitle: 'Payouts received',
                icon: Icons.check_circle_outline_rounded,
                accentColor: AppColors.primary,
                bgLight: AppColors.primary.withOpacity(0.08),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Jobs Handled',
                value: '${metrics.periodJobs}',
                subtitle: '✅ ${metrics.periodCompleted}  ⚡ ${metrics.periodInProgress}  ⏳ ${metrics.periodPending}',
                icon: Icons.build_circle_rounded,
                accentColor: Colors.blue.shade700,
                bgLight: Colors.blue.shade50,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgLight,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgLight, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(TechnicianWorkMetrics metrics) {
    return Column(
      children: [
        // Search Input
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search jobs by ID, device, or customer...',
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
        const SizedBox(height: 10),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'All (${metrics.periodJobs})'),
              const SizedBox(width: 8),
              _buildFilterChip('completed', 'Completed (${metrics.periodCompleted})'),
              const SizedBox(width: 8),
              _buildFilterChip('in_progress', 'In Progress (${metrics.periodInProgress})'),
              const SizedBox(width: 8),
              _buildFilterChip('pending', 'Pending (${metrics.periodPending})'),
              const SizedBox(width: 8),
              _buildFilterChip('cancelled', 'Cancelled'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatus == key;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => _onStatusChanged(key),
    );
  }

  Widget _buildJobCard(TechnicianJobItem job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
            try {
              final res = await RepairRepository().getRepairDetails(job.id);
              if (mounted) Navigator.pop(context);
              if (mounted && res.success && res.data != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RepairDetailsScreen(repair: res.data!)),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Could not open repair details')),
                );
              }
            } catch (e) {
              if (mounted) Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Job Number & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          job.jobNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(job.repairStatus),
                  ],
                ),
                const SizedBox(height: 8),

                // Device & Customer Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.phone_android_rounded, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.deviceName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '👤 ${job.customerName}${job.customerMobile != null ? ' (${job.customerMobile})' : ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (job.problemDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔧 ', style: TextStyle(fontSize: 11)),
                        Expanded(
                          child: Text(
                            job.problemDescription,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 16),

                // Bottom row: Date & Technician Profit Highlight
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(job.createdAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            'My Profit: \u{20B9}${job.technicianEarning.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.build_circle_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'No Repair Jobs Found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'No repair jobs match "${_getSelectedMonthLabel()}" with filter "${_selectedStatus.toUpperCase()}".',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

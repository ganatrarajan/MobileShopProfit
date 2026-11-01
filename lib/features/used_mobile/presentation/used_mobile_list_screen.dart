import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/date_helper.dart';
import '../../../../core/utils/used_mobile_export_helper.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/whatsapp_icon.dart';
import '../../subscription/utils/subscription_guard.dart';
import '../data/used_mobile_repository.dart';
import '../models/used_mobile.dart';
import '../models/used_mobile_stats.dart';
import 'buy_used_mobile_screen.dart';
import 'used_mobile_details_screen.dart';
import 'used_mobile_pdf_screen.dart';
import 'widgets/add_repair_expense_modal.dart';
import 'widgets/sell_used_mobile_modal.dart';

class UsedMobileListScreen extends StatefulWidget {
  const UsedMobileListScreen({super.key});

  @override
  State<UsedMobileListScreen> createState() => UsedMobileListScreenState();
}

class UsedMobileListScreenState extends State<UsedMobileListScreen> {
  final UsedMobileRepository _repo = UsedMobileRepository();
  final TextEditingController _searchController = TextEditingController();

  List<UsedMobile> _mobiles = [];
  UsedMobileStats _stats = UsedMobileStats.empty();
  bool _isLoading = true;
  String _selectedFilter = 'in_stock'; // default: in_stock for showroom
  String _selectedBrand = 'all'; // all, or specific brand filter
  bool _isKpiExpanded = false; // collapsible by default to save 60% of the screen
  bool _hasParsedArgs = false;
  Timer? _debounceTimer;

  // Date Filtering state (defaults to 'this_month' matching other modules)
  String _datePreset = 'this_month';
  DateTimeRange? _customDateRange;

  void applyDateFilter(String period, DateTimeRange? customRange) {
    if (_datePreset != period || _customDateRange != customRange) {
      setState(() {
        _datePreset = period;
        _customDateRange = customRange;
      });
      fetchMobiles();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasParsedArgs) {
      _hasParsedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map) {
        if (args.containsKey('period')) {
          _datePreset = args['period'].toString();
        }
        if (args.containsKey('customRange') && args['customRange'] is DateTimeRange) {
          _customDateRange = args['customRange'] as DateTimeRange;
        }
      }
      fetchMobiles();
    }
  }

  Map<String, int> get _brandCounts {
    final Map<String, int> counts = {};
    for (final m in _mobiles) {
      final b = m.brand.trim();
      if (b.isNotEmpty) {
        counts[b] = (counts[b] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<UsedMobile> get _filteredMobiles {
    if (_selectedBrand == 'all') {
      return _mobiles;
    }
    return _mobiles.where((m) => m.brand.trim().toLowerCase() == _selectedBrand.trim().toLowerCase()).toList();
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
                    fetchMobiles();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.today_rounded),
                  title: const Text('Today'),
                  trailing: _datePreset == 'today' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'today');
                    fetchMobiles();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('Yesterday'),
                  trailing: _datePreset == 'yesterday' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'yesterday');
                    fetchMobiles();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_view_month_rounded),
                  title: const Text('This Month'),
                  trailing: _datePreset == 'this_month' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'this_month');
                    fetchMobiles();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('Last Month'),
                  trailing: _datePreset == 'last_month' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'last_month');
                    fetchMobiles();
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
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: _customDateRange,
                    );
                    if (picked != null) {
                      setState(() {
                        _customDateRange = picked;
                        _datePreset = 'custom';
                      });
                      fetchMobiles();
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      fetchMobiles();
    });
  }

  Future<void> fetchMobiles({int page = 1}) async {
    setState(() => _isLoading = true);

    final res = await _repo.getUsedMobiles(
      status: _selectedFilter == 'all' ? null : _selectedFilter,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      page: page,
    );

    if (mounted) {
      setState(() {
        _mobiles = res.mobiles;
        _stats = res.stats;
        _isLoading = false;
        if (_selectedBrand != 'all' && !_brandCounts.containsKey(_selectedBrand)) {
          _selectedBrand = 'all';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Used Mobiles (Buy & Sell)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            tooltip: 'Export Excel & Reports',
            onPressed: _showExportOptionsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: fetchMobiles,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchMobiles,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Top KPI Banner (Lifetime summary of stock, sales & profit)
            SliverToBoxAdapter(
              child: _buildKpiSection(isDark),
            ),

            // Search Bar & Filter Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search Brand, Model, IMEI, Ref #...',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                                      onPressed: () {
                                        _searchController.clear();
                                        fetchMobiles();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDark ? AppColors.darkSurface : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _showDateFilterBottomSheet,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                    const SizedBox(height: 10),
                    _buildFilterTabs(isDark),
                    const SizedBox(height: 8),
                    _buildBrandAndExportToolbar(isDark),
                  ],
                ),
              ),
            ),

            // Mobile Cards List
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_mobiles.isEmpty)
              SliverFillRemaining(
                child: AppEmptyState(
                  icon: Icons.phone_android_rounded,
                  title: 'No Used Mobiles Found',
                  message: _searchController.text.isNotEmpty
                      ? 'No devices match "${_searchController.text}". Try another search.'
                      : 'You haven\'t logged any old mobile purchases yet.\nTap below to buy an old phone from a customer!',
                  actionLabel: '+ Buy Old Mobile',
                  onAction: () => _navigateToAdd(context),
                ),
              )
            else if (_filteredMobiles.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt_off_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'No devices found for "$_selectedBrand"',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap below to show all available brands.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: () => setState(() => _selectedBrand = 'all'),
                          child: const Text('View All Brands'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildMobileCard(_filteredMobiles[i], isDark),
                    childCount: _filteredMobiles.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'buy_used_mobile_fab',
        onPressed: () => _navigateToAdd(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: const Text(
          'Buy Old Mobile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Future<void> _navigateToAdd(BuildContext context) async {
    final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'purchase used mobiles');
    if (!ok || !context.mounted) return;

    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BuyUsedMobileScreen()),
    );
    if (res == true) {
      fetchMobiles();
    }
  }

  Widget _buildKpiSection(bool isDark) {
    final periodTag = _datePreset == 'all_time' ? 'All Time' : _dateFilterLabel;

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState: _isKpiExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.phone_android_rounded, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_stats.inStockCount} In Stock',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 6),
                    Text(
                      '₹${_stats.inStockInvestment.toStringAsFixed(0)} Value',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (_stats.soldCount > 0) ...[
                      const SizedBox(width: 6),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 6),
                      Text(
                        '${_stats.soldCount} Sold',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.accent),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => setState(() => _isKpiExpanded = true),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Overview',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.blue.shade700),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      secondChild: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_rounded, size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Business Summary ($periodTag)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => setState(() => _isKpiExpanded = false),
                  child: const Row(
                    children: [
                      Text('Hide', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'In Stock Devices',
                    value: '${_stats.inStockCount} Units',
                    subtitle: 'Invested: ₹${_stats.inStockInvestment.toStringAsFixed(0)}',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Net Profit',
                    value: '₹${_stats.totalProfitEarned.toStringAsFixed(0)}',
                    subtitle: '$periodTag | ${_stats.profitMarginPercentage.toStringAsFixed(1)}% ROI',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.accent,
                    isDark: isDark,
                    isHighlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Sold Revenue',
                    value: '₹${_stats.totalSaleRevenue.toStringAsFixed(0)}',
                    subtitle: '$periodTag (${_stats.soldCount} Sold)',
                    icon: Icons.point_of_sale_rounded,
                    color: Colors.blue.shade700,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Purchased',
                    value: '${_stats.totalPurchasedCount} Phones',
                    subtitle: '$periodTag (₹${_stats.totalPurchasedAmount.toStringAsFixed(0)})',
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.indigo,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight ? color.withOpacity(0.5) : (isDark ? AppColors.darkBorder : AppColors.border),
          width: isHighlight ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isHighlight ? color : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    final tabs = [
      {'id': 'in_stock', 'label': 'In Stock (${_stats.inStockCount})'},
      {'id': 'sold', 'label': 'Sold (${_stats.soldCount})'},
      {'id': 'all', 'label': 'All (${_stats.totalPurchasedCount})'},
    ];

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
      ),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _selectedFilter == t['id'];
          final isSold = t['id'] == 'sold';
          final activeColor = isSold ? AppColors.accent : AppColors.primary;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedFilter != t['id']) {
                  setState(() {
                    _selectedFilter = t['id']!;
                    _selectedBrand = 'all';
                  });
                  fetchMobiles();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  t['label']!,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey.shade300 : AppColors.textSecondary),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showBrandFilterBottomSheet(bool isDark) {
    final brandMap = _brandCounts;
    final sortedBrands = brandMap.keys.toList()..sort();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final displayedBrands = sortedBrands.where((b) {
              if (searchQuery.trim().isEmpty) return true;
              return b.toLowerCase().contains(searchQuery.trim().toLowerCase());
            }).toList();

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.branding_watermark_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Mobile Brand',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '${_brandCounts.length} brands available in stock',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search input if multiple brands
                    if (sortedBrands.length > 5) ...[
                      TextField(
                        onChanged: (val) {
                          setModalState(() => searchQuery = val);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search brand name...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                          filled: true,
                          fillColor: isDark ? AppColors.darkBackground : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Brand List
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // "All Brands" option
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _selectedBrand == 'all'
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkBorder : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.category_rounded,
                                size: 18,
                                color: _selectedBrand == 'all' ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                            title: const Text(
                              'All Brands',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${_mobiles.length} total devices',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            trailing: _selectedBrand == 'all'
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 22)
                                : null,
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() => _selectedBrand = 'all');
                            },
                          ),
                          const Divider(height: 8),

                          // Brand items
                          if (displayedBrands.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'No brands match "$searchQuery"',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                ),
                              ),
                            )
                          else
                            ...displayedBrands.map((b) {
                              final count = brandMap[b] ?? 0;
                              final isSelected = _selectedBrand.toLowerCase() == b.toLowerCase();

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.15)
                                        : (isDark ? AppColors.darkBackground : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    b.isNotEmpty ? b[0].toUpperCase() : '📱',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  b,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected ? AppColors.primary : null,
                                  ),
                                ),
                                subtitle: Text(
                                  '$count ${count == 1 ? "device" : "devices"} in stock',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 22)
                                    : null,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() => _selectedBrand = b);
                                },
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBrandAndExportToolbar(bool isDark) {
    final isSoldTab = _selectedFilter == 'sold';
    final count = _mobiles.length;

    return Row(
      children: [
        // Brand Selector (Opens Modal Bottom Sheet)
        Expanded(
          child: InkWell(
            onTap: () => _showBrandFilterBottomSheet(isDark),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedBrand == 'all' ? Icons.category_rounded : Icons.branding_watermark_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selectedBrand == 'all'
                          ? 'All Brands ($count)'
                          : '$_selectedBrand (${_brandCounts[_selectedBrand] ?? 0})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Excel Download Button
        InkWell(
          onTap: () async {
            if (_mobiles.isEmpty) {
              AppFeedback.showError(
                context,
                title: 'No Records',
                message: 'No devices found to download in this tab.',
              );
              return;
            }
            if (isSoldTab) {
              await UsedMobileExportHelper.exportSalesToExcel(context, _mobiles);
            } else {
              await UsedMobileExportHelper.exportPurchasesToExcel(context, _mobiles);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF107C41).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF107C41).withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, size: 15, color: Color(0xFF107C41)),
                SizedBox(width: 4),
                Text(
                  'Excel',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF107C41)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),

        // PDF Download Button
        InkWell(
          onTap: () async {
            if (_mobiles.isEmpty) {
              AppFeedback.showError(
                context,
                title: 'No Records',
                message: 'No devices found to download report in this tab.',
              );
              return;
            }
            if (isSoldTab) {
              await UsedMobileExportHelper.downloadSalesPdf(context, _mobiles);
            } else {
              await UsedMobileExportHelper.downloadPurchasesPdf(context, _mobiles);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, size: 15, color: Colors.red),
                SizedBox(width: 4),
                Text(
                  'PDF',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleExportSheetAction({
    required BuildContext parentContext,
    required bool isSales,
    required bool isExcel,
  }) async {
    // Show a small progress dialog while fetching dataset
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 3),
                SizedBox(width: 18),
                Text('Preparing Report...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final res = await _repo.getUsedMobiles(
        status: isSales ? 'sold' : null,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        perPage: 1000,
      );

      if (!parentContext.mounted) return;
      Navigator.of(parentContext, rootNavigator: true).pop(); // dismiss loading dialog

      final items = isSales
          ? res.mobiles.where((m) => m.status == 'sold').toList()
          : res.mobiles;

      if (items.isEmpty) {
        AppFeedback.showError(
          parentContext,
          title: 'No Data Found',
          message: isSales ? 'No sold phone records found for this period.' : 'No purchase records found for this period.',
        );
        return;
      }

      if (isExcel) {
        if (isSales) {
          await UsedMobileExportHelper.exportSalesToExcel(parentContext, items);
        } else {
          await UsedMobileExportHelper.exportPurchasesToExcel(parentContext, items);
        }
      } else {
        if (isSales) {
          await UsedMobileExportHelper.downloadSalesPdf(parentContext, items);
        } else {
          await UsedMobileExportHelper.downloadPurchasesPdf(parentContext, items);
        }
      }
    } catch (e) {
      if (parentContext.mounted) {
        Navigator.of(parentContext, rootNavigator: true).pop(); // dismiss loading dialog if still open
        AppFeedback.showError(
          parentContext,
          title: 'Download Failed',
          message: 'Error preparing export: $e',
        );
      }
    }
  }

  void _showExportOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.file_download_outlined, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Download Reports to Device',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Directly download records for $_dateFilterLabel to phone storage:',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  // Purchases Section
                  const Text('1. Purchased Mobiles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF107C41).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.download_rounded, color: Color(0xFF107C41), size: 20),
                    ),
                    title: const Text('Download Purchases Excel (.csv)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Save bought phones list directly to device Downloads folder'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleExportSheetAction(parentContext: context, isSales: false, isExcel: true);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20),
                    ),
                    title: const Text('Download Purchases Summary PDF Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Save printable branded inventory PDF to device Downloads folder'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleExportSheetAction(parentContext: context, isSales: false, isExcel: false);
                    },
                  ),
                  const Divider(height: 20),
                  // Sales Section
                  const Text('2. Sold Mobiles & Profit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent)),
                  const SizedBox(height: 6),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF107C41).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.download_rounded, color: Color(0xFF107C41), size: 20),
                    ),
                    title: const Text('Download Sold Phones & Profit Excel (.csv)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Save sales invoices, buyer details & profits to Downloads'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleExportSheetAction(parentContext: context, isSales: true, isExcel: true);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20),
                    ),
                    title: const Text('Download Sales & Net Profit PDF Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Save official sales & profit ledger PDF to device Downloads folder'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleExportSheetAction(parentContext: context, isSales: true, isExcel: false);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileCard(UsedMobile mobile, bool isDark) {
    final isSold = mobile.isSold;
    final profit = mobile.profit ?? 0.0;
    final specs = [
      if (mobile.storage != null && mobile.storage!.isNotEmpty) mobile.storage!,
      if (mobile.ram != null && mobile.ram!.isNotEmpty) mobile.ram!,
      if (mobile.color != null && mobile.color!.isNotEmpty) mobile.color!,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSold ? AppColors.accent.withOpacity(0.35) : (isDark ? AppColors.darkBorder : AppColors.border),
          width: isSold ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UsedMobileDetailsScreen(mobile: mobile),
            ),
          );
          if (result == true) fetchMobiles();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand Initial / Logo Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSold
                      ? AppColors.accent.withOpacity(0.12)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSold
                        ? AppColors.accent.withOpacity(0.25)
                        : AppColors.primary.withOpacity(0.2),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  mobile.brand.isNotEmpty ? mobile.brand[0].toUpperCase() : '📱',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: isSold ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Device Details (Company/Model, Storage/Color, Condition)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand & Model
                    Text(
                      '${mobile.brand} ${mobile.model}',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // RAM / Storage / Color
                    Text(
                      specs.isNotEmpty ? specs : 'Standard Spec',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Condition Pill & Status/Battery
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          ),
                          child: Text(
                            mobile.conditionLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade300 : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (mobile.batteryHealth != null && mobile.batteryHealth!.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              '🔋 ${mobile.batteryHealth}',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                            ),
                          ),
                        ],
                        if (isSold) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'SOLD',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Price & Action Button Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSold) ...[
                    // In-Stock: Cost / Value Price
                    Text(
                      '₹${mobile.totalCost.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                    const SizedBox(height: 5),
                    // Quick Sell Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 14),
                      label: const Text('Sell', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                      onPressed: () {
                        SellUsedMobileModal.show(context, mobile, onSaleComplete: fetchMobiles);
                      },
                    ),
                  ] else ...[
                    // Sold: Selling Price & Profit
                    Text(
                      '₹${(mobile.sellingPrice ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: profit >= 0 ? AppColors.accent.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${profit >= 0 ? "+" : "-"}₹${profit.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: profit >= 0 ? AppColors.accent : AppColors.error,
                        ),
                      ),
                    ),
                  ],

                  // More Menu (PDF, WhatsApp, Repair, Details)
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == 'pdf') {
                        UsedMobilePdfScreen.show(
                          context,
                          mobile,
                          isSold ? UsedMobilePdfType.saleInvoice : UsedMobilePdfType.purchaseAgreement,
                        );
                      } else if (val == 'whatsapp') {
                        if (isSold) {
                          WhatsAppHelper.sendUsedMobileSaleWhatsAppMessage(context, mobile);
                        } else {
                          WhatsAppHelper.sendUsedMobilePurchaseWhatsAppMessage(context, mobile);
                        }
                      } else if (val == 'repair') {
                        AddRepairExpenseModal.show(context, mobile, onExpenseAdded: fetchMobiles);
                      } else if (val == 'details') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => UsedMobileDetailsScreen(mobile: mobile)),
                        ).then((res) {
                          if (res == true) fetchMobiles();
                        });
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('View Full Details', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(isSold ? 'Sale Invoice PDF' : 'Purchase Agreement PDF', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'whatsapp',
                        child: Row(
                          children: [
                            WhatsAppIcon(size: 16),
                            SizedBox(width: 8),
                            Text('Send on WhatsApp', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (!isSold)
                        PopupMenuItem(
                          value: 'repair',
                          child: Row(
                            children: [
                              Icon(Icons.build_circle_rounded, size: 16, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              const Text('Add Repair Expense', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


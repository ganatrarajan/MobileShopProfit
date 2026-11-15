import 'package:flutter/material.dart';
import '../../../core/services/profit_visibility_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/profit_ledger_export_helper.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/custom_card.dart';
import '../data/profit_ledger_repository.dart';
import '../models/profit_ledger_model.dart';

class ProfitLedgerScreen extends StatefulWidget {
  final String initialPeriod;
  final DateTimeRange? initialDateRange;
  final String shopName;

  const ProfitLedgerScreen({
    super.key,
    this.initialPeriod = 'this_month',
    this.initialDateRange,
    this.shopName = 'Mobile Repair Shop',
  });

  @override
  State<ProfitLedgerScreen> createState() => _ProfitLedgerScreenState();
}

class _ProfitLedgerScreenState extends State<ProfitLedgerScreen> {
  final ProfitLedgerRepository _repository = ProfitLedgerRepository();

  late String _selectedPeriod;
  DateTimeRange? _customDateRange;
  String _selectedCategory = 'all'; // 'all', 'sales', 'repairs', 'used_mobiles'
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  ProfitLedgerResponse? _ledgerData;

  final List<Map<String, String>> _periodOptions = [
    {'key': 'today', 'label': 'Today'},
    {'key': 'this_week', 'label': 'This Week'},
    {'key': 'this_month', 'label': 'This Month'},
    {'key': 'last_month', 'label': 'Last Month'},
    {'key': 'this_year', 'label': 'This Year'},
    {'key': 'all_time', 'label': 'All Time'},
    {'key': 'custom', 'label': 'Custom'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    _customDateRange = widget.initialDateRange;
    _fetchLedger();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLedger() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? sDate;
    String? eDate;
    if (_selectedPeriod == 'custom' && _customDateRange != null) {
      final s = _customDateRange!.start;
      final e = _customDateRange!.end;
      sDate = '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
      eDate = '${e.year}-${e.month.toString().padLeft(2, '0')}-${e.day.toString().padLeft(2, '0')}';
    }

    final res = await _repository.getProfitLedger(
      period: _selectedPeriod,
      category: _selectedCategory,
      startDate: sDate,
      endDate: eDate,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _ledgerData = res.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _customDateRange = picked;
      });
      _fetchLedger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search reference, customer, item...',
                  hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  _searchQuery = val;
                  _fetchLedger();
                },
              )
            : const Text(
                'Net Profit Breakdown',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.white),
            tooltip: _isSearching ? 'Close Search' : 'Search Ledger',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                  _fetchLedger();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          const ProfitVisibilityToggle(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            tooltip: 'Download Report',
            onSelected: (val) {
              if (_ledgerData == null) {
                AppFeedback.showError(context, message: 'No data to export.');
                return;
              }
              if (val == 'pdf') {
                ProfitLedgerExportHelper.exportToPdf(
                  context: context,
                  data: _ledgerData!,
                  shopName: widget.shopName,
                );
              } else if (val == 'excel') {
                ProfitLedgerExportHelper.exportToCsv(
                  context: context,
                  data: _ledgerData!,
                  shopName: widget.shopName,
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Download PDF Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_rounded, color: Color(0xFF059669), size: 20),
                    SizedBox(width: 10),
                    Text('Download Excel / CSV (.csv)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLedger,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Filter Header
              _buildPeriodSelector(),

              // Category Selector Tabs
              _buildCategorySelector(),

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AppShimmer.detailsLoading(),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(_errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        ElevatedButton(
                            onPressed: _fetchLedger, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (_ledgerData != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Hero Net Profit Summary Card
                      _buildHeroProfitCard(_ledgerData!.summary),
                      const SizedBox(height: 16),

                      // Listing Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profit Transactions (${_ledgerData!.items.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => ProfitLedgerExportHelper.exportToPdf(
                                  context: context,
                                  data: _ledgerData!,
                                  shopName: widget.shopName,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.picture_as_pdf_rounded, size: 13, color: Colors.redAccent),
                                      SizedBox(width: 4),
                                      Text('PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => ProfitLedgerExportHelper.exportToCsv(
                                  context: context,
                                  data: _ledgerData!,
                                  shopName: widget.shopName,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.table_chart_rounded, size: 13, color: Color(0xFF059669)),
                                      SizedBox(width: 4),
                                      Text('Excel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Transactions List
                      if (_ledgerData!.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: AppEmptyState(
                            title: 'No Profit Records Found',
                            description:
                                'No completed sales, repairs, or used mobile deals recorded for the selected period.',
                            icon: Icons.monetization_on_outlined,
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _ledgerData!.items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            return _buildTransactionCard(_ledgerData!.items[i], isDark);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _periodOptions.map((opt) {
            final isSelected = _selectedPeriod == opt['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () {
                  if (opt['key'] == 'custom') {
                    _selectCustomDateRange();
                  } else {
                    setState(() {
                      _selectedPeriod = opt['key']!;
                    });
                    _fetchLedger();
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    opt['label']!,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'key': 'all', 'label': 'All Profits'},
      {'key': 'sales', 'label': 'Sales'},
      {'key': 'repairs', 'label': 'Repairs'},
      {'key': 'used_mobiles', 'label': 'Used Mobiles'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: categories.map((c) {
          final isSelected = _selectedCategory == c['key'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = c['key']!;
                  });
                  _fetchLedger();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkSurface
                            : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    c['label']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroProfitCard(ProfitLedgerSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.monetization_on_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'TOTAL NET PROFIT',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${summary.totalCount} DEALS',
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Combined Profit (Repairs + Sales + Used Mobiles)',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5),
          ),
          const SizedBox(height: 2),
          ProfitText(
            amount: summary.totalNetProfit,
            prefix: '₹',
            decimals: 2,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),

          // Mini 3-Column Profit Source Cards
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sales Profit',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                          const SizedBox(height: 2),
                          ProfitText(
                            amount: summary.salesProfit,
                            decimals: 0,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text('${summary.salesCount} sold',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Repair Profit',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                          const SizedBox(height: 2),
                          ProfitText(
                            amount: summary.repairProfit,
                            decimals: 0,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text('${summary.repairCount} jobs',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Used Mob. Profit',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                          const SizedBox(height: 2),
                          ProfitText(
                            amount: summary.usedMobileProfit,
                            decimals: 0,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text('${summary.usedMobileCount} phones',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Revenue: \u20B9${summary.totalRevenue.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Total Costs: \u20B9${summary.totalCost.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(ProfitLedgerItem item, bool isDark) {
    Color typeColor;
    IconData typeIcon;

    if (item.type == 'repair') {
      typeColor = AppColors.warning;
      typeIcon = Icons.build_circle_rounded;
    } else if (item.type == 'used_mobile') {
      typeColor = const Color(0xFF0284C7);
      typeIcon = Icons.phone_android_rounded;
    } else {
      typeColor = AppColors.primary;
      typeIcon = Icons.point_of_sale_rounded;
    }

    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Type badge, Ref number, Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: typeColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 12, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          item.typeLabel.toUpperCase(),
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: typeColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.refNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ],
              ),
              Text(
                item.formattedDate,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title / Device Details
          Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Customer Info
          Text(
            '${item.customerName}${item.customerPhone.isNotEmpty ? " • ${item.customerPhone}" : ""}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Financial Breakdown Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Revenue', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      '\u20B9${item.revenue.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cost', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      '\u20B9${item.cost.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Profit: ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                      ProfitText(
                        amount: item.profit,
                        prefix: '₹',
                        showSign: true,
                        decimals: 0,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


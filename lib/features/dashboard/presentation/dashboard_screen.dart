import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_error_mapper.dart';
import '../../../core/widgets/custom_card.dart';
import '../../profit_intelligence/data/profit_intelligence_repository.dart';
import '../../profit_intelligence/domain/profit_intelligence_models.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_data.dart';
import '../../subscription/utils/subscription_guard.dart';
import 'widgets/dashboard_drawer.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onTabSelected;

  const DashboardScreen({super.key, this.onTabSelected});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  void _navigateToTab(int tabIndex, String fallbackRoute) {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(tabIndex);
    } else {
      Navigator.pushNamed(context, fallbackRoute);
    }
  }

  final DashboardRepository _dashboardRepository = DashboardRepository();

  String _selectedPeriod = 'this_month';
  DateTimeRange? _customDateRange;

  bool _isLoading = true;
  String? _errorMessage;
  DashboardData? _dashboardData;
  ProfitIntelligenceData? _profitAiData;
  bool _hasShownExpiryDialog = false;

  String _storedShopName = '';
  String _storedOwnerName = '';

  @override
  void initState() {
    super.initState();
    _loadStoredShopInfo();
    fetchDashboard();
  }

  Future<void> _loadStoredShopInfo() async {
    try {
      final shop = await AuthStorage().getShop();
      final user = await AuthStorage().getUser();
      if (mounted) {
        setState(() {
          if (shop != null && shop['name'] != null && shop['name'].toString().isNotEmpty) {
            _storedShopName = shop['name'].toString();
          }
          if (user != null && user['name'] != null && user['name'].toString().isNotEmpty) {
            _storedOwnerName = user['name'].toString();
          }
        });
      }
    } catch (_) {}
  }

  void _onPeriodSelected(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    fetchDashboard();
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'custom';
      });
      fetchDashboard();
    }
  }

  String? get _startDateStr {
    if (_selectedPeriod == 'custom' && _customDateRange != null) {
      final s = _customDateRange!.start;
      return '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
    }
    return null;
  }

  String? get _endDateStr {
    if (_selectedPeriod == 'custom' && _customDateRange != null) {
      final e = _customDateRange!.end;
      return '${e.year}-${e.month.toString().padLeft(2, '0')}-${e.day.toString().padLeft(2, '0')}';
    }
    return null;
  }

  Future<void> fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch Profit AI data
      try {
        final profitRes = await ProfitIntelligenceRepository().getSummary();
        if (profitRes.success && profitRes.data != null) {
          _profitAiData = profitRes.data;
        }
      } catch (_) {}

      // Fetch Dashboard metrics
      final res = await _dashboardRepository.getDashboardData(
        period: _selectedPeriod,
        startDate: _startDateStr,
        endDate: _endDateStr,
      );

      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _dashboardData = res.data!;
            _isLoading = false;
          });

          if (_dashboardData != null && (_dashboardData!.daysRemaining <= 10 || _dashboardData!.isExpiringSoon) && !_hasShownExpiryDialog) {
            _hasShownExpiryDialog = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showSubscriptionExpiryDialog(_dashboardData!.daysRemaining);
            });
          }
        } else {
          setState(() {
            _errorMessage = AppErrorMapper.mapMessage(res.message);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppErrorMapper.mapMessage(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;

    final String shopName = (_dashboardData?.shopName != null &&
            _dashboardData!.shopName.isNotEmpty &&
            _dashboardData!.shopName != 'Mobile Repair Shop')
        ? _dashboardData!.shopName
        : (_storedShopName.isNotEmpty ? _storedShopName : 'Mobile Repair Shop');

    final String ownerName = (_dashboardData?.ownerName != null &&
            _dashboardData!.ownerName.isNotEmpty &&
            _dashboardData!.ownerName != 'Shop Owner')
        ? _dashboardData!.ownerName
        : (_storedOwnerName.isNotEmpty ? _storedOwnerName : 'Shop Owner');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shopName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Welcome back, $ownerName', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: fetchDashboard,
          ),
        ],
      ),
      drawer: DashboardDrawer(
        shopName: shopName,
        ownerName: ownerName,
        onTabSelected: widget.onTabSelected,
      ),
      body: RefreshIndicator(
        onRefresh: fetchDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Filter Header Bar
              _buildPeriodFilterBar(),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: fetchDashboard, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (_dashboardData != null) ...[
                if (_dashboardData!.isEmptyShop)
                  _buildEmptyShopOnboarding()
                else ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subscription Expiry Highlight Card
                        if (_dashboardData!.daysRemaining <= 10 || _dashboardData!.isExpiringSoon)
                          _buildSubscriptionHighlightCard(_dashboardData!.daysRemaining),

                        // 1. TOP USP: Profit AI Business Assistant Banner
                        _buildTopProfitAiBanner(),
                        const SizedBox(height: 20),

                        // 2. Fast Creation Actions Section (Quick Daily Tasks)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.3)),
                            Text('Tap to create', style: TextStyle(fontSize: 11, color: textMutedColor)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildFastActionsGrid(),
                        const SizedBox(height: 20),

                        // 3. Financial Overview & Net Profit Card
                        _buildFinancialSummaryCard(_dashboardData!.financialOverview),
                        const SizedBox(height: 16),

                        // 4. Shop Performance Metrics Summary (Outstanding, Collected & Pending Overview)
                        Text('Shop Performance Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.3)),
                        const SizedBox(height: 10),
                        _buildSalesSummaryCard(_dashboardData!.sales),
                        const SizedBox(height: 12),
                        _buildPurchaseSummaryCard(_dashboardData!.purchases),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(child: _buildRepairSummaryCard(_dashboardData!.repairs)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInventorySummaryCard(_dashboardData!.inventory)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildExpenseSummaryCard(_dashboardData!.expenses),
                        const SizedBox(height: 24),

                        // 5. Organized Business Management Modules
                        Text('Business Management Modules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Text('Select a module to manage records, invoices, stock & customers.', style: TextStyle(fontSize: 11.5, color: textMutedColor)),
                        const SizedBox(height: 12),
                        _buildStructuredModulesList(),
                        const SizedBox(height: 20),

                        // 6. Needs Attention Section
                        if (_dashboardData!.attention.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                              const SizedBox(width: 6),
                              Text('Needs Attention', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.3)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                child: Text('${_dashboardData!.attention.length} items', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ..._dashboardData!.attention.map((item) => _buildAttentionCard(item)),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // TOP USP BANNER: Profit AI Business Assistant
  Widget _buildTopProfitAiBanner() {
    final healthScore = _profitAiData?.health.score ?? 85;
    final rating = _profitAiData?.health.rating ?? 'Good';
    final extraProfit = _profitAiData?.potentialExtraProfit ?? 0.0;
    final extraProfitFormatted = _profitAiData?.potentialExtraProfitFormatted ?? 'Analyze your shop profit leaks in real time.';

    Color ratingBgColor = healthScore >= 80 ? AppColors.accent : (healthScore >= 60 ? AppColors.warning : AppColors.error);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.auto_awesome_rounded, color: Color(0xFF047857), size: 20),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'PROFIT AI ASSISTANT',
                              style: TextStyle(
                                color: Color(0xFF047857),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ratingBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Health: $healthScore/100 ($rating)',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  extraProfit > 0 ? extraProfitFormatted : 'Real-time AI Business Analysis & Profit Recovery',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, height: 1.3),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Automated analysis checks underpriced repairs, slow stock, warranty loss & unpaid dues.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profitIntelligence),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
              decoration: const BoxDecoration(
                gradient: AppColors.profitGradient,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Open Profit AI Analysis',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilterBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPeriodChip('Today', 'today'),
            const SizedBox(width: 8),
            _buildPeriodChip('This Month', 'this_month'),
            const SizedBox(width: 8),
            _buildPeriodChip('Last Month', 'last_month'),
            const SizedBox(width: 8),
            _buildPeriodChip('This Year', 'this_year'),
            const SizedBox(width: 8),
            InkWell(
              onTap: _pickCustomDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedPeriod == 'custom' ? Colors.white : Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 14,
                      color: _selectedPeriod == 'custom' ? AppColors.primary : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedPeriod == 'custom' && _customDateRange != null
                          ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
                          : 'Custom Date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedPeriod == 'custom' ? FontWeight.w800 : FontWeight.w600,
                        color: _selectedPeriod == 'custom' ? AppColors.primary : Colors.white,
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

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return InkWell(
      onTap: () => _onPeriodSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primary : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionHighlightCard(int daysRemaining) {
    final isExpired = daysRemaining <= 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isExpired ? Colors.red.shade200 : Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.warning_rounded : Icons.timer_outlined,
            color: isExpired ? AppColors.error : AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? 'Subscription Expired' : 'Plan Expiring Soon ($daysRemaining Days Left)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isExpired ? AppColors.error : Colors.amber.shade900,
                  ),
                ),
                Text(
                  isExpired ? 'Renew now to maintain full access' : 'Renew plan now to prevent feature restriction',
                  style: TextStyle(fontSize: 11, color: isExpired ? Colors.red.shade800 : Colors.amber.shade800),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isExpired ? AppColors.error : AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 0,
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.subscription),
            child: const Text('Renew', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyShopOnboarding() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.storefront_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Welcome to Your Mobile Shop!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text('Get started by adding your first sale, repair ticket, or inventory item.', textAlign: TextAlign.center, style: TextStyle(color: textMutedColor)),
          const SizedBox(height: 24),
          _buildOnboardingStepTile(
            number: '1',
            title: 'Quick Accessories Sale',
            desc: 'Sell tempered glass, covers, or chargers in seconds.',
            icon: Icons.flash_on_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.quickSale),
          ),
          const SizedBox(height: 12),
          _buildOnboardingStepTile(
            number: '2',
            title: 'Add Repair Job',
            desc: 'Register customer devices for screen, battery, or board repair.',
            icon: Icons.handyman_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.createRepair),
          ),
          const SizedBox(height: 12),
          _buildOnboardingStepTile(
            number: '3',
            title: 'Add Inventory Stock',
            desc: 'Add products, parts, and stock quantities.',
            icon: Icons.inventory_2_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.addInventoryItem),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingStepTile({
    required String number,
    required String title,
    required String desc,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard(FinancialOverview fin) {
    final isProfit = fin.netProfit >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isProfit
            ? const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? const Color(0xFF059669) : AppColors.error).withOpacity(0.3),
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
              Row(
                children: const [
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Net Profit & Financial Overview',
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
                  isProfit ? 'PROFIT' : 'LOSS',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Remaining Net Profit',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '\u20B9${fin.netProfit.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Sales', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                    const SizedBox(height: 2),
                    Text('\u20B9${fin.totalSales.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Purchases', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                    const SizedBox(height: 2),
                    Text('\u20B9${fin.totalPurchases.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Expenses', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                    const SizedBox(height: 2),
                    Text('\u20B9${fin.totalExpenses.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesSummaryCard(SalesSummary sales) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.point_of_sale_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Sales & Revenue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              InkWell(
                onTap: () => _navigateToTab(1, AppRoutes.sales),
                child: const Text('View All \u2192', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Revenue', style: TextStyle(fontSize: 11, color: textMutedColor)),
                    const SizedBox(height: 4),
                    Text('\u20B9${sales.totalSales.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoices', style: TextStyle(fontSize: 11, color: textMutedColor)),
                    const SizedBox(height: 4),
                    Text('${sales.totalCount}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Collected', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            Text('\u20B9${sales.totalCollected.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 24, width: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions_rounded, size: 16, color: sales.totalDue > 0 ? AppColors.error : AppColors.textMuted),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer Dues', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            Text('\u20B9${sales.totalDue.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: sales.totalDue > 0 ? AppColors.error : textColor)),
                          ],
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

  Widget _buildPurchaseSummaryCard(PurchaseSummary purchases) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;

    return CustomCard(
      onTap: () => Navigator.pushNamed(context, AppRoutes.purchases),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_bag_rounded, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Text('Inventory Purchases', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              const Text('View All \u2192', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Purchases', style: TextStyle(fontSize: 11, color: textMutedColor)),
                    const SizedBox(height: 4),
                    Text('\u20B9${purchases.totalPurchases.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.purple)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Orders', style: TextStyle(fontSize: 11, color: textMutedColor)),
                    const SizedBox(height: 4),
                    Text('${purchases.totalCount}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.payments_rounded, size: 16, color: Colors.purple),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Amount Paid', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            Text('\u20B9${purchases.totalPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.purple)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 24, width: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.report_problem_rounded, size: 16, color: purchases.totalOutstanding > 0 ? AppColors.error : AppColors.textMuted),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Vendor Dues', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            Text('\u20B9${purchases.totalOutstanding.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: purchases.totalOutstanding > 0 ? AppColors.error : textColor)),
                          ],
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

  Widget _buildRepairSummaryCard(RepairSummary repairs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;

    return CustomCard(
      onTap: () => _navigateToTab(3, AppRoutes.repairs),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.build_rounded, color: AppColors.warning, size: 20),
              if (repairs.readyCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Text('${repairs.readyCount} Ready', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Active Repairs', style: TextStyle(fontSize: 12, color: textMutedColor)),
          const SizedBox(height: 2),
          Text('${repairs.activeRepairsCount}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text('${repairs.totalRepairsCount} Total Repairs', style: TextStyle(fontSize: 11, color: textMutedColor)),
        ],
      ),
    );
  }

  Widget _buildInventorySummaryCard(InventorySummary inventory) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;

    return CustomCard(
      onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.inventory_2_rounded, color: AppColors.accent, size: 20),
              if (inventory.lowStockCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(10)),
                  child: Text('${inventory.lowStockCount} Low', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Inventory Stock', style: TextStyle(fontSize: 12, color: textMutedColor)),
          const SizedBox(height: 2),
          Text('\u20B9${inventory.totalStockValue.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text('${inventory.totalItems} Total Items', style: TextStyle(fontSize: 11, color: textMutedColor)),
        ],
      ),
    );
  }

  Widget _buildExpenseSummaryCard(ExpenseSummary expenses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;

    return CustomCard(
      onTap: () => Navigator.pushNamed(context, AppRoutes.expenses),
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.secondary, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shop Expenses', style: TextStyle(fontSize: 12, color: textMutedColor)),
                  Text('\u20B9${expenses.totalExpensesSum.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
            ],
          ),
          if (expenses.topCategory != null)
            Text('Top: ${expenses.topCategory!.name}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary)),
        ],
      ),
    );
  }

  Widget _buildFastActionsGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionTile('Quick Sale', Icons.flash_on_rounded, Colors.amber.shade800, () async {
            final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'create quick sales');
            if (ok && mounted) Navigator.pushNamed(context, AppRoutes.quickSale);
          }),
          const SizedBox(width: 8),
          _buildActionTile('Add Repair', Icons.handyman_rounded, AppColors.primary, () async {
            final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'create repair tickets');
            if (ok && mounted) Navigator.pushNamed(context, AppRoutes.createRepair);
          }),
          const SizedBox(width: 8),
          _buildActionTile('Add Purchase', Icons.add_shopping_cart_rounded, Colors.purple, () async {
            final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'manage inventory purchases');
            if (ok && mounted) Navigator.pushNamed(context, AppRoutes.addPurchase);
          }),
          const SizedBox(width: 8),
          _buildActionTile('Add Expense', Icons.post_add_rounded, AppColors.secondary, () async {
            final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'manage expenses');
            if (ok && mounted) Navigator.pushNamed(context, AppRoutes.addExpense);
          }),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStructuredModulesList() {
    return Column(
      children: [
        _buildModuleCard(
          title: 'Inventory Purchase & Vendors',
          desc: 'Manage supplier purchases, vendor payments & stock orders',
          icon: Icons.shopping_bag_rounded,
          color: Colors.purple,
          onTap: () => Navigator.pushNamed(context, AppRoutes.purchases),
        ),
        const SizedBox(height: 10),
        _buildModuleCard(
          title: 'Customers Directory',
          desc: 'Customer profiles, contact numbers & purchase/repair history',
          icon: Icons.people_alt_rounded,
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.customers),
        ),
        const SizedBox(height: 10),
        _buildModuleCard(
          title: 'Warranty & Rework Claims',
          desc: 'Track device repair warranties & rework claims',
          icon: Icons.verified_user_rounded,
          color: AppColors.secondary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.warranties),
        ),
        const SizedBox(height: 10),
        _buildModuleCard(
          title: 'Reports & Business Analytics',
          desc: 'Sales reports, repair stats, expense summary & CSV exports',
          icon: Icons.analytics_rounded,
          color: AppColors.accent,
          onTap: () => Navigator.pushNamed(context, AppRoutes.reportsHub),
        ),
        const SizedBox(height: 10),
        _buildModuleCard(
          title: 'Device Models & IMEI Database',
          desc: 'Search customer devices, IMEI numbers & models',
          icon: Icons.phone_android_rounded,
          color: AppColors.textSecondary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.deviceSearch),
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildAttentionCard(AttentionItem item) {
    final type = item.type;
    final title = item.title;
    final subtitle = item.subtitle;

    Color iconColor = AppColors.warning;
    IconData iconData = Icons.warning_amber_rounded;

    if (type == 'out_of_stock' || type == 'vendor_dues') {
      iconColor = AppColors.error;
      iconData = Icons.error_outline_rounded;
    } else if (type == 'ready_repair') {
      iconColor = AppColors.accent;
      iconData = Icons.task_alt_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CustomCard(
        onTap: () => _handleAttentionTap(item),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(iconData, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _handleAttentionTap(AttentionItem item) {
    final route = item.actionRoute;
    switch (route) {
      case 'inventory':
        Navigator.pushNamed(context, AppRoutes.inventory);
        break;
      case 'repairs':
      case 'open_repairs':
        Navigator.pushNamed(context, AppRoutes.repairs);
        break;
      case 'open_purchases':
      case 'purchases':
        Navigator.pushNamed(context, AppRoutes.purchases);
        break;
      case 'sales':
        Navigator.pushNamed(context, AppRoutes.sales);
        break;
      case 'warranties':
        Navigator.pushNamed(context, AppRoutes.warranties);
        break;
      default:
        break;
    }
  }

  void _showSubscriptionExpiryDialog(int daysRemaining) {
    final isExpired = daysRemaining <= 0;
    showDialog(
      context: context,
      barrierDismissible: !isExpired,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isExpired ? AppColors.errorLight : AppColors.warning.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExpired ? Icons.error_outline_rounded : Icons.timer_outlined,
                  color: isExpired ? AppColors.error : AppColors.warning,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isExpired ? 'Subscription Expired!' : 'Subscription Expiring Soon!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isExpired ? AppColors.error : AppColors.warning,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isExpired
                    ? 'Your shop subscription plan has expired. Please renew your plan to create or edit records in your shop.'
                    : 'Only $daysRemaining days remaining on your active subscription plan! Please renew your plan now to continue uninterrupted access to sales billing, repair tracking, and profit intelligence.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExpired ? AppColors.error : AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, AppRoutes.subscription);
                  },
                  icon: const Icon(Icons.star_rounded, size: 18),
                  label: const Text('Renew Plan Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

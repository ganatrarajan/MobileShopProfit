import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../purchase/presentation/purchase_list_screen.dart';
import '../../repair/presentation/repair_list_screen.dart';
import '../../sales/presentation/quick_sale_screen.dart';
import '../../sales/presentation/sales_list_screen.dart';
import 'dashboard_screen.dart';

import '../../subscription/utils/subscription_guard.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late final Set<int> _visitedTabs;

  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey<DashboardScreenState>();
  final GlobalKey<SalesListScreenState> _salesListKey = GlobalKey<SalesListScreenState>();
  final GlobalKey<QuickSaleScreenState> _quickSaleKey = GlobalKey<QuickSaleScreenState>();
  final GlobalKey<RepairListScreenState> _repairListKey = GlobalKey<RepairListScreenState>();
  final GlobalKey<PurchaseListScreenState> _purchaseListKey = GlobalKey<PurchaseListScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visitedTabs = {_currentIndex};

    _pages = [
      DashboardScreen(key: _dashboardKey, onTabSelected: _onTabTapped),
      RepairListScreen(key: _repairListKey),
      QuickSaleScreen(key: _quickSaleKey, onSuccess: _onQuickSaleSuccess),
      SalesListScreen(key: _salesListKey),
      PurchaseListScreen(key: _purchaseListKey),
    ];
  }

  void _onQuickSaleSuccess() {
    setState(() {
      _currentIndex = 3; // Switch to Sales & Billing tab
      _visitedTabs.add(3);
    });
    _salesListKey.currentState?.fetchSales();
  }

  Future<void> _onTabTapped(int index) async {
    if (index == 2) {
      final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'make quick sales');
      if (!ok) return;
    }

    final dashState = _dashboardKey.currentState;
    final period = dashState?.selectedPeriod ?? 'this_month';
    final customRange = dashState?.customDateRange;

    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index == 1) {
        _repairListKey.currentState?.applyDateFilter(period, customRange);
      } else if (index == 3) {
        _salesListKey.currentState?.applyDateFilter(period, customRange);
      } else if (index == 4) {
        _purchaseListKey.currentState?.applyDateFilter(period, customRange);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          _onTabTapped(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(_pages.length, (index) {
            if (_visitedTabs.contains(index)) {
              return _pages[index];
            }
            return const SizedBox.shrink();
          }),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey.shade400).withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            selectedItemColor: isDark ? AppColors.primaryLight : AppColors.primary,
            unselectedItemColor: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded),
                activeIcon: Icon(Icons.grid_view_rounded),
                label: 'Dashboard',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.build_circle_outlined),
                activeIcon: Icon(Icons.build_circle_rounded),
                label: 'Repairs',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x404F46E5),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                ),
                label: 'Quick Sale',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Sales',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined),
                activeIcon: Icon(Icons.shopping_bag_rounded),
                label: 'Purchase',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

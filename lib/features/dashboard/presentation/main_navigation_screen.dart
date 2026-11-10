import 'package:flutter/material.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../purchase/presentation/purchase_list_screen.dart';
import '../../repair/presentation/repair_list_screen.dart';
import '../../sales/presentation/sales_list_screen.dart';
import '../../subscription/utils/subscription_guard.dart';
import '../../technician/presentation/technician_my_work_screen.dart';
import '../../used_mobile/presentation/used_mobile_list_screen.dart';
import 'dashboard_screen.dart';
import 'staff_account_screen.dart';

class _NavTabItem {
  final String id;
  final String label;
  final Widget icon;
  final Widget? activeIcon;
  final Widget page;

  _NavTabItem({
    required this.id,
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.page,
  });
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};

  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey<DashboardScreenState>();
  final GlobalKey<SalesListScreenState> _salesListKey = GlobalKey<SalesListScreenState>();
  final GlobalKey<UsedMobileListScreenState> _usedMobileKey = GlobalKey<UsedMobileListScreenState>();
  final GlobalKey<RepairListScreenState> _repairListKey = GlobalKey<RepairListScreenState>();
  final GlobalKey<PurchaseListScreenState> _purchaseListKey = GlobalKey<PurchaseListScreenState>();

  List<_NavTabItem> _tabs = [];
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visitedTabs.add(_currentIndex);
    _buildOwnerTabs();
    _checkRoleAndConfigureTabs();
  }

  void _buildOwnerTabs() {
    _tabs = [
      _NavTabItem(
        id: 'dashboard',
        label: 'Dashboard',
        icon: const Icon(Icons.grid_view_rounded),
        activeIcon: const Icon(Icons.grid_view_rounded),
        page: DashboardScreen(key: _dashboardKey, onTabSelected: _onTabTapped),
      ),
      _NavTabItem(
        id: 'repairs',
        label: 'Repairs',
        icon: const Icon(Icons.build_circle_outlined),
        activeIcon: const Icon(Icons.build_circle_rounded),
        page: RepairListScreen(key: _repairListKey),
      ),
      _NavTabItem(
        id: 'used_mobiles',
        label: 'Used Mobiles',
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
          child: const Icon(Icons.phone_android_rounded, color: Colors.white, size: 20),
        ),
        page: UsedMobileListScreen(key: _usedMobileKey),
      ),
      _NavTabItem(
        id: 'sales',
        label: 'Sales',
        icon: const Icon(Icons.receipt_long_rounded),
        activeIcon: const Icon(Icons.receipt_long_rounded),
        page: SalesListScreen(key: _salesListKey),
      ),
      _NavTabItem(
        id: 'purchases',
        label: 'Stock & Purchases',
        icon: const Icon(Icons.inventory_2_outlined),
        activeIcon: const Icon(Icons.inventory_2_rounded),
        page: PurchaseListScreen(key: _purchaseListKey),
      ),
    ];
  }

  Future<void> _checkRoleAndConfigureTabs() async {
    final user = await AuthStorage().getUser();
    final bool isOwner = AuthStorage.isOwnerUser(user);

    if (!isOwner) {
      _isStaff = true;
      final permsRaw = user?['permissions'];
      final perms = permsRaw is Map ? permsRaw : {};

      final hasRepairs = perms['repairs'] == true || perms['repairs'] == 1 || perms['repairs'].toString() == 'true';
      final hasSales = perms['sales'] == true || perms['sales'] == 1 || perms['sales'].toString() == 'true';
      final hasPurchases = perms['purchases'] == true || perms['purchases'] == 1 || perms['purchases'].toString() == 'true';
      final hasUsed = perms['used_mobiles'] == true || perms['used_mobiles'] == 1 || perms['used_mobiles'].toString() == 'true';

      final List<_NavTabItem> staffTabs = [];

      if (hasRepairs) {
        staffTabs.add(_NavTabItem(
          id: 'repairs',
          label: 'Repairs',
          icon: const Icon(Icons.build_circle_outlined),
          activeIcon: const Icon(Icons.build_circle_rounded),
          page: RepairListScreen(key: _repairListKey),
        ));

        if (user?['role'] == 'technician') {
          staffTabs.add(_NavTabItem(
            id: 'my_work',
            label: 'My Profit',
            icon: const Icon(Icons.monetization_on_outlined),
            activeIcon: const Icon(Icons.monetization_on_rounded),
            page: const TechnicianMyWorkScreen(),
          ));
        }
      }

      if (hasUsed) {
        staffTabs.add(_NavTabItem(
          id: 'used_mobiles',
          label: 'Used Mobiles',
          icon: const Icon(Icons.phone_android_rounded),
          activeIcon: const Icon(Icons.phone_android_rounded),
          page: UsedMobileListScreen(key: _usedMobileKey),
        ));
      }

      if (hasSales) {
        staffTabs.add(_NavTabItem(
          id: 'sales',
          label: 'Sales',
          icon: const Icon(Icons.receipt_long_rounded),
          activeIcon: const Icon(Icons.receipt_long_rounded),
          page: SalesListScreen(key: _salesListKey),
        ));
      }

      if (hasPurchases) {
        staffTabs.add(_NavTabItem(
          id: 'purchases',
          label: 'Stock & Purchases',
          icon: const Icon(Icons.inventory_2_outlined),
          activeIcon: const Icon(Icons.inventory_2_rounded),
          page: PurchaseListScreen(key: _purchaseListKey),
        ));
      }

      // Staff Account / Profile Tab
      staffTabs.add(_NavTabItem(
        id: 'staff_account',
        label: 'My Account',
        icon: const Icon(Icons.person_outline_rounded),
        activeIcon: const Icon(Icons.person_rounded),
        page: const StaffAccountScreen(),
      ));

      if (mounted) {
        setState(() {
          _tabs = staffTabs;
          if (_currentIndex >= _tabs.length) {
            _currentIndex = 0;
          }
          _visitedTabs.clear();
          _visitedTabs.add(_currentIndex);
        });
      }
    }
  }

  Future<void> _onTabTapped(int index) async {
    if (index >= _tabs.length) return;
    final tab = _tabs[index];

    if (tab.id == 'used_mobiles' && !_isStaff) {
      final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'access used mobiles');
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
      if (tab.id == 'repairs') {
        _repairListKey.currentState?.applyDateFilter(period, customRange);
      } else if (tab.id == 'used_mobiles') {
        _usedMobileKey.currentState?.applyDateFilter(period, customRange);
      } else if (tab.id == 'sales') {
        _salesListKey.currentState?.applyDateFilter(period, customRange);
      } else if (tab.id == 'purchases') {
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
          children: List.generate(_tabs.length, (index) {
            if (_visitedTabs.contains(index)) {
              return _tabs[index].page;
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
            items: _tabs.map((t) {
              return BottomNavigationBarItem(
                icon: t.icon,
                activeIcon: t.activeIcon ?? t.icon,
                label: t.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

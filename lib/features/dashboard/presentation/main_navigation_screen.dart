import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../inventory/presentation/inventory_list_screen.dart';
import '../../repair/presentation/repair_list_screen.dart';
import '../../sales/presentation/quick_sale_screen.dart';
import '../../sales/presentation/sales_list_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey<DashboardScreenState>();
  final GlobalKey<SalesListScreenState> _salesListKey = GlobalKey<SalesListScreenState>();
  final GlobalKey<QuickSaleScreenState> _quickSaleKey = GlobalKey<QuickSaleScreenState>();
  final GlobalKey<RepairListScreenState> _repairListKey = GlobalKey<RepairListScreenState>();
  final GlobalKey<InventoryListScreenState> _inventoryListKey = GlobalKey<InventoryListScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onQuickSaleSuccess() {
    setState(() {
      _currentIndex = 1; // Switch to Sales & Billing tab
    });
    _salesListKey.currentState?.fetchSales();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        _dashboardKey.currentState?.fetchDashboard();
        break;
      case 1:
        _salesListKey.currentState?.fetchSales();
        break;
      case 2:
        _quickSaleKey.currentState?.fetchInventoryItems();
        break;
      case 3:
        _repairListKey.currentState?.fetchRepairs();
        break;
      case 4:
        _inventoryListKey.currentState?.fetchInventory();
        break;
    }
  }

  List<Widget> get _pages => [
    DashboardScreen(key: _dashboardKey, onTabSelected: _onTabTapped),
    SalesListScreen(key: _salesListKey),
    QuickSaleScreen(key: _quickSaleKey, onSuccess: _onQuickSaleSuccess),
    RepairListScreen(key: _repairListKey),
    InventoryListScreen(key: _inventoryListKey),
  ];

  @override
  Widget build(BuildContext context) {
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
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey.shade600,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            elevation: 8,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                activeIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                label: 'Dashboard',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                activeIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                label: 'Sales',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                ),
                label: 'Quick Sale',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.build_rounded),
                activeIcon: Icon(Icons.build_rounded, color: AppColors.primary),
                label: 'Repairs',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_rounded),
                activeIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                label: 'Inventory',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardDrawer extends StatelessWidget {
  final String shopName;
  final String ownerName;
  final void Function(int tabIndex)? onTabSelected;

  const DashboardDrawer({
    super.key,
    required this.shopName,
    required this.ownerName,
    this.onTabSelected,
  });

  void _navigateToTab(BuildContext context, int tabIndex, String routeName) {
    Navigator.pop(context); // Close drawer
    if (onTabSelected != null) {
      onTabSelected!(tabIndex);
    } else {
      Navigator.pushNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            accountName: Text(
              shopName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              ownerName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Icon(Icons.store_rounded, color: Colors.white, size: 32),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded, color: AppColors.primary),
            title: const Text('Dashboard'),
            onTap: () => _navigateToTab(context, 0, AppRoutes.dashboard),
          ),
          ListTile(
            leading: const Icon(Icons.star_rounded, color: Colors.amber),
            title: const Text('⭐ Profit AI Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profitIntelligence);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.build_rounded, color: Colors.orange),
            title: const Text('Repairs'),
            onTap: () => _navigateToTab(context, 3, AppRoutes.repairs),
          ),
          ListTile(
            leading: const Icon(Icons.engineering_rounded, color: Colors.blueAccent),
            title: const Text('Technicians'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.technicians);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_rounded, color: Colors.green),
            title: const Text('Sales & Invoices'),
            onTap: () => _navigateToTab(context, 1, AppRoutes.sales),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_rounded, color: Colors.teal),
            title: const Text('Inventory'),
            onTap: () => _navigateToTab(context, 4, AppRoutes.inventory),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_rounded, color: Colors.indigo),
            title: const Text('Customers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.customers);
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_rounded, color: Colors.purple),
            title: const Text('Warranties'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.warranties);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded, color: Colors.red),
            title: const Text('Expenses'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.expenses);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_rounded, color: Colors.blue),
            title: const Text('Reports Hub'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.reportsHub);
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone_android_rounded, color: Colors.blueGrey),
            title: const Text('Device Search'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.deviceSearch);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storefront_rounded, color: AppColors.primary),
            title: const Text('Shop Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.shopProfile);
            },
          ),
        ],
      ),
    );
  }
}

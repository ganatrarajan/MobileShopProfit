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
    const textStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    const boldTextStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w800,
    );

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
            ),
            accountName: Text(
              shopName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
            ),
            accountEmail: Text(
              ownerName,
              style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 32),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded, color: AppColors.primary),
            title: const Text('Dashboard', style: textStyle),
            onTap: () => _navigateToTab(context, 0, AppRoutes.dashboard),
          ),
          ListTile(
            leading: const Icon(Icons.star_rounded, color: AppColors.warning),
            title: const Text('Profit AI Assistant', style: boldTextStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profitIntelligence);
            },
          ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.build_rounded, color: Colors.orange),
            title: const Text('Repairs', style: textStyle),
            onTap: () => _navigateToTab(context, 3, AppRoutes.repairs),
          ),
          ListTile(
            leading: const Icon(Icons.engineering_rounded, color: Colors.blue),
            title: const Text('Technicians', style: textStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.technicians);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_rounded, color: AppColors.accent),
            title: const Text('Sales & Invoices', style: textStyle),
            onTap: () => _navigateToTab(context, 1, AppRoutes.sales),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_rounded, color: Colors.teal),
            title: const Text('Inventory', style: textStyle),
            onTap: () => _navigateToTab(context, 4, AppRoutes.inventory),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_rounded, color: AppColors.primary),
            title: const Text('Customers', style: textStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.customers);
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_rounded, color: AppColors.secondary),
            title: const Text('Warranties', style: textStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.warranties);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.error),
            title: const Text('Expenses', style: textStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.expenses);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_rounded, color: Colors.indigo),
            title: const Text('Reports Hub', style: textStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.reportsHub);
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone_android_rounded, color: Colors.blueGrey),
            title: const Text('Device Search', style: textStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.deviceSearch);
            },
          ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.card_membership_rounded, color: AppColors.warning),
            title: const Text('Subscription & Billing', style: boldTextStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.subscription);
            },
          ),
          ListTile(
            leading: const Icon(Icons.storefront_rounded, color: AppColors.primary),
            title: const Text('Shop Profile', style: textStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.shopProfile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded, color: AppColors.textMuted),
            title: const Text('Settings', style: textStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
    );
  }
}

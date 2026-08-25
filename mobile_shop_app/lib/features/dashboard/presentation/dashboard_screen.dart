import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/data/auth_repository.dart';
import '../../customer/presentation/customer_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthStorage _authStorage = AuthStorage();
  final AuthRepository _authRepository = AuthRepository();

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _shop;
  bool _isLoading = true;
  int _selectedBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final user = await _authStorage.getUser();
    final shop = await _authStorage.getShop();
    setState(() {
      _user = user;
      _shop = shop;
      _isLoading = false;
    });
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your shop account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authRepository.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopName = _shop?['name'] ?? 'Mobile Shop';
    final ownerName = _user?['name'] ?? 'Owner';
    final logoUrl = _shop?['logo_url'];
    final greeting = _getTimeBasedGreeting();

    Widget bodyWidget;
    if (_selectedBottomNavIndex == 1) {
      bodyWidget = const CustomerListScreen(isTab: true);
    } else {
      bodyWidget = _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Owner Header Card
                  CustomCard(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.accent,
                              backgroundImage: logoUrl != null ? NetworkImage(logoUrl) as ImageProvider : null,
                              child: logoUrl == null
                                  ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 26)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$greeting, $ownerName',
                                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    shopName,
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const StatusBadge(
                              label: 'Active',
                              backgroundColor: AppColors.accentLight,
                              textColor: AppColors.accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Action Bar for IMEI Search & Device Lookup
                  CustomCard(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.deviceSearch),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Global Device & IMEI Search', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              SizedBox(height: 2),
                              Text('Search by IMEI 1, IMEI 2, Serial, Brand or Customer', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Today's Overview (Placeholders)",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  // Metric Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: "Today's Sales",
                          value: "₹ 0.00",
                          subtitle: '0 Transactions',
                          icon: Icons.payments_rounded,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Repairs / Jobs',
                          value: '0 Active',
                          subtitle: '0 Completed Today',
                          icon: Icons.build_circle_rounded,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Payments',
                          value: '₹ 0.00',
                          subtitle: 'Cash / Online',
                          icon: Icons.account_balance_wallet_rounded,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Daily Expenses',
                          value: '₹ 0.00',
                          subtitle: '0 Recorded',
                          icon: Icons.receipt_long_rounded,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildMetricTile(
                    title: 'Profit Intelligence',
                    value: 'SaaS Intelligence Placeholder',
                    subtitle: 'Will analyze revenue, dead stock & repair margins',
                    icon: Icons.insights_rounded,
                    color: AppColors.accent,
                  ),
                ],
              ),
            );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent,
              backgroundImage: logoUrl != null ? NetworkImage(logoUrl) as ImageProvider : null,
              child: logoUrl == null
                  ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedBottomNavIndex == 1 ? 'Customer Management' : shopName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search IMEI / Devices',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.deviceSearch),
          ),
          IconButton(
            icon: const Icon(Icons.store_outlined),
            tooltip: 'Shop Profile',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.shopProfile),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: bodyWidget,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomNavIndex,
        onTap: (index) {
          if (index == 5) {
            Navigator.pushNamed(context, AppRoutes.shopProfile);
          } else {
            setState(() {
              _selectedBottomNavIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.build_outlined), label: 'Repairs'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_outlined), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
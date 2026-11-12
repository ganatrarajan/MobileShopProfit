import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../referral/presentation/refer_and_earn_screen.dart';

class DashboardDrawer extends StatelessWidget {
  final String shopName;
  final String ownerName;
  final String? logoUrl;
  final void Function(int tabIndex)? onTabSelected;
  final bool isReferralEnabled;
  final double referralPoints;
  final VoidCallback? onReferralReturned;

  const DashboardDrawer({
    super.key,
    required this.shopName,
    required this.ownerName,
    this.logoUrl,
    this.onTabSelected,
    this.isReferralEnabled = false,
    this.referralPoints = 0.0,
    this.onReferralReturned,
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
              child: ClipOval(
                child: (logoUrl != null && logoUrl!.isNotEmpty)
                    ? Image.network(
                        logoUrl!,
                        fit: BoxFit.cover,
                        width: 64,
                        height: 64,
                        errorBuilder: (_, __, ___) => const Icon(Icons.store_rounded, color: AppColors.primary, size: 32),
                      )
                    : const Icon(Icons.store_rounded, color: AppColors.primary, size: 32),
              ),
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
          if (isReferralEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReferAndEarnScreen()),
                    );
                    onReferralReturned?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Refer & Earn',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Invite shops & earn recharge pts',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            referralPoints > 0 ? '${referralPoints.toStringAsFixed(0)} pts' : 'EARN',
                            style: const TextStyle(
                              color: Color(0xFF1E1B4B),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.build_rounded, color: Colors.orange),
            title: const Text('Repairs', style: textStyle),
            onTap: () => _navigateToTab(context, 1, AppRoutes.repairs),
          ),
          ListTile(
            leading: const Icon(Icons.engineering_rounded, color: Colors.deepOrange),
            title: const Text('Technicians', style: textStyle),
            subtitle: const Text('Repair jobs & technician payouts', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.technicians);
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge_rounded, color: Color(0xFF6366F1)),
            title: Row(
              children: [
                const Text('Staff Members', style: textStyle),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LOGIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: const Text('App logins & module permissions', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.staff);
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
            title: const Text('Used Mobiles (Buy & Sell)', style: textStyle),
            onTap: () => _navigateToTab(context, 2, AppRoutes.usedMobiles),
          ),
          ListTile(
            title: const Text('Sales & Invoices', style: textStyle),
            leading: const Icon(Icons.receipt_long_rounded, color: AppColors.accent),
            onTap: () => _navigateToTab(context, 3, AppRoutes.sales),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.indigo),
            title: const Text('Purchases & Vendors', style: textStyle),
            onTap: () => _navigateToTab(context, 4, AppRoutes.purchases),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_rounded, color: Colors.teal),
            title: const Text('Inventory', style: textStyle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.inventory);
            },
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

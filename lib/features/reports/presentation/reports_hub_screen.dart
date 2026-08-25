import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportCategories = [
      {
        'title': 'Sales Report',
        'subtitle': 'Revenue, transactions, quick vs regular sales',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.blue.shade700,
        'route': AppRoutes.salesReport,
      },
      {
        'title': 'Repair Report',
        'subtitle': 'Total, completed, active & revenue by repair',
        'icon': Icons.build_rounded,
        'color': Colors.amber.shade800,
        'route': AppRoutes.repairReport,
      },
      {
        'title': 'Inventory Report',
        'subtitle': 'Valuation, stock status & movement analytics',
        'icon': Icons.inventory_2_rounded,
        'color': Colors.teal.shade700,
        'route': AppRoutes.inventoryReport,
      },
      {
        'title': 'Expense Report',
        'subtitle': 'Category breakdowns & operational costs',
        'icon': Icons.account_balance_wallet_rounded,
        'color': Colors.red.shade700,
        'route': AppRoutes.expenseReport,
      },
      {
        'title': 'Payment Report',
        'subtitle': 'Collections by Cash, UPI, Card & Bank',
        'icon': Icons.payments_rounded,
        'color': Colors.indigo.shade700,
        'route': AppRoutes.paymentReport,
      },
      {
        'title': 'Customer Report',
        'subtitle': 'Total, new, repeat & top spending customers',
        'icon': Icons.people_alt_rounded,
        'color': Colors.purple.shade700,
        'route': AppRoutes.customerReport,
      },
      {
        'title': 'Warranty Report',
        'subtitle': 'Active warranties, claims & claim rates',
        'icon': Icons.verified_user_rounded,
        'color': Colors.green.shade700,
        'route': AppRoutes.warrantyReport,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '📈 Business Performance Reports',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Select a category below to view factual, real-time metrics and detailed records.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reportCategories.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final cat = reportCategories[index];
                final color = cat['color'] as Color;

                return CustomCard(
                  onTap: () => Navigator.pushNamed(context, cat['route'] as String),
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat['icon'] as IconData, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat['title'] as String,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat['subtitle'] as String,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

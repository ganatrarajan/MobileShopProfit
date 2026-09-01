import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../data/profit_intelligence_repository.dart';
import '../domain/profit_intelligence_models.dart';

class ProfitIntelligenceScreen extends StatefulWidget {
  const ProfitIntelligenceScreen({super.key});

  @override
  State<ProfitIntelligenceScreen> createState() => _ProfitIntelligenceScreenState();
}

class _ProfitIntelligenceScreenState extends State<ProfitIntelligenceScreen> {
  final ProfitIntelligenceRepository _repository = ProfitIntelligenceRepository();

  bool _isLoading = true;
  String? _errorMessage;
  ProfitIntelligenceData? _data;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _repository.getSummary();
      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _data = res.data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = res.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('⭐ Profit Intelligence'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchSummary, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchSummary,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // 1. Business Health Score Card
                      if (_data != null) ...[
                        _buildHealthScoreCard(_data!.health),
                        const SizedBox(height: 16),

                        // 2. Potential Extra Profit Banner
                        if (_data!.potentialExtraProfit > 0) ...[
                          _buildPotentialProfitBanner(_data!.potentialExtraProfitFormatted, _data!.potentialExtraProfit),
                          const SizedBox(height: 20),
                        ],

                        // 3. Problem Cards Grid
                        Text(
                          'Business Optimization Cards',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Real-time automated analysis highlighting profit leaks across your shop.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 14),

                        _buildProblemCardsList(_data!.cards),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildHealthScoreCard(BusinessHealthScore health) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;
    final score = health.score;
    Color color = score >= 80 ? AppColors.accent : (score >= 60 ? AppColors.warning : AppColors.error);

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Business Health Score', style: TextStyle(fontSize: 12, color: textMutedColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$score', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: color)),
                      Text(' / 100', style: TextStyle(fontSize: 14, color: textMutedColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  health.rating.toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          if (health.deductionReasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
            const SizedBox(height: 12),
            Text('Optimization Opportunities:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 6),
            ...health.deductionReasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(reason, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPotentialProfitBanner(String text, double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.profitGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.trending_up_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('POTENTIAL EXTRA PROFIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'By addressing underpriced repairs, recovering overdue customer payments, and liquidating dead stock.',
            style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemCardsList(Map<String, ProblemCardSummary> cards) {
    final list = cards.values.toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final card = list[idx];
        return _buildProblemCardItem(card);
      },
    );
  }

  Widget _buildProblemCardItem(ProblemCardSummary card) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;
    IconData icon;
    Color color;

    switch (card.category) {
      case 'underpriced_repairs':
        icon = Icons.handyman_rounded;
        color = AppColors.warning;
        break;
      case 'slow_moving_stock':
        icon = Icons.hourglass_empty_rounded;
        color = AppColors.secondary;
        break;
      case 'warranty_loss':
        icon = Icons.verified_user_rounded;
        color = AppColors.error;
        break;
      case 'pending_payments':
        icon = Icons.account_balance_wallet_rounded;
        color = AppColors.primary;
        break;
      case 'low_margin_products':
        icon = Icons.price_change_rounded;
        color = AppColors.accent;
        break;
      default:
        icon = Icons.analytics_rounded;
        color = AppColors.primary;
    }

    return CustomCard(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.profitIntelligenceDetail,
          arguments: {
            'category': card.category,
            'title': card.title,
          },
        );
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 2),
                    Text(card.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textMutedColor),
            ],
          ),
          if (card.hasEnoughData && card.financialImpact > 0) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Impact Value:', style: TextStyle(fontSize: 11.5, color: textMutedColor)),
                Text('₹${card.financialImpact.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

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
    return Scaffold(
      backgroundColor: AppColors.background,
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
                        const Text(
                          'Business Optimization Cards',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
    final score = health.score;
    Color color = score >= 80 ? Colors.green : (score >= 60 ? Colors.amber.shade800 : Colors.red.shade700);

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Business Health Score', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$score', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
                      const Text(' / 100', style: TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  health.rating.toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          if (health.deductionReasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            const Text('Optimization Opportunities:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.25),
            blurRadius: 8,
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
              Text('POTENTIAL EXTRA PROFIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'By addressing underpriced repairs, recovering overdue customer payments, and liquidating dead stock.',
            style: TextStyle(fontSize: 11, color: Colors.white70),
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
    IconData icon;
    Color color;

    switch (card.category) {
      case 'underpriced_repairs':
        icon = Icons.handyman_rounded;
        color = Colors.amber.shade800;
        break;
      case 'slow_moving_stock':
        icon = Icons.hourglass_empty_rounded;
        color = Colors.purple.shade700;
        break;
      case 'warranty_loss':
        icon = Icons.verified_user_rounded;
        color = Colors.red.shade700;
        break;
      case 'pending_payments':
        icon = Icons.account_balance_wallet_rounded;
        color = Colors.blue.shade700;
        break;
      case 'low_margin_products':
        icon = Icons.price_change_rounded;
        color = Colors.teal.shade700;
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
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(card.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
          if (card.hasEnoughData && card.financialImpact > 0) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Impact Value:', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                Text('₹ ${card.financialImpact.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

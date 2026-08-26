import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/profit_intelligence_repository.dart';
import '../models/recommendation.dart';

class ProfitIntelligenceScreen extends StatefulWidget {
  const ProfitIntelligenceScreen({super.key});

  @override
  State<ProfitIntelligenceScreen> createState() => _ProfitIntelligenceScreenState();
}

class _ProfitIntelligenceScreenState extends State<ProfitIntelligenceScreen> {
  final ProfitIntelligenceRepository _repository = ProfitIntelligenceRepository();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _summaryData;
  List<RecommendationItem> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _fetchIntelligenceData();
  }

  Future<void> _fetchIntelligenceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _repository.getSummary();
      final recs = await _repository.getRecommendations();

      setState(() {
        _summaryData = summary;
        _recommendations = recs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToRoute(String route) {
    if (route.isEmpty) return;

    switch (route) {
      case '/customers':
        Navigator.pushNamed(context, AppRoutes.customers);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigating to $route')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('⭐ Profit Intelligence & Recommendations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchIntelligenceData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _fetchIntelligenceData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Business Health Score Card
                        _buildHealthScoreCard(),
                        const SizedBox(height: 16),

                        // Potential Extra Profit Banner
                        _buildExtraProfitBanner(),
                        const SizedBox(height: 20),

                        // Recommended Actions Section Title
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Recommended Actions',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Prioritized money & margin action items based on real shop data.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),

                        // Recommendations List
                        if (_recommendations.isEmpty)
                          _buildEmptyRecommendationsCard()
                        else
                          ..._recommendations.map((rec) => _buildRecommendationTile(rec)),

                        const SizedBox(height: 24),
                        const Text(
                          'Profit Intelligence Summary Cards',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        _buildAnalysisCardsList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchIntelligenceData,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    final health = _summaryData?['business_health'] as Map<String, dynamic>?;
    final score = health?['score'] ?? 100;
    final rating = health?['rating'] ?? 'Excellent';
    final deductions = (health?['deduction_reasons'] as List<dynamic>?) ?? [];

    Color badgeColor = Colors.green;
    if (score < 60) {
      badgeColor = Colors.red;
    } else if (score < 80) {
      badgeColor = Colors.orange;
    }

    return CustomCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Business Health Score', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  SizedBox(height: 2),
                  Text('Based on customer dues, margins & inventory', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Text(
                      '$score / 100',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: badgeColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($rating)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (deductions.isNotEmpty) ...[
            const Divider(height: 20),
            const Text('Deduction Factors:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            ...deductions.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          reason.toString(),
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildExtraProfitBanner() {
    final formatted = _summaryData?['potential_extra_profit_formatted'] ?? '';
    final amount = _summaryData?['potential_extra_profit'] ?? 0;

    if (amount <= 0 && formatted.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withOpacity(0.15), AppColors.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Potential Profit Opportunity',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
                const SizedBox(height: 2),
                Text(
                  formatted.isNotEmpty ? formatted : 'You could increase your monthly profit by ₹$amount.',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendationsCard() {
    return const CustomCard(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 40, color: Colors.green),
          SizedBox(height: 10),
          Text(
            'No Critical Actions Needed!',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 6),
          Text(
            'Your shop is performing cleanly with no urgent pending dues or margin bottlenecks.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTile(RecommendationItem rec) {
    Color priorityColor = Colors.green;
    if (rec.priority == 'High') {
      priorityColor = Colors.red;
    } else if (rec.priority == 'Medium') {
      priorityColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority & Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(
                  label: rec.priorityLabel,
                  backgroundColor: priorityColor.withOpacity(0.12),
                  textColor: priorityColor,
                ),
                StatusBadge(
                  label: rec.relatedModule.toUpperCase(),
                  backgroundColor: AppColors.background,
                  textColor: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              rec.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),

            // Problem statement
            Text(
              rec.problem,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),

            // Why it matters
            Text(
              rec.whyItMatters,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            // Recommended Action Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Action: ${rec.recommendation}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            if (rec.potentialBenefit.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money_rounded, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rec.potentialBenefit,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToRoute(rec.actionRoute),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(rec.actionTitle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCardsList() {
    final cards = _summaryData?['cards'] as Map<String, dynamic>?;
    if (cards == null) return const SizedBox.shrink();

    final cardKeys = ['pending_payments', 'underpriced_repairs', 'slow_moving_stock', 'low_margin_products', 'warranty_loss'];

    return Column(
      children: cardKeys.map((key) {
        final card = cards[key] as Map<String, dynamic>?;
        if (card == null) return const SizedBox.shrink();

        final title = card['title'] ?? key;
        final count = card['count'] ?? 0;
        final message = card['message'] ?? '';
        final impact = card['financial_impact'] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: CustomCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assessment_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          if (count > 0)
                            StatusBadge(
                              label: '$count items',
                              backgroundColor: AppColors.accentLight,
                              textColor: AppColors.accent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(message, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      if (impact > 0) ...[
                        const SizedBox(height: 2),
                        Text('Financial Impact: ₹$impact', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

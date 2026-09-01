import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../data/business_assistant_repository.dart';
import '../../models/recommendation.dart';

class DashboardBusinessAssistantWidget extends StatefulWidget {
  final Map<String, dynamic>? summaryData;

  const DashboardBusinessAssistantWidget({
    super.key,
    this.summaryData,
  });

  @override
  State<DashboardBusinessAssistantWidget> createState() => _DashboardBusinessAssistantWidgetState();
}

class _DashboardBusinessAssistantWidgetState extends State<DashboardBusinessAssistantWidget> {
  bool _isLoading = true;
  BusinessAssistantData? _data;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      final res = await BusinessAssistantRepository().getRecommendations();
      if (mounted) {
        setState(() {
          _data = res.data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getPriorityDotColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red.shade700;
      case 'medium':
        return Colors.orange.shade800;
      case 'low':
      default:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEnoughData = _data?.hasEnoughData ?? widget.summaryData?['has_enough_data'] ?? true;
    final int count = _data?.totalCount ?? widget.summaryData?['attention_count'] ?? 0;
    final List<Recommendation> recommendations = _data?.recommendations ?? [];

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 BUSINESS ASSISTANT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isLoading
                          ? 'Loading smart actions...'
                          : count > 0 
                              ? '$count things need your attention' 
                              : 'Daily smart business actions',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.profitIntelligence);
                },
                icon: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                label: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
            )
          else if (!hasEnoughData || recommendations.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Keep recording sales and repairs to get smart business recommendations.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else
            Column(
              children: recommendations.take(3).map((item) {
                final String priority = item.priority;
                final String msg = item.shortMessage.isNotEmpty ? item.shortMessage : item.title;
                final dotColor = _getPriorityDotColor(priority);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          msg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

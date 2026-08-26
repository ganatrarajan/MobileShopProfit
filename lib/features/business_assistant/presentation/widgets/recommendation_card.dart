import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/routes/app_routes.dart';
import '../../models/recommendation.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;

  const RecommendationCard({
    super.key,
    required this.recommendation,
  });

  Color _getPriorityColor() {
    switch (recommendation.priority) {
      case 'high':
        return Colors.red.shade700;
      case 'medium':
        return Colors.orange.shade800;
      case 'low':
      default:
        return Colors.green.shade700;
    }
  }

  String _getPriorityLabel() {
    switch (recommendation.priority) {
      case 'high':
        return '🔴 High Priority';
      case 'medium':
        return '🟠 Medium Priority';
      case 'low':
      default:
        return '🟢 Low Priority';
    }
  }

  void _handleAction(BuildContext context) {
    final route = recommendation.actionRoute;

    switch (route) {
      case 'sales':
        Navigator.pushNamed(context, AppRoutes.customers);
        break;
      case 'inventory':
      case 'repairs':
      case 'warranties':
      case 'expenses':
      default:
        // Default navigation to customers / main modules
        Navigator.pushNamed(context, AppRoutes.customers);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getPriorityLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              if (recommendation.potentialBenefit != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    recommendation.potentialBenefit!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            recommendation.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Short Message
          Text(
            recommendation.shortMessage,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Reason / Detail
          Text(
            recommendation.reason,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Suggested Action
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What you can do:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recommendation.suggestedAction,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _handleAction(context),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(recommendation.buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

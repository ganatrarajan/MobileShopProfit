import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../data/business_assistant_repository.dart';
import '../models/business_recommendation.dart';

class BusinessAssistantScreen extends StatefulWidget {
  const BusinessAssistantScreen({super.key});

  @override
  State<BusinessAssistantScreen> createState() => _BusinessAssistantScreenState();
}

class _BusinessAssistantScreenState extends State<BusinessAssistantScreen> {
  final BusinessAssistantRepository _repository = BusinessAssistantRepository();
  bool _isLoading = true;
  String? _errorMessage;
  BusinessAssistantResponse? _assistantResponse;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repository.getRecommendations();
      if (mounted) {
        setState(() {
          _assistantResponse = response;
          _isLoading = false;
        });
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

  void _handleNavigation(String route) {
    switch (route) {
      case '/sales':
        Navigator.pushNamed(context, AppRoutes.dashboard);
        break;
      case '/customers':
        Navigator.pushNamed(context, AppRoutes.customers);
        break;
      case '/inventory':
      case '/repairs':
      case '/warranties':
      case '/expenses':
        // Navigate back or to dashboard screen
        Navigator.pushNamed(context, AppRoutes.dashboard);
        break;
      default:
        Navigator.pushNamed(context, AppRoutes.dashboard);
        break;
    }
  }

  Color _getPriorityColor(String priority) {
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

  Color _getPriorityBgColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red.shade50;
      case 'medium':
        return Colors.orange.shade50;
      case 'low':
      default:
        return Colors.green.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('💡 ', style: TextStyle(fontSize: 18)),
            Text('Business Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecommendations,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          const Text('Failed to load recommendations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 6),
                          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadRecommendations,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subtitle banner card
                        CustomCard(
                          backgroundColor: AppColors.primary.withOpacity(0.06),
                          padding: const EdgeInsets.all(16),
                          child: const Row(
                            children: [
                              Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Here are the most important things you can do today.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recommendation cards or Insufficient data banner
                        if (_assistantResponse == null || !_assistantResponse!.hasSufficientData) ...[
                          CustomCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(Icons.auto_graph_rounded, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  'Building Shop Intelligence',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _assistantResponse?.notice ??
                                      'Keep using the app. We need more sales and shop data before we can suggest the best action for your business.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _assistantResponse!.recommendations.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final rec = _assistantResponse!.recommendations[index];
                              return _buildRecommendationCard(rec);
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildRecommendationCard(BusinessRecommendation rec) {
    final priorityColor = _getPriorityColor(rec.priority);
    final priorityBg = _getPriorityBgColor(rec.priority);

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Priority Badge & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: priorityColor.withOpacity(0.3)),
                ),
                child: Text(
                  rec.priorityBadge,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: priorityColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rec.title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: priorityColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Short message
          Text(
            rec.shortMessage,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),

          // Reason / Explanation
          Text(
            rec.reason,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 10),

          // Suggested Action box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What you can do:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.suggestedAction,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
                if (rec.potentialBenefit != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    rec.potentialBenefit!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleNavigation(rec.route),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(rec.actionButtonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

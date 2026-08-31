import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../data/business_assistant_repository.dart';
import '../models/recommendation.dart';
import 'widgets/recommendation_card.dart';

class BusinessAssistantScreen extends StatefulWidget {
  const BusinessAssistantScreen({super.key});

  @override
  State<BusinessAssistantScreen> createState() => _BusinessAssistantScreenState();
}

class _BusinessAssistantScreenState extends State<BusinessAssistantScreen> {
  final BusinessAssistantRepository _repository = BusinessAssistantRepository();

  bool _isLoading = true;
  String? _errorMessage;
  BusinessAssistantData? _assistantData;
  String _selectedPriorityFilter = 'all'; // 'all', 'high', 'medium', 'low'

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _repository.getRecommendations();

    if (mounted) {
      if (response.success && response.data != null) {
        setState(() {
          _assistantData = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to load business recommendations.';
          _isLoading = false;
        });
      }
    }
  }

  List<Recommendation> _getFilteredRecommendations() {
    if (_assistantData == null) return [];
    if (_selectedPriorityFilter == 'all') {
      return _assistantData!.recommendations;
    }
    return _assistantData!.recommendations
        .where((r) => r.priority == _selectedPriorityFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = _getFilteredRecommendations();
    final bool hasEnoughData = _assistantData?.hasEnoughData ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Business Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Recommendations',
            onPressed: _fetchRecommendations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchRecommendations,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Card
                      CustomCard(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '💡 Daily Business Assistant',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _assistantData?.message ?? 'Here are the most important things you can do today.',
                              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Priority Filter Chips
                      if (hasEnoughData && _assistantData != null && _assistantData!.recommendations.isNotEmpty) ...[
                        Row(
                          children: [
                            _buildFilterChip('all', 'All (${_assistantData!.totalCount})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('high', '🔴 High (${_assistantData!.priorityCounts['high'] ?? 0})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('medium', '🟠 Medium (${_assistantData!.priorityCounts['medium'] ?? 0})'),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Recommendations List or Empty State
                      if (!hasEnoughData || recommendations.isEmpty)
                        CustomCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, size: 54, color: AppColors.accent),
                              const SizedBox(height: 14),
                              const Text(
                                'Keep Recording Sales & Repairs',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'We need more sales, repair, and inventory data before suggesting specific business actions. Keep using the app normally!',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recommendations.length,
                          itemBuilder: (context, index) {
                            return RecommendationCard(
                              recommendation: recommendations[index],
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final bool isSelected = _selectedPriorityFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPriorityFilter = value;
          });
        }
      },
    );
  }
}

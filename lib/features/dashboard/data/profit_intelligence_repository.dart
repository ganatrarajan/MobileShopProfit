import '../../../core/network/api_client.dart';
import '../models/recommendation.dart';

class ProfitIntelligenceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getSummary() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/profit-intelligence',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.message);
  }

  Future<List<RecommendationItem>> getRecommendations() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/profit-intelligence/recommendations',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final list = response.data!['recommendations'] as List<dynamic>? ?? [];
      return list.map((item) => RecommendationItem.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }
}

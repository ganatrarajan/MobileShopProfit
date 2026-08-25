import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/profit_intelligence_models.dart';

class ProfitIntelligenceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<ProfitIntelligenceData>> getSummary() async {
    return await _apiClient.get<ProfitIntelligenceData>(
      '/profit-intelligence',
      fromJson: (json) => ProfitIntelligenceData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getCategoryDetails(String category) async {
    return await _apiClient.get<Map<String, dynamic>>(
      '/profit-intelligence/details/$category',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}

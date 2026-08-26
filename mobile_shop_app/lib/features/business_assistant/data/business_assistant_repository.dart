import '../../../core/network/api_client.dart';
import '../models/business_recommendation.dart';

class BusinessAssistantRepository {
  final ApiClient _apiClient;

  BusinessAssistantRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<BusinessAssistantResponse> getRecommendations() async {
    final response = await _apiClient.get(
      '/v1/business-assistant',
      fromJson: (json) => BusinessAssistantResponse.fromJson(json as Map<String, dynamic>),
    );
    return response.data ?? const BusinessAssistantResponse(hasSufficientData: false, totalActionsCount: 0, recommendations: []);
  }
}

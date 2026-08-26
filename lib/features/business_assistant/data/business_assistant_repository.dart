import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/recommendation.dart';

class BusinessAssistantRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<BusinessAssistantData>> getRecommendations() async {
    final response = await _apiClient.get(
      '/business-assistant',
      fromJson: (data) {
        if (data is Map<String, dynamic>) {
          return BusinessAssistantData.fromJson(data);
        }
        return BusinessAssistantData(
          hasEnoughData: false,
          message: 'No data available',
          totalCount: 0,
          priorityCounts: {'high': 0, 'medium': 0, 'low': 0},
          recommendations: [],
        );
      },
    );

    return response;
  }
}

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class ReferralRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<Map<String, dynamic>>> getReferralSummary() async {
    final response = await _apiClient.get(ApiEndpoints.referralSummary);
    if (response.success && response.data != null) {
      final raw = response.data;
      final Map<String, dynamic> dataMap = (raw is Map && raw.containsKey('data') && raw['data'] is Map)
          ? Map<String, dynamic>.from(raw['data'])
          : (raw is Map ? Map<String, dynamic>.from(raw) : {});
      return ApiResponse<Map<String, dynamic>>(
        success: true,
        message: response.message,
        data: dataMap,
      );
    }
    return ApiResponse<Map<String, dynamic>>(
      success: false,
      message: response.message,
    );
  }
}


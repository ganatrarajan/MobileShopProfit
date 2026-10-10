import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/dashboard_data.dart';

class DashboardRepository {
  final ApiClient _apiClient = ApiClient();
  static final Map<String, DashboardData> _cache = {};

  /// Get cached dashboard data if available
  DashboardData? getCachedData({
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) {
    final key = '${period}_${startDate ?? ''}_${endDate ?? ''}';
    return _cache[key];
  }

  /// Clear in-memory cache
  static void clearCache() {
    _cache.clear();
  }

  /// Get aggregated dashboard metrics
  Future<ApiResponse<DashboardData>> getDashboardData({
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'period': period,
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '${ApiEndpoints.dashboard}?$queryString';

    final response = await _apiClient.get(path);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> jsonMap = (rawData is Map<String, dynamic>)
          ? rawData
          : (response.data is Map ? Map<String, dynamic>.from(response.data) : {});

      final dashboardData = DashboardData.fromJson(jsonMap);
      final key = '${period}_${startDate ?? ''}_${endDate ?? ''}';
      _cache[key] = dashboardData;

      return ApiResponse<DashboardData>(
        success: true,
        message: response.message,
        data: dashboardData,
      );
    }

    return ApiResponse<DashboardData>(
      success: false,
      message: response.message,
    );
  }
}

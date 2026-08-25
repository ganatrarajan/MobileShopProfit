import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class ReportsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<Map<String, dynamic>>> getSalesReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
    String? saleType,
    String? search,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'period': period,
      'page': page.toString(),
    };
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (saleType != null && saleType != 'all') queryParams['sale_type'] = saleType;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    return await _apiClient.get<Map<String, dynamic>>(
      '/reports/sales',
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getRepairReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
    String? status,
    String? search,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'period': period,
      'page': page.toString(),
    };
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (status != null && status != 'all') queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    return await _apiClient.get<Map<String, dynamic>>(
      '/reports/repairs',
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getInventoryReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
    String? category,
    String? search,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'period': period,
      'page': page.toString(),
    };
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (category != null && category != 'all') queryParams['category'] = category;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    return await _apiClient.get<Map<String, dynamic>>(
      '/reports/inventory',
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getExpenseReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
    int? categoryId,
    String? search,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'period': period,
      'page': page.toString(),
    };
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    return await _apiClient.get<Map<String, dynamic>>(
      '/reports/expenses',
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getPaymentReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'period': period,
      'page': page.toString(),
    };
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    return await _apiClient.get<Map<String, dynamic>>(
      '/reports/payments',
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getCustomerReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'period': period,
      'page': page.toString(),
    };
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    return await _apiClient.get<Map<String, dynamic>>(
      '/reports/customers',
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getWarrantyReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'period': period,
      'page': page.toString(),
    };
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    return await _apiClient.get<Map<String, dynamic>>(
      '/reports/warranties',
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}

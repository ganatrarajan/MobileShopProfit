import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/profit_ledger_model.dart';

class ProfitLedgerRepository {
  final ApiClient _apiClient = ApiClient();

  /// Fetch profit ledger data with optional period, category and search filters
  Future<ApiResponse<ProfitLedgerResponse>> getProfitLedger({
    String period = 'this_month',
    String category = 'all',
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'period': period,
      'category': category,
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '/profit-ledger?$queryString';

    final response = await _apiClient.get(path);

    if (response.success) {
      Map<String, dynamic> jsonMap = {};
      if (response.rawJson != null && response.rawJson is Map) {
        jsonMap = Map<String, dynamic>.from(response.rawJson!);
      } else if (response.data is Map) {
        jsonMap = Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is List) {
        jsonMap = {'items': response.data};
      }

      final ledgerResponse = ProfitLedgerResponse.fromJson(jsonMap);
      return ApiResponse<ProfitLedgerResponse>(
        success: true,
        message: response.message,
        data: ledgerResponse,
        rawJson: response.rawJson,
      );
    }

    return ApiResponse<ProfitLedgerResponse>(
      success: false,
      message: response.message.isNotEmpty
          ? response.message
          : 'Failed to load profit ledger data.',
      errors: response.errors,
    );
  }
}

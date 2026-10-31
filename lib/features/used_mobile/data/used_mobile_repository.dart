import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/used_mobile.dart';
import '../models/used_mobile_stats.dart';

class UsedMobileListResponse {
  final List<UsedMobile> mobiles;
  final UsedMobileStats stats;
  final int currentPage;
  final int lastPage;
  final int total;

  UsedMobileListResponse({
    required this.mobiles,
    required this.stats,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });
}

class UsedMobileRepository {
  final ApiClient _client = ApiClient();

  /// Fetch list of used mobiles with optional filters, search, and lifetime KPIs
  Future<UsedMobileListResponse> getUsedMobiles({
    String? status,
    String? search,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int? perPage,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
    };
    if (perPage != null) {
      query['per_page'] = perPage.toString();
    }

    if (status != null && status.isNotEmpty && status != 'all') {
      query['status'] = status;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      query['date_from'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      query['date_to'] = dateTo;
    }

    final response = await _client.get<List<UsedMobile>>(
      ApiEndpoints.usedMobiles,
      queryParameters: query,
      fromJson: (data) {
        if (data is List) {
          return data
              .map((item) => UsedMobile.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
        return <UsedMobile>[];
      },
    );

    if (response.success && response.data != null) {
      UsedMobileStats stats = UsedMobileStats.empty();
      if (response.rawJson?['summary'] != null) {
        stats = UsedMobileStats.fromJson(
            Map<String, dynamic>.from(response.rawJson!['summary'] as Map));
      }

      int currentPage = 1;
      int lastPage = 1;
      int total = response.data!.length;

      if (response.rawJson?['pagination'] != null) {
        final pag = response.rawJson!['pagination'] as Map;
        currentPage = int.tryParse(pag['current_page']?.toString() ?? '1') ?? 1;
        lastPage = int.tryParse(pag['last_page']?.toString() ?? '1') ?? 1;
        total = int.tryParse(pag['total']?.toString() ?? '0') ?? total;
      }

      return UsedMobileListResponse(
        mobiles: response.data!,
        stats: stats,
        currentPage: currentPage,
        lastPage: lastPage,
        total: total,
      );
    }

    return UsedMobileListResponse(
      mobiles: [],
      stats: UsedMobileStats.empty(),
    );
  }

  /// Get quick KPI stats
  Future<UsedMobileStats> getStats() async {
    final response = await _client.get<UsedMobileStats>(
      ApiEndpoints.usedMobilesStats,
      fromJson: (data) =>
          UsedMobileStats.fromJson(Map<String, dynamic>.from(data as Map)),
    );
    return response.data ?? UsedMobileStats.empty();
  }

  /// Fetch single used mobile details
  Future<UsedMobile?> getDetails(int id) async {
    final response = await _client.get<UsedMobile>(
      '${ApiEndpoints.usedMobiles}/$id',
      fromJson: (data) =>
          UsedMobile.fromJson(Map<String, dynamic>.from(data as Map)),
    );
    return response.data;
  }

  /// Record a purchase of an old phone (Buy Old Phone)
  Future<ApiResponse<UsedMobile>> buyUsedMobile(Map<String, dynamic> data) async {
    return await _client.post<UsedMobile>(
      ApiEndpoints.usedMobiles,
      body: data,
      fromJson: (res) =>
          UsedMobile.fromJson(Map<String, dynamic>.from(res as Map)),
    );
  }

  /// Update an existing used mobile entry
  Future<ApiResponse<UsedMobile>> updateUsedMobile(
      int id, Map<String, dynamic> data) async {
    return await _client.put<UsedMobile>(
      '${ApiEndpoints.usedMobiles}/$id',
      body: data,
      fromJson: (res) =>
          UsedMobile.fromJson(Map<String, dynamic>.from(res as Map)),
    );
  }

  /// Log repair / refurbishment cost on an in-stock phone
  Future<ApiResponse<UsedMobile>> addRepairExpense(
      int id, double repairCost, String? repairDetails) async {
    return await _client.post<UsedMobile>(
      '${ApiEndpoints.usedMobiles}/$id/repair-expense',
      body: {
        'repair_cost': repairCost,
        if (repairDetails != null && repairDetails.trim().isNotEmpty)
          'repair_details': repairDetails.trim(),
      },
      fromJson: (res) =>
          UsedMobile.fromJson(Map<String, dynamic>.from(res as Map)),
    );
  }

  /// Sell an in-stock used mobile
  Future<ApiResponse<UsedMobile>> sellUsedMobile(
      int id, Map<String, dynamic> data) async {
    return await _client.post<UsedMobile>(
      '${ApiEndpoints.usedMobiles}/$id/sell',
      body: data,
      fromJson: (res) =>
          UsedMobile.fromJson(Map<String, dynamic>.from(res as Map)),
    );
  }

  /// Delete an entry
  Future<ApiResponse<dynamic>> deleteUsedMobile(int id) async {
    return await _client.delete<dynamic>(
      '${ApiEndpoints.usedMobiles}/$id',
    );
  }
}

